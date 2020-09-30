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

(* For every added type, an encoding must be added in api/encoding.ml *)

type config = {
  mutable port : int ;
  mutable token : string ;
}

type version = {
  v_db: string;
  v_db_version: int;
}

(* Information on the general configuration *)

(* Use OpamUtils.summary opam_config to generate: *)
type opam_config_summary = {
  mutable repositories : string list ;
  mutable installed_switches : string list ;
  mutable switch : string option ;
}

type opam_config = {
  opamroot : string ;
  config : string ;
}
