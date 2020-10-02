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
  EzAPI.request ->
  unit ->
  (Types.version, exn) result RestoDirectory1.Answer.answer Lwt.t

val state :
  EzAPI.request ->
  unit ->
  (Types.partial_state, exn) result RestoDirectory1.Answer.answer Lwt.t

val partial_state :
  EzAPI.request ->
  Types.state_times ->
  (Types.partial_state, exn) result RestoDirectory1.Answer.answer Lwt.t

val switch_packages :
  EzAPI.request * string -> unit ->
  (string list, exn) result RestoDirectory1.Answer.answer Lwt.t

val switch_opams :
  EzAPI.request -> Types.switch_opams_query ->
  (Types.opam_file list, exn) result RestoDirectory1.Answer.answer Lwt.t

val switch_opam :
  EzAPI.request * string -> unit ->
  (Types.opam_file list, exn) result RestoDirectory1.Answer.answer Lwt.t

val switch_opam_extras :
  EzAPI.request -> Types.switch_opams_query ->
  (Types.opam_extra list, exn) result RestoDirectory1.Answer.answer Lwt.t

val switch_opam_extra :
  EzAPI.request * string -> unit ->
  (Types.opam_extra list, exn) result RestoDirectory1.Answer.answer Lwt.t

val switch :
  EzAPI.request * string -> unit ->
  (Types.switch_state, exn) result RestoDirectory1.Answer.answer Lwt.t

val opam :
  EzAPI.request -> string list ->
  (Types.call_status, exn) result RestoDirectory1.Answer.answer Lwt.t

val opam_get :
  EzAPI.request * string -> unit ->
  (Types.call_status, exn) result RestoDirectory1.Answer.answer Lwt.t

val poll :
  EzAPI.request -> int * int ->
  (Types.call_status, exn) result RestoDirectory1.Answer.answer Lwt.t

val poll_get :
  EzAPI.request * string -> unit ->
  (Types.call_status, exn) result RestoDirectory1.Answer.answer Lwt.t

val processes :
  EzAPI.request -> unit ->
  (Types.call_status list, exn) result RestoDirectory1.Answer.answer Lwt.t
