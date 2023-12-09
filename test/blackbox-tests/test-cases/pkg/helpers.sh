export DUNE_PKG_OVERRIDE_OCAML=1

dune="dune"

pkg_root="_build/_private/default/.pkg"

build_pkg() {
  $dune build $pkg_root/$1/target/
}

show_pkg() {
  find $pkg_root/$1 | sort | sed "s#$pkg_root/$1##"
}

show_pkg_targets() {
  find $pkg_root/$1/target | sort | sed "s#$pkg_root/$1/target##"
}

show_pkg_cookie() {
  $dune internal dump $pkg_root/$1/target/cookie
}

mock_packages="mock-opam-repository/packages"

mkrepo() {
  mkdir -p $mock_packages
}

mkpkg() {
  name=$1
  if [ "$#" -eq "1" ]
  then
    version="0.0.1"
  else
    version="$2"
  fi
  mkdir -p $mock_packages/$name/$name.$version
  echo 'opam-version: "2.0"' > $mock_packages/$name/$name.$version/opam
  cat >>$mock_packages/$name/$name.$version/opam
}

add_mock_repo_if_needed() {
  if [ ! -e dune-workspace ]
  then
      cat >dune-workspace <<EOF
(lang dune 3.10)
(lock_dir
 (repositories mock))
(repository
 (name mock)
 (source "file://$(pwd)/mock-opam-repository"))
EOF
  else
    if ! grep '(name mock)' > /dev/null dune-workspace
    then
      # add the repo definition
      cat >>dune-workspace <<EOF
(repository
 (name mock)
 (source "file://$(pwd)/mock-opam-repository"))
EOF
 
      # reference the repo
      if grep -s '(repositories'
      then
        sed -i '' -e 's/(repositories \(.*\))/(repositories mock \1)/' dune-workspace
      else
        cat >>dune-workspace <<EOF
(lock_dir
 (repositories mock))
EOF
      fi
  
    fi
  fi
}

solve_project() {
  cat >dune-project
  add_mock_repo_if_needed
  dune pkg lock --dont-poll-system-solver-variables $@
}

make_lockdir() {
  mkdir dune.lock
  cat >dune.lock/lock.dune <<EOF
(lang package 0.1)
(repositories (complete true))
EOF
}

make_project() {
  cat <<EOF
(lang dune 3.11)
 (package
  (name x)
  (allow_empty)
  (depends $@))
EOF
}

solve() {
  make_project $@ | solve_project
}
