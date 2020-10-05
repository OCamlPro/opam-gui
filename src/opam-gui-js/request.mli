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

val version :
  ?error:EzRequest.error_handler -> (Types.version -> unit) -> unit

(* query an update of the state *)
val state :
  ?error:EzRequest.error_handler ->
  ?state_times:Types.state_times -> (Types.partial_state -> unit) -> unit

val switch_packages :
  ?error:EzRequest.error_handler ->
  switch:string -> (string list -> unit) -> unit

val switch_opams :
  ?error:EzRequest.error_handler ->
  switch:string -> packages:string list ->
  (Types.opam_file list -> unit) -> unit


(* the argument is the subcommand of opam, i.e. [ "upgrade" ] for example *)
val opam :
  ?error:EzRequest.error_handler ->
  string list -> (Types.call_status -> unit) -> unit

(* the argument of `poll` is `pid,line`, i.e. the pid of the command and
   the last line in the log we received. 0 at the beginning. *)
val poll :
  ?error:EzRequest.error_handler ->
  int * int -> (Types.call_status -> unit) -> unit

val processes :
  ?error:EzRequest.error_handler ->
  (Types.call_status list -> unit) -> unit
