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

open Js_of_ocaml

let html_escaped s =
  let len = String.length s in
  let b = Buffer.create len in
  for i = 0 to len -1 do
    match s.[i] with
    | '<' -> Buffer.add_string b "&lt;"
    | '>' -> Buffer.add_string b "&gt;"
    | '&' -> Buffer.add_string b "&amp;"
    | '"' -> Buffer.add_string b "&quot;"
    | c -> Buffer.add_char b c
  done;
  Buffer.contents b

let www_host, api_host =
  match Url.url_of_string
          (Js.to_string Dom_html.window##.location##.href) with
  | Some (Url.Http hu) ->
    Printf.sprintf "http://%s:%d" hu.Url.hu_host hu.Url.hu_port,
    Printf.sprintf "http://%s:%d" hu.Url.hu_host ( hu.Url.hu_port + 1)
  | Some (Url.Https hu) ->
    Printf.sprintf "https://%s:%d" hu.Url.hu_host hu.Url.hu_port,
    Printf.sprintf "https://%s:%d" hu.Url.hu_host ( hu.Url.hu_port+ 1)
  | _ ->
    Printf.sprintf "http://127.0.0.1:%d" PConfig.port,
    Printf.sprintf "http://127.0.0.1:%d" ( PConfig.port + 1)
(*  EzAPI.TYPES.BASE host *)

let () = Printf.printf "Web host: %s\n%!" www_host
let () = Printf.printf "API host: %s\n%!" api_host

let logs s = Firebug.console##log (Js.string s)

let path () =
  match Url.url_of_string (Js.to_string Dom_html.window##.location##.href) with
  | None -> ""
  | Some url -> match url with
    | Url.Http hu | Url.Https hu -> String.concat "/" hu.Url.hu_path
    | Url.File fu -> String.concat "/" fu.Url.fu_path

let set_path ?(scroll=true) ?(args=[]) path =
  let args = match args with
    | [] -> ""
    | l -> "?" ^ String.concat "&" (List.map (fun (k, v) -> k ^ "=" ^ v) l) in
  let path = Js.some @@ Js.string @@ "/" ^ path ^ args in
  Dom_html.window##.history##pushState path (Js.string "") path;
  if scroll then Dom_html.window##scroll 0 0

let wait ?(t=1.) f =
  Dom_html.window##setTimeout (Js.wrap_callback f) t |> ignore
