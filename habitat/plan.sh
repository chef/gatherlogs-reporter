pkg_name=gatherlogs
pkg_origin=will
pkg_maintainer="Will Fisher <will@chef.io>"
pkg_license=('Apache-2.0')
pkg_deps=(
  core/ruby
)
pkg_build_deps=(
  core/readline
  core/sed
)
pkg_bin_dirs=(bin)

pkg_version() {
  cat "$SRC_PATH/VERSION"
}

do_before() {
  do_default_before
  update_pkg_version
}

do_prepare() {
  export GEM_HOME="$pkg_prefix/lib"
  build_line "Setting GEM_HOME=$GEM_HOME"
  export GEM_PATH="$GEM_HOME"
  build_line "Setting GEM_PATH=$GEM_PATH"
}

do_unpack() {
  mkdir -pv "$HAB_CACHE_SRC_PATH/$pkg_dirname"
  cp -RT "$PLAN_CONTEXT"/.. "$HAB_CACHE_SRC_PATH/$pkg_dirname/"
}

do_build() {
  pushd "$HAB_CACHE_SRC_PATH/$pkg_dirname/"
    build_line "gem build gatherlogs.gemspec"
    gem build gatherlogs.gemspec
  popd
}

do_install() {
  pushd "$HAB_CACHE_SRC_PATH/$pkg_dirname/"
    build_line "Gem install gatherlogs gem"
    gem install gatherlogs-*.gem --no-document
  popd

  wrap_gatherlogs_bin
}

# Need to wrap the gatherlogs binary to ensure GEM_HOME/GEM_PATH is correct
wrap_gatherlogs_bin() {
  local bin="$pkg_prefix/bin/check_logs"
  local real_bin="$GEM_HOME/gems/gatherlogs-${pkg_version}/bin/check_logs"
  build_line "Adding wrapper $bin to $real_bin"
  cat <<EOF > "$bin"
#!$(pkg_path_for busybox-static)/bin/sh
set -e
export GEM_HOME="$GEM_HOME"
export GEM_PATH="$GEM_PATH"
exec $(pkg_path_for core/ruby)/bin/ruby $real_bin \$@
EOF
  chmod -v 755 "$bin"
}

do_strip() {
  return 0
}
