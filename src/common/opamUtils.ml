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

let summary opam_config =
  let file = OpamParser.string opam_config.config
      (Filename.concat  opam_config.opamroot "config" ) in
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
