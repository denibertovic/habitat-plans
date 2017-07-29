pkg_origin=denibertovic
pkg_name=elm
pkg_version=0.18.0
pkg_lib_dirs=(lib)
pkg_bin_dirs=(bin)
pkg_include_dirs=(include)
pkg_deps=(
    core/zlib/1.2.8
    core/gmp/6.1.0/20170513202112
    core/gcc-libs/5.2.0
    core/libffi/3.2.1
    core/glibc
    core/texinfo
    core/ncurses/6.0
)
pkg_build_deps=(
    denibertovic/ghc/7.10.2/20170728150241
    core/git
    alasconnect/cabal-install/1.24.0.2
    core/gcc
    core/perl
)

github_clone() {
  # $1 = origin, $2 = name, $3 = commit or tag
  git clone https://github.com/${1}/${2}.git

  pushd ${2}
  git checkout ${3} --quiet
  popd
}

do_build() {
    cd $CACHE_PATH
    export LD_LIBRARY_PATH="$(pkg_path_for gmp)/lib:$(pkg_path_for zlib)/lib:$(pkg_path_for libffi)/lib:$(pkg_path_for gcc-libs)/lib:$(pkg_path_for glibc)/lib:$(pkg_path_for ncurses)/lib"
    export LIBRARY_PATH="$(pkg_path_for gmp)/lib:$(pkg_path_for zlib)/lib:$(pkg_path_for libffi)/lib:$(pkg_path_for gcc-libs)/lib:$(pkg_path_for glibc)/lib:$(pkg_path_for ncurses)/lib"

    github_clone elm-lang elm-compiler ${pkg_version}
    github_clone elm-lang elm-package ${pkg_version}
    github_clone elm-lang elm-make ${pkg_version}
    github_clone elm-lang elm-reactor ${pkg_version}
    github_clone elm-lang elm-repl ${pkg_version}

    echo "split-objs: True" > cabal.config
    cabal update
    cabal sandbox init
    cabal sandbox add-source elm-compiler
    cabal sandbox add-source elm-package
    cabal sandbox add-source elm-make
    cabal sandbox add-source elm-reactor
    cabal sandbox add-source elm-repl

    # install only dependencies
    cabal install -j --only-dependencies --ghc-options="-w" \
        --extra-include-dirs=$(pkg_path_for zlib)/include \
        --extra-lib-dirs=$(pkg_path_for zlib)/lib \
        --extra-lib-dirs=$(pkg_path_for gmp)/lib \
        --extra-lib-dirs=$(pkg_path_for ncurses)/lib \
        elm-compiler \
        elm-package \
        elm-make \
        elm-reactor \
        elm-repl

    # install all except reactor
    cabal install -j --ghc-options="-XFlexibleContexts" \
        --extra-include-dirs=$(pkg_path_for zlib)/include \
        --extra-lib-dirs=$(pkg_path_for zlib)/lib \
        --extra-lib-dirs=$(pkg_path_for gmp)/lib \
        --extra-lib-dirs=$(pkg_path_for ncurses)/lib \
        elm-compiler \
        elm-package \
        elm-make \
        elm-repl

    # # and finally install elm-reactor
    # # TODO: This currently doesn't compile but it probably not needed
    # # except for interacive development
    # cabal install -j \
    #     --extra-include-dirs=$(pkg_path_for zlib)/include \
    #     --extra-lib-dirs=$(pkg_path_for zlib)/lib \
    #     --extra-lib-dirs=$(pkg_path_for gmp)/lib \
    #     --extra-lib-dirs=$(pkg_path_for ncurses)/lib \
    #     elm-reactor

}

do_install() {
    cd $CACHE_PATH
    cp -r .cabal-sandbox/bin ${pkg_prefix}/
}

