open Types
open Encoding
open EzAPI

let section_main = section "API"
let sections = [ section_main ]

let version : (version, exn, no_security) service0 =
  service
    ~section:section_main
    ~name:"version"
    ~output:version
    Path.(root // "version")


(* Use OpamUtils.summary to parse the most useful fields *)
let opam_config : (opam_config, exn, no_security) service0 =
  service
    ~section:section_main
    ~name:"opam_config"
    ~output:opam_config
    Path.(root // "opam-config")
