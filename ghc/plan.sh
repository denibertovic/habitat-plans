pkg_name=ghc
pkg_origin=denibertovic
pkg_version=7.10.2
pkg_description="The Glasgow Haskell Compiler, a compiler and interactive environment for the Haskell functional programming language."
pkg_source=http://downloads.haskell.org/~ghc/${pkg_version}/ghc-${pkg_version}-x86_64-unknown-linux-deb7.tar.xz
pkg_shasum=0144791f0cc5ef5991356b3b3a4521da8072dd1c216a48e7d2dfbbdca827cdf1
pkg_upstream_url=https://github.com/ghc/ghc
pkg_license=('BSD-3-Clause')
pkg_maintainer="The Habitat Maintainers <humans@habitat.sh>"
pkg_bin_dirs=(bin)
pkg_lib_dirs=(lib)
pkg_build_deps=(
  core/patchelf
)
pkg_deps=(
  core/glibc
  core/gmp/6.1.0
  core/perl
  core/gcc
  core/make
  core/libffi
  dysinger/ncurses5-compat-libs/6.0/20170619182942
)

ghc_patch_rpath() {
  RELATIVE_TO=$(dirname "$1")
  RELATIVE_PATHS=$( (for LIB_PATH in "${@:2}"; do echo "\$ORIGIN/$(realpath --relative-to="${RELATIVE_TO}" "${LIB_PATH}")"; done) | paste -sd ':' )
  patchelf --set-rpath "${LD_RUN_PATH}:${RELATIVE_PATHS}" "$1"
}
export -f ghc_patch_rpath

do_build() {
  build_line "Fixing interpreter for binaries:"

  find . -type f -executable \
    -exec sh -c 'file -i "$1" | grep -q "x-executable; charset=binary"' _ {} \; \
    -print \
    -exec patchelf --interpreter "$(pkg_path_for glibc)/lib/ld-linux-x86-64.so.2" {} \;

  export LD_LIBRARY_PATH="$LD_RUN_PATH"

  ./configure --prefix="${pkg_prefix}"

}

do_install() {
  local GHC_LIB_PATHS

  do_default_install

  pushd "${pkg_prefix}" > /dev/null

  GHC_LIB_PATHS=$(find . -name '*.so' -printf '%h\n' | uniq)

  build_line "Fixing rpath for binaries:"

  find . -type f -executable \
    -exec sh -c 'file -i "$1" | grep -q "x-executable; charset=binary"' _ {} \; \
    -print \
    -exec bash -c 'ghc_patch_rpath $1 $2 ' _ "{}" "$GHC_LIB_PATHS" \;

  build_line "Fixing ghc-split perl interpreter"

  fix_interpreter "${pkg_prefix}/lib/ghc-7.10.2/ghc-split" core/perl bin/perl

  popd > /dev/null
}

do_strip() {
  return 0
}
