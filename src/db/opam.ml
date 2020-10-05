(**************************************************************************)
(*                                                                        *)
(*  Copyright (c) 2020 OCamlPro SAS                                       *)
(*                                                                        *)
(*  All rights reserved.                                                  *)
(*  This file is distributed under the terms of the GNU Lesser General    *)
(*  Public License version 2.1, with the special exception on linking     *)
(*  described in the LICENSE.md file in the root directory.               *)
(*                                                                        *)
(**************************************************************************)

open EzCompat (* for StringMap *)
open Types
open EzFile.OP
open OpamStateTypes

let home_dir =
  try Sys.getenv "HOME" with
  | Not_found -> failwith "HOME variable not defined"

let opamroot_dir =
  try
    Sys.getenv "OPAMROOT"
  with
  | Not_found -> home_dir // ".opam"

type state = {
  mutable gt : unlocked global_state ;
  mutable rt : unlocked repos_state ;
  mutable switches : unlocked switch_state StringMap.t ;
}

let times = {
  global_mtime = 0L ;
  repos_mtime = 0L;
  switches_mtime = StringMap.empty ;
}

let mtime filename =
  match Unix.lstat filename with
  | exception exn ->
    Printf.eprintf "Warning: exception %S in Unix.lstat(%S)\n%!"
      ( Printexc.to_string exn) filename ;
    1L
  | st -> Int64.of_float st.Unix.st_mtime

let rec mtimes filenames =
  match filenames with
  | [] -> 0L
  | filename :: filenames ->
    max (mtime filename) (mtimes filenames)

let current_time = ref ( Unix.gettimeofday () )
let settime () = current_time := Unix.gettimeofday ()

let state = ref None
let last_state_update = ref 0.


let switch_dir ~gt switch =
  let switch_name = OpamSwitch.to_string switch in
  if Filename.is_relative switch_name then
    let opamroot = OpamFilename.Dir.to_string gt.root in
    opamroot // switch_name
  else
    switch_name // "_opam"

let switch_meta ~gt switch =
  ( switch_dir ~gt switch ) // ".opam-switch"

