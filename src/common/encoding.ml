open Json_encoding
open Types

let version = conv
  (fun {v_db; v_db_version} -> (v_db, v_db_version))
  (fun (v_db, v_db_version) -> {v_db; v_db_version}) @@
  obj2
    (req "db" string)
    (req "db_version" int)

let config =
  conv
    (fun { port ; token } -> ( port, token ) )
    (fun ( port , token ) -> { port ; token } )
  @@
  obj2
    (req "port" int)
    (req "token" string)

let opam_config = conv
    (fun { opamroot ; config } -> opamroot, config )
    (fun ( opamroot, config ) -> { opamroot ; config })
  @@ obj2
    (req "opamroot" string)
    (req "config" string)
