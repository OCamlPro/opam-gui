open Js_of_ocaml
open Js

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

        Request.global_state (fun ( gs : Types.global_state ) ->
            let s = OpamUtils.opam_config_summary
                gs in
            let switches =
              List.rev @@ List.map (fun sw ->
                  let current =
                    match s.switch with
                    | None -> false
                    | Some sw' -> String.equal sw sw'
                  in
                  (sw, current)
                ) s.installed_switches
            in

            app##.switches := V.list_to_js V.switch_to_js switches
          );

        app##.packages := app##.packages;

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
