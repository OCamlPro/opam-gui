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
open EzCompat

let expect_error ty s =
  Printf.kprintf failwith
    "Error: expected %s instead of %s" ty (OpamPrinter.value s)

let string = function
  | String (_pos, s) -> s
  | s -> expect_error "string" s

let string_list list = List.map string list

let opam_config_summary ( s : Types.state ) =
  {
    repositories = s.global_state.global_repos;
    installed_switches = StringMap.bindings s.switch_states |> List.map fst;
    switch = s.global_state.global_current_switch;
  }
