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

open EzCompat (* for StringMap *)
open Types
open EzFile.OP
open OpamStateTypes

type process_status =
    Running of Unix.process_status Lwt.t
  | Exited of Unix.process_status

type process = {
  process_command : string array ;
  process_pid : int ;
  mutable process_status : process_status ;
  mutable process_line : int ;
  mutable process_log : (int * string * string) list ;
}

let process_table = Hashtbl.create 113

(* let create process_command = *)

let call_status ?line p =
  let call_status = match p.process_status with
    | Running _ -> None
    | Exited s -> Some s
  in
  let rec iter process_log line call_log =
    match process_log with
    | [] -> call_log
    | ( ( l, kind, content ) as entry ) :: process_log ->
      if l > line then
        iter process_log line ( entry :: call_log )
      else
        call_log
  in
  let call_log, line = match line with
    | None -> [], 0
    | Some line -> iter p.process_log line [], line in
  let call_log = Array.of_list call_log in
  {
    call_pid = p.process_pid ;
    call_command = p.process_command ;
    call_line = line ;
    call_log ;
    call_status ;
  }

let rec read_output p name lwt_io =
  Lwt.bind
    (Lwt_io.read_line_opt lwt_io)
    (function
      | None -> Lwt.return_unit
      | Some content ->
        let line = p.process_line + 1 in
        p.process_log <- (line, name, content) :: p.process_log;
        p.process_line <- line ;
        read_output p name lwt_io
    )

let unsafe = try
    ignore ( Sys.getenv "OPAMGUI_UNSAFE" ); true
  with _ -> false

let very_unsafe = try
    ignore ( Sys.getenv "OPAMGUI_VERY_UNSAFE" ); true
  with _ -> false

let call command =
  match command with
  | [] -> failwith "empty opam command"
  | subcmd :: args ->
    let command =
      match subcmd with
      | "help"
      | "update"
      | "list"
      | "show"
      | "search"
        -> "opam" :: command
      | ( "upgrade"
        | "install"
        | "remove"
        | "repo"
        | "repository"
        | "switch"
        | "pin"
        | "unpin"
        | "config"
        | "init"
        ) when unsafe ->
        "opam" :: command
      | _ ->
        if very_unsafe then
          command
        else
          failwith "forbidden opam command (maybe set OPAMGUI_UNSAFE)"
    in
    let process_command = Array.of_list command in
    let po = Lwt_process.open_process_full ("", process_command)  in
    let process_status = po#status in
    let process_pid = po#pid in
    let process_line = 0 in
    let process_log = [] in
    let p =
      {
        process_status = Running process_status ;
        process_command ;
        process_pid ;
        process_line ;
        process_log ;
      } in
    Lwt.async (fun () ->
        Lwt.bind process_status
          (fun process_status ->
             p.process_status <- Exited process_status;
             Lwt.return_unit
          )
      );
    Lwt.async (fun () -> read_output p "out" po#stdout);
    Lwt.async (fun () -> read_output p "err" po#stderr);
    Hashtbl.add process_table process_pid p  ;
    call_status p ~line:0

let poll pid line =
  let p = Hashtbl.find process_table pid in
  call_status p ~line

let processes () =
  let list = ref [] in
  Hashtbl.iter (fun _ p ->
      list := call_status p :: !list
    ) process_table ;
  !list
