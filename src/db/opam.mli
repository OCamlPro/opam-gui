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

val opamroot_dir : string

val get_partial_state :
  ?state_times:Types.state_times -> unit -> Types.partial_state

val switch_packages : string -> string list

val switch_opams : string -> string list -> Types.opam_file list

val switch_opam_extras : string -> string list -> Types.opam_extra list

val switch : string -> Types.switch_state

(* called by Handlers.to_api to update the current time *)
val settime : unit -> unit
