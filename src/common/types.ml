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
  switch_state : string option ; (* content of file *)
  switch_config : string option ; (* content of file *)

  switch_base : string list ; (* list of initial packages: compiler *)
  switch_roots : string list ; (* list of explicitely installed packages *)
  switch_installed : string list ;
  switch_pinned : string list ;
  (* switch_repos *)
}

type global_state = {
  global_opamroot : string ; (* directory of opam *)
  global_configfile : string ;   (* config of opam *)
  global_repos : string list ;   (* list of repositories *)
  global_current_switch : string option ; (* current switch *)
}

type state_times = {
  mutable global_mtime : int64 ;
  mutable repos_mtime : int64 ;
  mutable switches_mtime : int64 StringMap.t ;
}

type repos_state = unit

type partial_state = {
  partial_state_times : state_times ;
  partial_global_state : global_state option ;
  partial_repos_state : repos_state option ;
  partial_switch_states : switch_state option StringMap.t ;
}

type deps = {
  dep_set : StringSet.t;
  dep_formula : string ;
}

type opam_file = {
  opam_name : string ;
  opam_version : string ;
  opam_synopsis : string ;
  opam_description : string ;
  opam_authors : string list ;
  opam_license : string list ;
  opam_available : bool ;
  opam_urls : string list ;
  opam_hashes : string list ;
  opam_depends : deps ;
  opam_depopts : deps ;
}

type file_change =
  | AddDir
  | AddFile of int64
  | RemoveFile
  | ModifyFile
  | AddLink of string

type opam_extra = {
  opam_nv : string ; (* package.version *)
  opam_dir : string option ;
  opam_file : string option ; (* content of opam_file *)
  opam_changes : file_change StringMap.t option ;
}

(* API *)

type switch_opams_query = {
  query_switch_opams_switch : string ;
  query_switch_opams_packages : string list ; (* NAME.VERSION *)
}




(******************* WITHOUT ENCODINGS ***************************)

type state = {
  state_times : state_times ;
  global_state : global_state ;
  repos_state : repos_state ;
  switch_states : switch_state StringMap.t ;
}

(* Use OpamUtils.summary opam_config to generate: *)
type opam_config_summary = {
  mutable repositories : string list ;
  mutable installed_switches : string list ;
  mutable switch : string option ;
}



let prehistoric_times () = {
  global_mtime = 0L ;
  repos_mtime = 0L;
  switches_mtime = StringMap.empty ;
}
