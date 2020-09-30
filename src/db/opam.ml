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
(* open OpamParserTypes *)

let home_dir =
  try Sys.getenv "HOME" with
  | Not_found -> failwith "HOME variable not defined"

let opamroot_dir =
  try
    Sys.getenv "OPAMROOT"
  with
  | Not_found -> home_dir // ".opam"
