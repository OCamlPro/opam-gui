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

open Types
open OpamParserTypes

let expect_error ty s =
  Printf.kprintf failwith
    "Error: expected %s instead of %s" ty (OpamPrinter.value s)

let string = function
  | String (_pos, s) -> s
  | s -> expect_error "string" s

let string_list list = List.map string list

let summary ~opamroot ~opam_config =
  let file = OpamParser.string opam_config
      (Filename.concat opamroot "config" ) in
  let summary = {
    repositories = [];
    installed_switches = [];
    switch = None;
  } in
  List.iter (function
      | Section _ -> ()
      | Variable (_pos, name, v) ->
        match name, v with
        | "repositories", List (_pos, list) ->
          summary.repositories <- string_list list
        | "installed-switches", List (_pos, list) ->
          summary.installed_switches <- string_list list
        | "switch", String (_pos, s) ->
          summary.switch <- Some s
        | _ -> ()
    ) file.file_contents;
  summary

(* Unfortunately, OpamFile from opam-format cannot be used in JSOO:

let switch_state switch =
  match switch.switch_state with
  | None -> None
  | Some content ->
    Some ( OpamFile.SwitchSelections.read_from_string content )

let switch_config switch =
  match switch.switch_config with
  | None -> None
  | Some content ->
    Some ( OpamFile.Switch_config.read_from_string content )

let opam_config config =
  OpamFile.Config.read_from_string config.opam_config
*)
