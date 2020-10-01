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

let switch_packages :
  (string, string list, exn, no_security)
    post_service0 =
  post_service
    ~section:section_main
    ~name:"switch_packages"
    ~input:string
    ~output:(list string)
    Path.(root // "switch_packages")

let switch_opams :
  (switch_opams_query, switch_opams_reply, exn, no_security)
    post_service0 =
  post_service
    ~section:section_main
    ~name:"switch_packages"
    ~input:switch_opams_query
    ~output:switch_opams_reply
    Path.(root // "switch_opams")
