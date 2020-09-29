(lang dune 2.4)
(name ez-opam)

(source (uri git://github.com/OCamlPro/ez-opam))
(license MIT)
(authors "Fabrice Le Fessant" "David Declerck")
(maintainers "david.declerck@ocamlpro.com")
(homepage https://github.com/OCamlPro/ez-opam)
(bug_reports https://github.com/OCamlPro/ez-opam/-/issues)

(package
 (name ez-opam)
 (synopsis "A GUI for Opam")
 (depends
  vue-jsoo
  ez-api
  calendar
  geoip
  cohttp-lwt-unix
  re))
