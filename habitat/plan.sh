pkg_name=gatherlogs
pkg_origin=will
pkg_maintainer="Will Fisher <will@chef.io>"
pkg_license=('Apache-2.0')
pkg_deps=(
  core/busybox-static
  core/ruby
  chef/inspec
)
pkg_build_deps=(
)
pkg_bin_dirs=(bin)

pkg_version() {
  cat "$SRC_PATH/VERSION"
}

do_before() {
  do_default_before
  update_pkg_version
}

do_setup_environment() {
  export GEM_LIB_PATH="$pkg_prefix/lib"

  set_runtime_env GEM_HOME "$GEM_LIB_PATH"
  set_buildtime_env GEM_HOME "$GEM_LIB_PATH"
  set_runtime_env GEM_PATH "$GEM_LIB_PATH"
  set_buildtime_env GEM_PATH "$GEM_LIB_PATH"
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
  local real_bin="$GEM_LIB_PATH/gems/gatherlogs-${pkg_version}/bin/check_logs"

  build_line "Adding wrapper $bin to $real_bin"
  cat <<EOF > "$bin"
#!$(pkg_path_for busybox-static)/bin/sh
set -e

source $pkg_prefix/RUNTIME_ENVIRONMENT

exec $(pkg_path_for core/ruby)/bin/ruby $real_bin \$@
EOF
  chmod -v 755 "$bin"
}

do_strip() {
  return 0
}
