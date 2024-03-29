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

open EzCompat
open Js_of_ocaml
open Js
open Types

let get_app ?app () = match app with
  | None -> V.app ()
  | Some app -> app

let route ?app path =
  Common.logs ("route " ^ path);
  let app = get_app ?app () in
  app##.path := string path;
  match String.split_on_char '/' path with
  | [ path ] -> begin match path with
      | "" ->
          ()

      | "db" ->
        Request.version (fun {v_db; v_db_version} ->
            app##.database := string v_db;
            app##.db_version_ := v_db_version)
      | "api" ->
        Common.wait ~t:10. @@ fun () ->
        (Unsafe.variable "Redoc")##init
          (string "openapi.json")
          (Unsafe.obj [|"scrollYOffset", Unsafe.inject 50|])
          (Dom_html.getElementById_exn "redoc")
      | _ -> ()
    end
  | _ -> ()

let route_js app path =
  route ~app (to_string path);
  Common.set_path (to_string path)

let init () =
  V.add_method1 "route" route_js;
  let path = Common.path () in
  Dom_html.window##.onpopstate := Dom_html.handler (fun _e ->
      route @@ Common.path ();
      _true);
  path
