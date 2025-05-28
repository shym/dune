Test a cross-compilation scenario with pkg

  $ mkdir -p etc/findlib.conf.d
  $ export OCAMLFIND_CONF=$PWD/etc/findlib.conf
  $ cat >etc/findlib.conf <<EOF
  > path="$PWD/prefix/lib"
  > ocamldep="$PWD/notocamldep"
  > EOF
  $ cat >etc/findlib.conf.d/foo.conf <<EOF
  > path(foo)=""
  > ocamldep(foo)="$PWD/notocamldep-foo"
  > EOF

  $ cat >notocamldep <<EOF
  > #!/usr/bin/env sh
  > ocamldep "\$@"
  > EOF
  $ cat >notocamldep-foo <<EOF
  > #!/usr/bin/env sh
  > ocamldep "\$@"
  > EOF
  $ chmod +x notocamldep notocamldep-foo

  $ mkdir app
  $ cat > app/dune-project <<EOF
  > (lang dune 3.7)
  > (package (name repro))
  > EOF
  $ cat > app/dune <<EOF
  > (executable
  >  (name gen)
  >  (modules gen)
  >  (enabled_if
  >   (= %{context_name} "default")))
  > (rule
  >  (with-stdout-to
  >   gen.ml
  >   (echo "let () = Format.printf \"let x = 1\"")))
  > (library
  >  (name repro)
  >  (public_name repro)
  >  (modules foo))
  > (rule
  >  (with-stdout-to
  >   foo.ml
  >   (run ./gen.exe)))
  > EOF

Let’s build with dune pkg and look what has been built in each context

  $ dune pkg lock --root=app
  Solution for dune.lock:
  (no dependencies to lock)
  $ dune build --root=app @install -x foo --verbose 2>&1 | grep notocamldep
  Running[11]: (cd _build/default.foo && $TESTCASE_ROOT/notocamldep-foo -modules -impl foo.ml) > _build/default.foo/.repro.objs/repro__Foo.impl.d

  $ ls app/_build/default
  gen.exe
  gen.ml
  gen.mli
  $ ls app/_build/default.foo
  META.repro
  foo.ml
  repro-foo.install
  repro.a
  repro.cma
  repro.cmxa
  repro.cmxs
  repro.dune-package
  repro.ml-gen

Let’s try now with a project that depends on OCaml

  $ cat > app/dune-project <<EOF
  > (lang dune 3.7)
  > (package
  >  (name repro)
  >  (depends (ocaml (= 5.3.0))))
  > EOF

  $ dune clean
  $ dune pkg lock --root=app
  Solution for dune.lock:
  - ocaml.5.3.0
  - ocaml-base-compiler.5.3.0
  - ocaml-compiler.5.3.0
  - ocaml-config.3
  $ dune build --root=app @install -x foo --verbose 2>&1 | grep -o 'ocamldep.*'
  ocamldep.opt -modules -impl foo.ml) > _build/default.foo/.repro.objs/repro__Foo.impl.d

Let’s check that the project was built even if the `foo` toolchain was ignored

  $ ls app/_build/default
  gen.exe
  gen.ml
  gen.mli
  $ ls app/_build/default.foo
  META.repro
  foo.ml
  repro-foo.install
  repro.a
  repro.cma
  repro.cmxa
  repro.cmxs
  repro.dune-package
  repro.ml-gen
