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

let opam_config _req () =
  to_api @@ (
    let opamroot = Opam.opamroot_dir in
    let opam_config = EzFile.read_file ( opamroot // "config" ) in
    let summary = OpamUtils.summary ~opamroot ~opam_config in
    let switches = List.map (fun switch_name ->
        let switch_dirname =
          if Filename.is_relative switch_name then
            opamroot // switch_name
          else
            switch_name // "_opam"
        in
        let switch_state_filename =
          switch_dirname // ".opam-switch" // "switch-state"
        in
        let switch_config_filename =
          switch_dirname // ".opam-switch" // "switch-config"
        in
        let switch_state = match EzFile.read_file switch_state_filename with
          | exception _ -> None
          | content -> Some content
        in
        let switch_config = match EzFile.read_file switch_config_filename with
          | exception _ -> None
          | content -> Some content
        in
        let switch_time = match Unix.lstat switch_state_filename with
          | exception _ -> 0L
          | st -> Int64.of_float st.Unix.st_mtime
        in
        switch_name, {
          switch_name ;
          switch_dirname ;
          switch_state ;
          switch_config ;
          switch_time ;
        }
      ) summary.installed_switches in
    Lwt.return (Ok {
        opamroot ;
        opam_config ;
        switches ;
      }))
