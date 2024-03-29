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
open Types

open Js_of_ocaml.Js

class type error = object
  method code : int readonly_prop
  method content : js_string t optdef readonly_prop
end

class type switches_js = object
  method name : js_string t prop
  method path : js_string t prop
  method time : js_string t prop
  method current : bool t prop
end

class type packages_js = object
  method name : js_string t prop
  method installed : bool t prop
end

class type app = object
  method path : js_string t prop
  method database : js_string t prop
  method db_version_ : int prop

  method current_switch_ : js_string t prop
  method selected_switch_ : js_string t prop

  method switches : switches_js t js_array t prop
  method switches_busy_ : bool t prop

  method packages : packages_js t js_array t prop
  method packages_busy_ : bool t prop
end

include Vue_js.Make(struct
    type data = app
    type all = data
    let id = "app"
  end)

let switch_to_js (n, p, t, c) =
   object%js val mutable name = string n
     val mutable path = string p
     val mutable time =
       let t = Unix.localtime (Int64.to_float t) in
       let t = Printf.sprintf "%02d/%02d/%04d %02d:%02d:%02d"
         t.tm_mday t.tm_mon (t.tm_year + 1900)
         t.tm_hour t.tm_min t.tm_sec
       in
       string t
     val mutable current = bool c end

let package_to_js (n, i) =
  object%js val mutable name = string n
    val mutable installed = bool i end

let list_to_js f l =
  array (Array.of_list (List.map f l))



let state = ref None
let get_state ?(update = false) f =
  match !state with
  | None ->
    Request.state
      (fun p ->
         let s = Types.{
             state_times = p.partial_state_times ;
             global_state = (match p.partial_global_state with
                 | None ->
                   Printf.printf "no global_state\n%!";
                   assert false
                 | Some global_state -> global_state);
             repos_state = (match p.partial_repos_state with
                 | None ->
                   Printf.printf "no repos_state\n%!";
                   assert false
                 | Some repos_state -> repos_state);
             switch_states = EzCompat.StringMap.map (function
                 | None ->
                   Printf.printf "no switch_state\n%!";
                   assert false
                 | Some switch_state -> switch_state) p.partial_switch_states ;
           } in
         state := Some s;
         f s
      )
  | Some s ->
    if update then
      let { state_times ; _ } = s in
      Request.state ~state_times (fun p ->
          let s = Types.{
              state_times = p.partial_state_times ;
              global_state = (match p.partial_global_state with
                  | None -> s.global_state
                  | Some global_state -> global_state);
              repos_state = (match p.partial_repos_state with
                  | None -> s.repos_state
                  | Some repos_state -> repos_state);
              switch_states = EzCompat.StringMap.mapi (fun switch_name ->
                  function
                  | Some switch_state -> switch_state
                  | None ->
                    match
                      StringMap.find switch_name s.switch_states
                    with
                    | exception _ -> assert false
                    | switch_state -> switch_state
                ) p.partial_switch_states ;
            } in
          state := Some s;
          f s
        )
    else
      f s

let init path =
  let data : app t = object%js (self)
    val mutable path = path
    val mutable database = string ""
    val mutable db_version_ = 0

    val mutable current_switch_ = string ""
    val mutable selected_switch_ = string ""

    val mutable switches = array [| |]
    val mutable switches_busy_ = bool false

    val mutable packages = array [| |]
    val mutable packages_busy_ = bool false
    end
  in

  add_method1 "switches_provider" (fun this ctxt ->

      Ezjs_min.Promise.promise (fun resolve _reject ->
          get_state (fun ( gs : Types.state ) ->
              let sum = OpamUtils.opam_config_summary gs in
              let switches =
                EzCompat.StringMap.fold (fun sw swc acc ->
                    (* switch_state = packages *)
                    (* opamroot = ~/.opam *)
                    let current =
                      match sum.switch with
                      | None -> false
                      | Some sw' -> String.equal sw sw'
                    in
                    if current then
                      this##.current_switch_ := string sw;
                    if current && to_string this##.selected_switch_ = "" then
                      this##.selected_switch_ := string sw;

                    let time =
                      match EzCompat.StringMap.find_opt sw
                              gs.state_times.switches_mtime with
                      | None -> Int64.zero
                      | Some t -> t
                    in

                    (sw, swc.Types.switch_dirname, time, current) :: acc
                  ) gs.switch_states []
              in
              this##.switches := list_to_js switch_to_js switches;
              resolve (this##.switches)
            )
        )
    );

  add_method1 "packages_provider" (fun this ctxt ->

      Ezjs_min.Promise.promise (fun resolve _reject ->
          let ssw = to_string this##.selected_switch_ in
          if ssw = "" then
            resolve (array [| |])
          else
            get_state (fun (gs : Types.state) ->
                match EzCompat.StringMap.find_opt ssw gs.switch_states with
                | None ->
                    resolve (array [| |])
                | Some sw ->
                    this##.packages :=
                      list_to_js package_to_js
                        (List.map (fun s -> (s, true)) sw.switch_installed);
                    resolve (this##.packages)
              )
        )
    );


  add_method0 "some_action" (fun this ->
      Unsafe.eval_string "alert('test')");

  init ~data ~show:true ()
