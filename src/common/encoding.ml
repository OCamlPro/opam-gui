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

let switch_config = conv
    (fun { switch_name ; switch_dirname ;
           switch_state ; switch_config ; switch_time } ->
       let switch_time = Int64.to_string switch_time in
       ( switch_name, switch_dirname,
         switch_state, switch_config, switch_time ))
    (fun
      ( switch_name, switch_dirname,
        switch_state, switch_config, switch_time ) ->
      let switch_time = Int64.of_string switch_time in
      { switch_name ; switch_dirname ;
        switch_state ; switch_config ; switch_time })
  @@ obj5
  (req "switch_name" string)
  (req "switch_dirname" string)
  (req "switch_state" (option string))
  (req "switch_config" (option string))
  (req "switch_time" string)

let opam_config = conv
    (fun { opamroot ; opam_config ; switches } ->
       opamroot, opam_config, switches )
    (fun ( opamroot, opam_config, switches ) ->
       { opamroot ; opam_config ; switches })
  @@ obj3
    (req "opamroot" string)
    (req "config" string)
    (req "switches" (list (tup2 string switch_config)))
