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

open EzCompat

type config = {
  mutable port : int ;
  mutable token : string ;
}

type version = {
  v_db: string;
  v_db_version: int;
}

(* Information on the general configuration *)

type switch_state = {
  switch_name : string ;
  switch_dirname : string ;
  switch_state : string option ;
  switch_config : string option ;
  switch_time : int64 ;

  switch_base : string list ;
  switch_roots : string list ;
  switch_installed : string list ;
  switch_pinned : string list ;
  (* switch_repos *)
}

type opam_config = {
  config_content : string ;
  config_current_switch : string option ;
}

type global_state = {
  mutable opamroot : string ; (* directory of opam *)
  mutable opam_config : opam_config ;   (* config of opam *)
  mutable repos_list : string list ;
  mutable switches : switch_state StringMap.t ;
}


(******************* WITHOUT ENCODINGS ***************************)

(* Use OpamUtils.summary opam_config to generate: *)
type opam_config_summary = {
  mutable repositories : string list ;
  mutable installed_switches : string list ;
  mutable switch : string option ;
}
