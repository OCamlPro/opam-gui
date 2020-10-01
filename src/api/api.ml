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

open EzAPIServerUtils

module MakeRegisterer(S: module type of Services)(H:module type of Handlers) = struct

  let register s h dir =
    let h a _ b = h a b in
    register s h dir

  let register dir =
    dir
  |> register S.version H.version
  |> register S.state H.state
  |> register S.partial_state H.partial_state
  |> register S.switch_packages H.switch_packages
  |> register S.switch_opams H.switch_opams
  |> register S.switch_opam_extras H.switch_opam_extras
  (* testing only *)
  |> register S.switch H.switch
  |> register S.switch_opam H.switch_opam
  |> register S.switch_opam_extra H.switch_opam_extra

end

module R = MakeRegisterer(Services)(Handlers)

let services =
  empty |> R.register
