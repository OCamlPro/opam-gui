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

let to_api p = Lwt.bind p EzAPIServerUtils.return

let version _params () = to_api (
    Db.get_version () |> fun v_db_version ->
    Lwt.return (Ok { v_db = "none"; v_db_version }))

let global_state _req () =
  to_api @@ (Lwt.return (Ok ( Opam.load_state () )))
