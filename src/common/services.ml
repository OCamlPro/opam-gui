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

open Types
open Json_encoding
open Encoding
open EzAPI

let section_main = section "API"
let sections = [ section_main ]

let version : (version, exn, no_security) service0 =
  service
    ~section:section_main
    ~name:"version"
    ~output:version
    Path.(root // "version")

(* To test from curl:
curl http://127.0.0.1:9989/state
*)
let state : (partial_state, exn, no_security) service0 =
  service
    ~section:section_main
    ~name:"state"
    ~output:partial_state
    Path.(root // "state")

let partial_state : (state_times, partial_state, exn, no_security)
    post_service0 =
  post_service
    ~section:section_main
    ~name:"partial_state"
    ~input:state_times
    ~output:partial_state
    Path.(root // "partial_state")

let arg_switch =
  EzAPI.arg_string "switch" "SWITCH"

let arg_switch_nv =
  EzAPI.arg_string "switch_nv" "SWITCH,NAME.VERSION"

(* To test from curl:
curl http://127.0.0.1:9989/switch/SWITCH
*)
let switch :
  (string, switch_state, exn, no_security)
    service1 =
  service
    ~section:section_main
    ~name:"switch"
    ~output:switch_state
    Path.(root // "switch" /: arg_switch)

(* To test from curl:
curl http://127.0.0.1:9989/switch_packages
*)
let switch_packages :
  (string, string list, exn, no_security)
    service1 =
  service
    ~section:section_main
    ~name:"switch_packages"
    ~output:(list string)
    Path.(root // "switch_packages" /: arg_switch)

let switch_opams :
  (switch_opams_query, opam_file list, exn, no_security)
    post_service0 =
  post_service
    ~section:section_main
    ~name:"switch_opams"
    ~input:switch_opams_query
    ~output:( list opam_file )
    Path.(root // "switch_opams")

(* only to test switch_opams from curl:
curl http://127.0.0.1:9989/switch_opam/4.10.0,ocaml-base-compiler.4.10.0
 *)
let switch_opam :
  (string, opam_file list, exn, no_security)
    service1 =
  service
    ~section:section_main
    ~name:"switch_opams"
    ~output:( list opam_file )
    Path.(root // "switch_opam" /: arg_switch_nv)

let switch_opam_extras :
  (switch_opams_query, opam_extra list, exn, no_security)
    post_service0 =
  post_service
    ~section:section_main
    ~name:"switch_opam_extras"
    ~input:switch_opams_query
    ~output:( list opam_extra )
    Path.(root // "switch_opam_extras")

(* only to test switch_opam_extras from curl:
curl http://127.0.0.1:9989/switch_opam_extra/4.10.0,ocaml-base-compiler.4.10.0
 *)
let switch_opam_extra :
  (string, opam_extra list, exn, no_security)
    service1 =
  service
    ~section:section_main
    ~name:"switch_opams"
    ~output:( list opam_extra )
    Path.(root // "switch_opam_extra" /: arg_switch_nv)
