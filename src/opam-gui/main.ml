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
  let path = "share" // (Globals.project_name ^ "-js") // "www" in
  let testfile = path // "index.html" in
  let binname = Filename.dirname Sys.executable_name in
  if Sys.file_exists ( binname // testfile ) then
    binname // path
  else
    binname // ".." // path

let () =
  Printf.eprintf "Serving files from %s\n%!" share_www

let gui_dirname = Opam.opamroot_dir // "plugins" // "opam-gui"
let config_filename = gui_dirname // "config"
let pid_filename = gui_dirname // "pid"

let plugins_bin = Opam.opamroot_dir // "plugins" // "bin"
let plugins_filename = plugins_bin // "opam-gui"

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
          port = Globals.port ;
          token = random_token () ;
        } in
      config,config
    | Some old_config ->
      old_config, { old_config with port = old_config.port }
  in
  let launch_browser = ref true in
  let start_server = ref true in
  Arg.parse [
    "-stop", Arg.Unit (fun () -> stop_server (); exit 0),
    "Stop the server";
    "-port", Arg.Int (fun port -> config.port <- port),
    "Change the port";
    "-server", Arg.Clear launch_browser, "Don't launch browser";
    "-browser", Arg.Clear start_server, "Don't start server";
  ] (fun s ->
      Printf.kprintf failwith "Unexpected argument %S" s)
    "opam-gui server and client" ;

  begin
    let old_content =
      if Sys.file_exists plugins_filename then
        EzFile.read_file plugins_filename
      else
        ""
    in
    let filename = Sys.argv.(0) in
    let filename =
      if Filename.is_relative filename then
        Sys.getcwd () // filename
      else
        filename
    in
    let new_content = Printf.sprintf "#!/bin/sh\nexec %s $*\n" filename in
    if new_content <> old_content then begin
      EzFile.write_file plugins_filename new_content;
      Unix.chmod plugins_filename 0o755
    end
  end;

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
          if not !start_server then
            failwith "Running server with different config";
          stop_server ();
          false
        end else
          true
    else
      false
  in
  let start_server_lwt =
    if !start_server then
      if server_is_running then begin
        Printf.eprintf "Process is already running\n%!";
        Lwt.return_unit
      end else begin
        EzFile.make_dir ~p:true gui_dirname;
        EzFile.write_file config_filename
          ( Json_encoding.construct Encoding.config config
            |> Ezjsonm.value_to_string );
        EzFile.write_file pid_filename
          (string_of_int (Unix.getpid ()));
        let servers = [
          config.port,
          EzAPIServerUtils.Root ( share_www, Some "/index.html" );
          config.port+1, EzAPIServerUtils.API Api.services ;
        ] in
        Printf.eprintf "Starting servers on ports [%s]\n%!"
          (String.concat ","
             (List.map (fun (port,_) ->
                  string_of_int port) servers));
        EzAPIServer.server ~catch servers
      end
    else
      Lwt.return_unit
  in
  let launch_browser_lwt =
    if !launch_browser then
      let call_xdg () =
        ignore (
          Printf.kprintf Sys.command
            "xdg-open http://127.0.0.1:%d/"
            config.port);
        Lwt.return_unit
      in
      if !start_server && not server_is_running then
        Lwt.bind
          (Lwt_unix.sleep 1.0 )
          call_xdg
      else
        call_xdg ()
    else
      Lwt.return_unit
  in
  let processes = Lwt.join [
      start_server_lwt ; launch_browser_lwt ]
  in
  Lwt_main.run processes

let () =
  main ()

(*
╰─➤ EZAPISERVER=3 ./bin/opam-gui -port 8080
*)