let read_state () =
  match !state with
  | None ->

    let gt = OpamGlobalState.load `Lock_none in
    let opamroot = OpamFilename.Dir.to_string gt.root in
    let config_filename = opamroot // "config" in
    times.global_mtime <- mtime config_filename ;

    (* monitorer .opam/repo/state.cache *)
    let repos_filename = opamroot //"repo" // "state.cache" in
    times.repos_mtime <- mtime repos_filename ;
    let rt = OpamRepositoryState.load `Lock_none gt in

    let switches =
      let switches = OpamGlobalState.switches gt in
      List.map  (fun switch ->
          let switch_name = OpamSwitch.to_string switch in
          let switch_meta = switch_meta ~gt switch in
          let switch_state_filename =
            switch_meta // "switch-state" in
          let switch_config_filename =
            switch_meta // "switch-config" in
          let switch_mtime = mtimes
              [ switch_state_filename ; switch_config_filename ] in
          times.switches_mtime <- StringMap.add switch_name switch_mtime
              times.switches_mtime;
          switch_name,
          OpamSwitchState.load `Lock_none gt rt switch)
        switches
    in
    let switches = StringMap.of_list switches in
    let s = { gt ; rt ; switches } in
    state := Some s;
    last_state_update := !current_time;
    s

  | Some s ->

    let opamroot = OpamFilename.Dir.to_string s.gt.root in
    let config_filename = opamroot // "config" in
    let global_mtime = mtime config_filename in

    let gt =
      if global_mtime > times.global_mtime then begin
        let gt = OpamGlobalState.load `Lock_none in
        s.gt <- gt;
        s.rt <- { s.rt with repos_global = gt };
        s.switches <- StringMap.map (fun switch ->
            { switch with
              switch_global = gt;
              switch_repos = s.rt;
            }) s.switches ;
        times.global_mtime <- global_mtime ;
        gt
      end else
        s.gt
    in

    let rt =
      let repos_filename = opamroot //"repo" // "state.cache" in
      let repos_mtime = mtime repos_filename in
      if times.repos_mtime < repos_mtime then
        let rt = OpamRepositoryState.load `Lock_none gt in
        s.rt <- rt ;
        times.repos_mtime <- repos_mtime ;
        (* invalidate all switches *)
        s.switches <- StringMap.empty;
        times.switches_mtime <- StringMap.empty;
        rt
      else
        s.rt
    in

    let switches_mtime = ref StringMap.empty in
    let switches =
      let switches = OpamGlobalState.switches gt in
      List.map  (fun switch ->
          let switch_name = OpamSwitch.to_string switch in
          let switch_dir =
            if Filename.is_relative switch_name then
              opamroot // switch_name
            else
              switch_name // "_opam"
          in
          let switch_state_filename =
            switch_dir // ".opam-switch" // "switch-state" in
          let switch_config_filename =
            switch_dir // ".opam-switch" // "switch-config" in
          let switch_mtime = mtimes
              [ switch_state_filename ; switch_config_filename ] in
          let keep_old =
            match StringMap.find switch_name times.switches_mtime with
            | exception Not_found -> false
            | old_mtime ->
              switch_mtime = old_mtime
          in
          let st =
            if keep_old then
              match StringMap.find switch_name s.switches with
              | st -> st
              | exception Not_found ->
                OpamSwitchState.load `Lock_none gt rt switch
            else
              OpamSwitchState.load `Lock_none gt rt switch
          in
          switches_mtime := StringMap.add switch_name switch_mtime
              !switches_mtime;
          ( switch_name, st )
        )
        switches
    in
    let switches = StringMap.of_list switches in
    s.switches <- switches;
    times.switches_mtime <- !switches_mtime;
    last_state_update := !current_time;
    s

(* Use this function to only reload the state after 5 seconds *)
let get_state ?(force=false) () =
  match !state with
  | None -> read_state ()
  | Some state ->
    if force || !current_time > !last_state_update +. 5. then
      read_state ()
    else
      state

let convert_switch_state gt st =
  let switch = st.switch in
  let switch_name = OpamSwitch.to_string switch in
  let global_opamroot = OpamFilename.Dir.to_string gt.root in
  let switch_dirname =
    if Filename.is_relative switch_name then
      global_opamroot // switch_name
    else
      switch_name // "_opam"
  in
  let switch_state_filename =
    switch_dirname // ".opam-switch" // "switch-state"
  in
  let switch_config_filename =
    switch_dirname // ".opam-switch" // "switch-config"
  in
  let switch_state = match EzFile.read_file switch_state_filename with
    | exception _ -> None
    | content -> Some content
  in
  let switch_config = match EzFile.read_file switch_config_filename with
    | exception _ -> None
    | content -> Some content
  in

  let switch_base = OpamPackage.Set.elements st.compiler_packages
                    |> List.map OpamPackage.to_string in
  let switch_roots = OpamPackage.Set.elements st.installed_roots
                     |> List.map OpamPackage.to_string in
  let switch_installed = OpamPackage.Set.elements st.installed
                         |> List.map OpamPackage.to_string in
  let switch_pinned = OpamPackage.Set.elements st.pinned
                      |> List.map OpamPackage.to_string in
  {
    switch_name ;
    switch_dirname ;
    switch_state ;
    switch_config ;
    switch_base ;
    switch_roots ;
    switch_installed ;
    switch_pinned ;
  }

let switch switch =
  let { gt ; rt = _ ; switches } = get_state () in
  let switch_state = StringMap.find switch switches in
  convert_switch_state gt switch_state

let get_partial_state ?( state_times = prehistoric_times () ) () =
  let { gt ; rt = _ ; switches } = read_state () in

  let partial_state_times = { times with global_mtime = times.global_mtime } in
  let global_opamroot = OpamFilename.Dir.to_string gt.root in
  let partial_global_state =
    if partial_state_times.global_mtime > state_times.global_mtime then
      let (config : OpamFile.Config.t ) = gt.config in
      let global_configfile =
        EzFile.read_file ( global_opamroot // "config" ) in
      let global_repos = OpamGlobalState.repos_list gt in
      let global_repos = List.map OpamRepositoryName.to_string global_repos in
      let global_current_switch =
        match OpamFile.Config.switch config with
        | None -> None
        | Some switch -> Some ( OpamSwitch.to_string switch )
      in
      let global_state = {
        global_opamroot ;
        global_configfile ;
        global_repos ;
        global_current_switch ;
      }
      in
      Some global_state
    else
      None
  in
  let partial_repos_state =
    if partial_state_times.repos_mtime > state_times.repos_mtime then
      Some ()
    else
      None
  in
  let partial_switch_states =
    StringMap.map (fun st ->

        let switch = st.switch in
        let switch_name = OpamSwitch.to_string switch in
        let old_mtime =
          match StringMap.find switch_name state_times.switches_mtime with
          | exception Not_found -> 0L
          | mtime -> mtime
        in
        let new_mtime =
          StringMap.find switch_name partial_state_times.switches_mtime in
        if new_mtime > old_mtime then
          Some ( convert_switch_state gt st )
        else
          None
      ) switches
  in
  {
    partial_state_times ;
    partial_global_state ;
    partial_repos_state ;
    partial_switch_states ;
  }

let switch_packages switch =
  let { gt = _ ; rt = _ ; switches } = get_state () in
  let switch_state = StringMap.find switch switches in
  let packages = ref [] in
  OpamPackage.Set.iter (fun p ->
      packages := OpamPackage.to_string p :: !packages)
    switch_state.packages;
  List.rev !packages

let set_of_formula formula =
  let set = ref StringSet.empty in
  OpamFormula.iter (fun (name, _formula) ->
      let name = OpamPackage.Name.to_string name in
      set := StringSet.add name !set) formula;
  { dep_set = !set ;
    dep_formula = OpamFilter.string_of_filtered_formula formula ;
  }

let switch_opams switch packages =
  let { gt = _ ; rt = _ ; switches } = get_state () in
  let switch_state = StringMap.find switch switches in
  let opams = ref [] in
  List.iter (fun nv ->
      let p = OpamPackage.of_string nv in
      match OpamPackage.Map.find p switch_state.opams with
      | exception Not_found ->
        Printf.eprintf
          "Warning: could not find OPAM for %s in switch %s\n%!"
          nv switch
      | opam ->
        let opam_synopsis = match OpamFile.OPAM.synopsis opam with
          | None -> "" | Some s -> s
        in
        let opam_description = match OpamFile.OPAM.descr_body opam with
          | None -> "" | Some s -> s
        in
        let opam_authors = OpamFile.OPAM.author opam in
        let opam_license = OpamFile.OPAM.license opam in
        let opam_name, opam_version = EzString.cut_at nv '.' in
        let opam_available =
          OpamPackage.Set.mem p (Lazy.force switch_state.available_packages) in
        let opam_urls, opam_hashes =
          match OpamFile.OPAM.url opam with
          | None -> [], []
          | Some url ->
            (
              ( OpamFile.URL.url url ::
                OpamFile.URL.mirrors url ) |> List.map OpamUrl.to_string ),
            OpamFile.URL.checksum url |> List.map OpamHash.to_string
        in

        let opam_depends =
          let depends = OpamFile.OPAM.depends opam in
          set_of_formula depends
        in

        let opam_depopts =
          let depends = OpamFile.OPAM.depopts opam in
          set_of_formula depends
        in
        let opam = {
          opam_name ;
          opam_version ;
          opam_synopsis ;
          opam_description ;
          opam_license ;
          opam_authors ;
          opam_available ;
          opam_urls ;
          opam_hashes ;
          opam_depends ;
          opam_depopts ;
        } in
        opams := opam :: !opams
    ) packages;
  !opams

let switch_opam_extras switch packages =
  let { gt ; rt = _ ; switches } = get_state () in
  let switch_state = StringMap.find switch switches in
  List.map (fun opam_nv ->
      let p = OpamPackage.of_string opam_nv in
      let opam = OpamPackage.Map.find p switch_state.opams in

      let opam_dir = OpamFile.OPAM.metadata_dir opam
      (* next version:
         let repos_root = OpamRepositoryState.get_repo rt in
         OpamFile.OPAM.get_metadata_dir
         ~repos_root opam
      *)
      in
      let opam_dir, opam_file = match opam_dir with
        | None -> None, None
        | Some opam_dir ->
          let opam_dir = OpamFilename.Dir.to_string opam_dir in
          let opam_file = EzFile.read_file ( opam_dir // "opam" ) in
          Some opam_dir, Some opam_file
      in
      let (n,_v) = EzString.cut_at opam_nv '.' in
      let switch_meta = switch_meta ~gt switch_state.switch in
      let opam_changes =
        let filename = switch_meta // "install" // ( n ^ ".changes") in
        if Sys.file_exists filename then
          let changes = OpamFile.Changes.read
              (OpamFile.make
                 (OpamFilename.of_string filename)) in
          let opam_changes = ref StringMap.empty in
          OpamStd.String.Map.iter (fun file change ->
              let change = match change with
                | OpamDirTrack.Added digest ->
                  let s = OpamDirTrack.string_of_digest digest in
                  begin
                    match s.[0] with
                    | 'D' -> AddDir
                    | 'L' ->
                      let _, link = EzString.cut_at s ':' in
                      AddLink link
                    | 'F' ->
                      let _, s = EzString.cut_at s 'S' in
                      let size, _ = EzString.cut_at s 'T' in
                      let size = Int64.of_string size in
                      AddFile size
                    | _ -> ModifyFile
                  end
                | Removed -> RemoveFile
                | _ -> ModifyFile
              in
              opam_changes := StringMap.add file change !opam_changes
            ) changes ;
          Some ( !opam_changes )
        else
          None
      in
      {
        opam_nv ;
        opam_changes ;
        opam_dir ;
        opam_file ;
      }
    ) packages
