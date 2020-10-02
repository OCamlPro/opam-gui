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
module S = Services

let api_host = EzAPI.TYPES.BASE Common.api_host


let wrap_res ?error f = function
  | Ok x -> f x
  | Error exn -> let s = Printexc.to_string exn in match error with
    | None -> Common.logs s
    | Some e -> e 500 (Some s)

let get0 ?post ?headers ?params ?error ?(msg="") ?(host= api_host) service f =
  EzRequest.ANY.get0 host service msg ?post ?headers ?error ?params (wrap_res ?error f) ()
let get1 ?post ?headers ?params ?error ?(msg="") ?(host= api_host) service f arg =
  EzRequest.ANY.get1 host service msg ?post ?headers ?error ?params (wrap_res ?error f) arg

let post0 ?(host= api_host) ?headers ?params ?error ?(msg="") ~input service f =
  EzRequest.ANY.post0 host service msg ?headers ?params ?error ~input (wrap_res ?error f)
let post1 ?(host= api_host) ?headers ?params ?error ?(msg="") ~input service arg f =
  EzRequest.ANY.post1 host service msg ?headers ?params ?error ~input arg (wrap_res ?error f)

let version ?error f = get0 S.version ?error f
let state ?error ?state_times f =
  match state_times with
  | None -> get0 S.state ?error f
  | Some state_times ->
    post0 S.partial_state ?error ~input:state_times f

let switch_packages ?error ~switch f =
  get1 S.switch_packages ?error f switch

let switch_opams ?error ~switch ~packages f =
  post0 S.switch_opams ?error
    ~input:{
      query_switch_opams_switch = switch ;
      query_switch_opams_packages = packages ;
    } f


let opam ?error command f =
  post0 S.opam ?error f ~input:command

let poll ?error pid_line f =
  post0 S.poll ?error f ~input:pid_line
