let () =
  EzXhr.init ();
  let path = Route.init () in
  let app = V.init (Js_of_ocaml.Js.string path) in
  Route.route ~app path
