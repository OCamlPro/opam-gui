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


(*
let info_service : (www_server_info, exn, EzAPI.no_security) EzAPI.service0 =
  EzAPI.service
    ~output:Encoding.info_encoding
    EzAPI.Path.(root // "info.json" )


let init f =
  get0 ~host:(Common.host ()) info_service
    ~error:(fun code content ->
        let s = match content with
          | None -> "network error"
          | Some content -> "network error: " ^ string_of_int code ^ " -> " ^ content in
        Common.logs s)
    (fun ({www_apis; _} as info) ->
       let api = List.nth www_apis (Random.int @@ List.length www_apis) in
       host := EzAPI.TYPES.BASE api;
       f info)
*)

let version ?error f = get0 S.version ?error f
let state ?error ?state_times f =
  match state_times with
  | None -> get0 S.state ?error f
  | Some state_times ->
    post0 S.partial_state ?error ~input:state_times f
