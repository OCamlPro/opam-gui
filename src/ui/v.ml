open Js_of_ocaml.Js

class type error = object
  method code : int readonly_prop
  method content : js_string t optdef readonly_prop
end

class type switches_js = object
  method name : js_string t prop
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

  method switches : switches_js t js_array t prop
  method packages : packages_js t js_array t prop
end

include Vue_js.Make(struct
    type data = app
    type all = data
    let id = "app"
  end)

let switch_to_js (s, c) =
   object%js val mutable name = string s
     val mutable current = bool c end

let package_to_js (n, i) =
  object%js val mutable name = string n
    val mutable installed = bool i end

let list_to_js f l =
  array (Array.of_list (List.map f l))

let init path =
  let data = object%js
    val mutable path = path
    val mutable database = string ""
    val mutable db_version_ = 0
    val mutable switches =
      array [| switch_to_js ("4.07", false);
               switch_to_js ("4.08", false) |]
    val mutable packages =
      array [| package_to_js ("base", true);
               package_to_js ("dune", true);
               package_to_js ("js_of_ocaml", true) |]
  end in
  init ~data ~show:true ()
