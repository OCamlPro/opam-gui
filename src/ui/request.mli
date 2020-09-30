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

val opam_config :
  ?error:EzRequest.error_handler -> (Types.opam_config -> unit) -> unit
