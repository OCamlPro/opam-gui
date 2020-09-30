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

let switch_config = conv
    (fun { switch_name ; switch_dirname ;
           switch_state ; switch_config ; switch_time ;
           switch_base ; switch_roots ;
           switch_installed ; switch_pinned ;
         } ->
      let switch_time = Int64.to_string switch_time in
      ( switch_name, switch_dirname,
        switch_state, switch_config, switch_time,
        switch_base, switch_roots,
        switch_installed, switch_pinned
      ))
    (fun
      ( switch_name, switch_dirname,
        switch_state, switch_config, switch_time,
        switch_base, switch_roots,
        switch_installed, switch_pinned
      ) ->
      let switch_time = Int64.of_string switch_time in
      { switch_name ; switch_dirname ;
        switch_state ; switch_config ; switch_time ;
        switch_base ; switch_roots ;
        switch_installed ; switch_pinned ;
      })
  @@ obj9
    (req "switch_name" string)
    (req "switch_dirname" string)
    (req "switch_state" (option string))
    (req "switch_config" (option string))
    (req "switch_time" string)
    (req "switch_base" ( list string))
    (req "switch_roots" ( list string))
    (req "switch_installed" ( list string))
    (req "switch_pinned" ( list string))

let opam_config = conv
    (fun { config_content ; config_current_switch } ->
       ( config_content, config_current_switch ) )
    (fun ( config_content, config_current_switch ) ->
       { config_content ; config_current_switch } )
  @@ obj2
    (req "content" string)
    (req "current_switch" (option string))

let global_state = conv
    (fun { opamroot ; opam_config ; switches ; repos_list } ->
       let switches = StringMap.bindings switches in
       opamroot, opam_config, switches, repos_list )
    (fun ( opamroot, opam_config, switches, repos_list ) ->
       let switches = StringMap.of_list switches in
       { opamroot ; opam_config ; switches ; repos_list })
  @@ obj4
    (req "opamroot" string)
    (req "config" opam_config)
    (req "switches" (list (tup2 string switch_config)))
    (req "repos" (list string))
