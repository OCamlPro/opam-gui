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

open Json_encoding
open Types
open EzCompat

let int64 = conv
    (fun i64 -> Int64.to_string i64)
    (fun s -> Int64.of_string s)
    string

let version = conv
  (fun {v_db; v_db_version} -> (v_db, v_db_version))
  (fun (v_db, v_db_version) -> {v_db; v_db_version}) @@
  obj2
    (req "db" string)
    (req "db_version" int)

let config =
  conv
    (fun { port ; token } -> ( port, token ) )
    (fun ( port , token ) -> { port ; token } )
  @@
  obj2
    (req "port" int)
    (req "token" string)

let switch_state = conv
    (fun { switch_name ; switch_dirname ;
           switch_state ; switch_config ;
           switch_base ; switch_roots ;
           switch_installed ; switch_pinned ;
         } ->
      ( switch_name, switch_dirname,
        switch_state, switch_config,
        switch_base, switch_roots,
        switch_installed, switch_pinned
      ))
    (fun
      ( switch_name, switch_dirname,
        switch_state, switch_config,
        switch_base, switch_roots,
        switch_installed, switch_pinned
      ) ->
      { switch_name ; switch_dirname ;
        switch_state ; switch_config ;
        switch_base ; switch_roots ;
        switch_installed ; switch_pinned ;
      })
  @@ obj8
    (req "switch_name" string)
    (req "switch_dirname" string)
    (req "switch_state" (option string))
    (req "switch_config" (option string))
    (req "switch_base" ( list string))
    (req "switch_roots" ( list string))
    (req "switch_installed" ( list string))
    (req "switch_pinned" ( list string))

(*
let opam_config = conv
    (fun { config_content ; config_current_switch } ->
       ( config_content, config_current_switch ) )
    (fun ( config_content, config_current_switch ) ->
       { config_content ; config_current_switch } )
  @@ obj2
    (req "content" string)
    (req "current_switch" (option string))
*)

let global_state = conv
    (fun { global_opamroot ; global_configfile ;
           global_repos ; global_current_switch } ->
      global_opamroot, global_configfile,
      global_repos, global_current_switch )
    (fun (global_opamroot, global_configfile,
          global_repos, global_current_switch ) ->
      { global_opamroot ; global_configfile ;
        global_repos ; global_current_switch } )
  @@ obj4
    (req "opamroot" string)
    (req "configfile" string)
    (req "repos" (list string))
    (opt "current_switch" string)

let state_times = conv
    ( fun { global_mtime ; repos_mtime ; switches_mtime } ->
        let switches_mtime = StringMap.bindings switches_mtime in
        ( global_mtime, repos_mtime, switches_mtime ) )
    ( fun ( global_mtime, repos_mtime, switches_mtime ) ->
        let switches_mtime = StringMap.of_list switches_mtime in
        { global_mtime ; repos_mtime ; switches_mtime } )
  @@
  obj3
  (req "global_mtime" int64)
  (req "repos_mtime" int64)
  (req "switches" (list (tup2 string int64)))

let repos_state = unit

let partial_state = conv
    ( fun
      { partial_state_times ; partial_global_state ;
        partial_repos_state ; partial_switch_states }
      ->
        let partial_switch_states = StringMap.bindings partial_switch_states in
        ( partial_state_times, partial_global_state,
          partial_repos_state, partial_switch_states )
    )
    ( fun
      ( partial_state_times, partial_global_state,
        partial_repos_state, partial_switch_states )
      ->
        let partial_switch_states = StringMap.of_list partial_switch_states in
        { partial_state_times ; partial_global_state ;
          partial_repos_state ; partial_switch_states }
    )
  @@ obj4
    (req "times" state_times)
    (opt "global" global_state)
    (opt "repos" repos_state)
    (req "switches" (list (tup2 string (option switch_state))))

let opam_file = conv
    ( fun
      { opam_name ; opam_version ; opam_synopsis ;
        opam_description ; opam_authors ; opam_license ;
        opam_available }
      ->
        ( opam_name, opam_version, opam_synopsis,
          opam_description, opam_authors, opam_license,
          opam_available )
    )
    ( fun
      ( opam_name, opam_version, opam_synopsis,
        opam_description, opam_authors, opam_license,
        opam_available )
      ->
        { opam_name ; opam_version ; opam_synopsis ;
          opam_description ; opam_authors ; opam_license ;
          opam_available }
    )
  @@ obj7
  (req "name" string)
  (req "version" string)
  (req "synopsis" string)
  (req "description" string)
  (req "authors" ( list string))
  (req "license" ( list string))
  (dft "available" bool true)

let switch_opams_query = conv
    ( fun
      { query_switch_opams_switch ; query_switch_opams_packages }
      ->
        ( query_switch_opams_switch, query_switch_opams_packages )
    )
    ( fun
      ( query_switch_opams_switch, query_switch_opams_packages )
      ->
        { query_switch_opams_switch ; query_switch_opams_packages }
    )
  @@ obj2
    (req "switch" string)
    (req "packages" ( list string ))

let switch_opams_reply = conv
    ( fun
      { reply_switch_opams_packages }
      ->
        ( reply_switch_opams_packages )
    )
    ( fun
      ( reply_switch_opams_packages )
      ->
        { reply_switch_opams_packages }
    )
  @@ obj1
  (req "opams" (list opam_file))
