open Json_encoding
open Types

let version = conv
  (fun {v_db; v_db_version} -> (v_db, v_db_version))
  (fun (v_db, v_db_version) -> {v_db; v_db_version}) @@
  obj2
    (req "db" string)
    (req "db_version" int)

let api_config = obj1 (opt "port" int)

let info_encoding = conv
    (fun {www_apis} -> www_apis)
    (fun www_apis -> {www_apis}) @@
  obj1
    (req "apis" (list string))

let opam_config = conv
    (fun { opamroot ; config } -> opamroot, config )
    (fun ( opamroot, config ) -> { opamroot ; config })
  @@ obj2
    (req "opamroot" string)
    (req "config" string)
