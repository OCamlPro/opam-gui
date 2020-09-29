open Js_of_ocaml.Js

class type error = object
  method code : int readonly_prop
  method content : js_string t optdef readonly_prop
end

class type switches_js = object
  method name : js_string t prop
end

class type data_ = object
  method path : js_string t prop
  method database : js_string t prop
  method db_version_ : int prop

  method switches : switches_js t js_array t prop
end

include Vue_js.Make(struct
    type nonrec data = data_
    type all = data
    let id = "app"
  end)

let init path =
  let data = object%js
    val mutable path = path
    val mutable database = string ""
    val mutable db_version_ = 0
    val mutable switches = array [|
        object%js val mutable name = string "4.07" end;
        object%js val mutable name = string "4.08" end
      |]
  end in
  init ~data ~show:true ()
