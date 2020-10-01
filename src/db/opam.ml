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

let state = ref None

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
          times.switches_mtime <- StringMap.add switch_name switch_mtime
              times.switches_mtime;
          switch_name,
          OpamSwitchState.load `Lock_none gt rt switch)
        switches
    in
    let switches = StringMap.of_list switches in
    let s = { gt ; rt ; switches } in
    state := Some s;
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
        s.switches <- StringMap.map (fun switch ->
            { switch with
              switch_repos = rt;
            }) s.switches ;
        times.repos_mtime <- repos_mtime ;
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
    s

let get_partial_state ?( state_times = prehistoric_times () ) () =
  let { gt ; rt ; switches } = read_state () in

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
          let switch_state =
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
          in
          Some switch_state
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
