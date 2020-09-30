(lang dune 2.4)
(name opam-gui)

(generate_opam_files false)

(source (uri git://github.com/OCamlPro/opam-gui))
(license MIT)
(authors "Fabrice Le Fessant" "David Declerck")
(maintainers "david.declerck@ocamlpro.com")
(homepage https://github.com/OCamlPro/opam-gui)
(bug_reports https://github.com/OCamlPro/opam-gui/-/issues)

(package
 (name opam-gui)
 (synopsis "A GUI for Opam")
 (depends
  vue-jsoo
  ez-api
  calendar
  geoip
  cohttp-lwt-unix
  ez_file
  opam-file-format
  opam-state
  ocplib_stuff
  re))
