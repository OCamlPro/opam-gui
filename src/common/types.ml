type version = {
  v_db: string;
  v_db_version: int;
}

type www_server_info = {
  www_apis : string list;
}

(* Information on the general configuration *)

type opam_config
