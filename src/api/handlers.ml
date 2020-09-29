open Lwt.Infix
open Types
(* open Services *)

let to_api p = Lwt.bind p EzAPIServerUtils.return

let version _params () = to_api (
    Db.get_version () |> fun v_db_version ->
    Lwt.return (Ok { v_db = "none"; v_db_version }))
