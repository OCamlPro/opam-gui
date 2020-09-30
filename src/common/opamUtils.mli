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

val summary :
  opamroot:string ->
  opam_config:string ->
  Types.opam_config_summary

(*
val opam_config : Types.opam_config -> OpamFile.Config.t

val switch_state : Types.switch_config -> OpamFile.SwitchSelections.t option

val switch_config : Types.switch_config -> OpamFile.Switch_config.t option
*)
