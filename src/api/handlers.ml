open Lwt.Infix
open Data_types
(* open Services *)

let to_api p =
  Lwt.catch (fun () -> p) (fun exn -> Lwt.return @@ Error exn) >>= fun p ->
  EzAPIServerUtils.return p

let version _params () = to_api (
    Db.get_version () |> fun v_db_version ->
    Lwt.return (Ok { v_db = "none"; v_db_version }))
