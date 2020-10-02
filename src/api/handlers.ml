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

open Lwt.Infix
open Types
open EzFile.OP

let to_api p =
  Opam.settime ();
  EzAPIServerUtils.return (Ok (p ()))

let version _params () =
  to_api (fun () ->
      Db.get_version () |> fun v_db_version ->
      { v_db = "none"; v_db_version })

let state _req () =
  to_api @@ (fun () -> Opam.get_partial_state () )

let partial_state _req state_times =
  to_api @@ (fun () -> Opam.get_partial_state ~state_times () )

let switch_packages (_req, switch) () =
  to_api @@ (fun () ->
      Opam.switch_packages switch
    )

let switch_opams _req q =
  to_api @@ (fun () ->
      Opam.switch_opams
        q.query_switch_opams_switch
        q.query_switch_opams_packages
    )

let switch_opam (_req, switch_nv) q =
  let switch, nv = EzString.cut_at switch_nv ',' in
  to_api @@ (fun () ->
      Opam.switch_opams switch [nv]
    )

let switch_opam_extras _req q =
  to_api @@ (fun () ->
      Opam.switch_opam_extras
        q.query_switch_opams_switch
        q.query_switch_opams_packages
    )

let switch_opam_extra (_req, switch_nv) q =
  let switch, nv = EzString.cut_at switch_nv ',' in
  to_api @@ (fun () ->
      Opam.switch_opam_extras switch [nv]
    )

let switch (_req, switch) () =
  to_api @@ (fun () -> Opam.switch switch)

let opam _req command =
  to_api @@ (fun () ->  Opam_lwt.call command)

let opam_get (_req, command) () =
  to_api @@ (fun () ->
      let command = EzString.split command ',' in
      Opam_lwt.call command)

let poll _req (pid,line) =
  to_api @@ (fun () -> Opam_lwt.poll pid line)

let poll_get (_req, pid_line) () =
  to_api @@ (fun () ->
      let pid, line = EzString.cut_at pid_line ',' in
      let pid = int_of_string pid in
      let line = if line = "" then 0 else int_of_string line in
      Opam_lwt.poll pid line)
