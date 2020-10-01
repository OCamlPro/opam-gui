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
