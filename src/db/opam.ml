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
  gt : unlocked global_state ;
  rt : unlocked repos_state ;
  switches : ( OpamSwitch.t * unlocked switch_state ) list ;
}

let state = lazy (
  (* monitorer le fichier .opam/config *)
  let gt = OpamGlobalState.load `Lock_none in

  (* monitorer .opam/repos/state.cache *)
  let rt = OpamRepositoryState.load `Lock_none gt in

  (* monitorer .opam/SWITCH/switch-state et .opam/SWITCH/switch-config  *)
  let switches =
    let switches = OpamGlobalState.switches gt in
    List.map  (fun switch ->
        switch, OpamSwitchState.load `Lock_none gt rt switch)
      switches
  in
  { gt ; rt ; switches }
)

let get_state () =
  (* TODO: reload the state if necessary, only the modified parts using
     timestamps of files *)
  Lazy.force state

let load_state () =
  let { gt ; rt ; switches } = get_state () in
  let ( opamroot : string ) = OpamFilename.Dir.to_string gt.root in
  let ( config : OpamFile.Config.t ) = gt.config in
  let config_content = EzFile.read_file ( opamroot // "config" ) in


  let repos_list = OpamGlobalState.repos_list gt in

  let switches = List.map (fun (switch,st) ->
      let switch_name = OpamSwitch.to_string switch in
      let switch_dirname =
        if Filename.is_relative switch_name then
          opamroot // switch_name
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
      let switch_time = match Unix.lstat switch_state_filename with
        | exception _ -> 0L
        | st -> Int64.of_float st.Unix.st_mtime
      in

      let switch_base = OpamPackage.Set.elements st.compiler_packages
                      |> List.map OpamPackage.to_string in
      let switch_roots = OpamPackage.Set.elements st.installed_roots
                      |> List.map OpamPackage.to_string in
      let switch_installed = OpamPackage.Set.elements st.installed
                      |> List.map OpamPackage.to_string in
      let switch_pinned = OpamPackage.Set.elements st.pinned
                      |> List.map OpamPackage.to_string in
      switch_name, {
        switch_name ;
        switch_dirname ;
        switch_state ;
        switch_config ;
        switch_time ;
        switch_base ;
        switch_roots ;
        switch_installed ;
        switch_pinned ;
      }
    ) switches
  in
  let switches = StringMap.of_list switches in
  let config_current_switch =
    match OpamFile.Config.switch config with
    | None -> None
    | Some switch -> Some ( OpamSwitch.to_string switch )
  in
  let repos_list = List.map OpamRepositoryName.to_string repos_list in
  let opam_config = {
    config_content ;
    config_current_switch ;
  } in
  {
    opamroot ;
    opam_config ;
    switches ;
    repos_list
  }
