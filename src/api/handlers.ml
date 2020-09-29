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
  Lwt.catch p (fun exn -> Lwt.return @@ Error exn) >>= fun p ->
  EzAPIServerUtils.return p

let version _params () = to_api (fun () ->
    Db.get_version () |> fun v_db_version ->
    Lwt.return (Ok { v_db = "none"; v_db_version }))

let opam_config _req () =
  to_api @@ fun () ->
  let opamroot = Opam.opamroot_dir in
  Lwt.return (Ok {
      opamroot ;
      config = EzFile.read_file ( opamroot // "config" )
    })
