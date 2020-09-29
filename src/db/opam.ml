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
open EzFile.OP
open OpamParserTypes

let home_dir =
  try Sys.getenv "HOME" with
  | Not_found -> failwith "HOME variable not defined"

let opamroot_dir =
  try
    Sys.getenv "OPAMROOT"
  with
  | Not_found -> home_dir // ".opam"

(*
let expect_error ty s =
  Printf.kprintf failwith
    "Error: expected %s instead of %s" ty (OpamPrinter.value s)

let string = function
  | String (_pos, s) -> s
  | s -> expect_error "string" s

let string_list list = List.map string list

let load_config ~opamroot =
  let file_name = opamroot // "config" in
  let file = OpamParser.file file_name in
  let config = {
    opam_version = None ;
    repositories = [];
    installed_switches = [];
    switch = None;
    jobs = None;
    download_command = None ;
    download_jobs = None ;
    global_variables
  } in
  List.iter (function
      | Section _ -> ()
      | Variable (_pos, name, v) ->
        match name, v with
        | "opam-version", String (_pos, version) ->
          config.opam_version <- version
        | "repositories", List (_pos, list) ->
          config.repositories <- string_list list
        | "installed-switches", List (_pos, list) ->
          config.installed_switches <- string_list list
    ) file.file_contents
*)
