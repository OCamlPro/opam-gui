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
open EzFile.OP

let share_www =
  let binname = Filename.dirname Sys.argv.(0) in
  binname // ".." // "share" // PConfig.project // "www"

let gui_dirname = Opam.opamroot_dir // "plugins" // "opam-gui"
let config_filename = gui_dirname // "config"
let pid_filename = gui_dirname // "pid"

let random_token () =
  let b = Bytes.create 20 in
  for i = 0 to Bytes.length b - 1 do
    Bytes.set b i (char_of_int (Random.int 256))
  done;
  Digest.to_hex (Digest.string (Bytes.to_string b))

let load_config filename =
  try
    let ic = open_in filename in
    let json = Ezjsonm.from_channel ic in
    close_in ic ;
    Json_encoding.destruct Encoding.config json
  with _ ->
    Printf.kprintf failwith
      "Fatal error: cannot parse config file %S\n%!" filename

let catch path exn =
  EzAPIServerUtils.reply_json 500 @@
  Json_encoding.(construct (obj1 (req "error" string)) @@ path ^ ": " ^ Printexc.to_string exn)

let stop_server () =
  if Sys.file_exists pid_filename then
    let pid = EzFile.read_file pid_filename in
    let pid = int_of_string pid in
    match Unix.kill pid 0 with
    | exception _ ->
      Printf.eprintf "Process is already stopped.\n%!";
      Sys.remove pid_filename
    | () ->
      Printf.eprintf "Killing process %d\n%!" pid;
      Unix.kill pid Sys.sigint

let main () =
  Printexc.record_backtrace true;
  let old_config =
    if Sys.file_exists config_filename then
      Some ( load_config config_filename )
    else
      None
  in
  let old_config, config =
    match old_config with
    | None ->
      let config =
        {
          port = PConfig.port ;
          token = random_token () ;
        } in
      config,config
    | Some old_config ->
      old_config, { old_config with port = old_config.port }
  in
  Arg.parse [
    "-stop", Arg.Unit (fun () -> stop_server (); exit 0),
    "Stop the server";
  ] (fun s ->
      Printf.kprintf failwith "Unexpected argument %S" s)
    "opam-gui server and client" ;

  let server_is_running =
    if Sys.file_exists pid_filename then
      let pid = EzFile.read_file pid_filename in
      let pid = int_of_string pid in
      match Unix.kill pid 0 with
      | exception _ ->
        EzFile.remove pid_filename;
        false
      | () ->
        if old_config <> config then begin
          stop_server ();
          false
        end else
          true
    else
      false
  in
  let processes =
    if server_is_running then begin
      Printf.eprintf "Process is already running\n%!";
      Lwt.return_unit
    end else begin
      EzFile.make_dir ~p:true gui_dirname;
      EzFile.write_file pid_filename
        (string_of_int (Unix.getpid ()));
      let servers = [
        config.port,
        EzAPIServerUtils.Root ( share_www, None );
        config.port+1, EzAPIServerUtils.API Api.services ;
      ] in
      Printf.eprintf "Starting servers on ports [%s]\n%!"
        (String.concat ","
           (List.map (fun (port,_) ->
                string_of_int port) servers));
      EzAPIServer.server ~catch servers
    end
  in
  let processes =
    Lwt.join [ processes ;
               Lwt.bind
                 (Lwt_unix.sleep 1.0 )
                 (fun () ->
                    ignore (
                      Printf.kprintf Sys.command
                        "xdg-open http://127.0.0.1:%d/index.html"
                        config.port);
                    Lwt.return_unit
                 )
             ]
  in
  Lwt_main.run processes

let () =
  main ()

(*
    let () =
      let www_port = ref 16900 in
      ignore ( Printf.kprintf Sys.command
                 "opam-gui-server --api-port %d --www-port %d &"
                 !api_port !www_port
             );
      Unix.sleep 1;
      ()
*)
