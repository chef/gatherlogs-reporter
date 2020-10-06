pkg_name=gatherlogs_reporter
pkg_origin=chef
pkg_maintainer="Chef Support <support@chef.io>"
pkg_license=('Apache-2.0')
pkg_deps=(
  core/tar
  core/bzip2
  core/wget
  core/ruby
  core/gzip
  core/file
  core/grep
  core/bash
  core/findutils
  core/git
  core/coreutils
)

pkg_build_deps=(
  core/gcc
  core/make
)

pkg_bin_dirs=(bin)

pkg_version() {
  cat "$SRC_PATH/../../VERSION"
}

do_before() {
  do_default_before
  update_pkg_version
}

do_setup_environment() {
  update_pkg_version
  export GEM_HOME="$pkg_prefix/lib"
  export GEM_PATH="$GEM_HOME"

  set_runtime_env GEM_HOME "$GEM_HOME"
  set_buildtime_env GEM_HOME "$GEM_HOME"
  push_runtime_env GEM_PATH "$GEM_PATH"
  push_buildtime_env GEM_PATH "$GEM_PATH"
  set_buildtime_env BUILD_GEM "true"
}

do_unpack() {
  mkdir -pv "$HAB_CACHE_SRC_PATH/$pkg_dirname"
  cp -RT "$PLAN_CONTEXT"/../.. "$HAB_CACHE_SRC_PATH/$pkg_dirname/"
}

do_build() {
  pushd "$HAB_CACHE_SRC_PATH/$pkg_dirname/"
    build_line "gem build $pkg_name.gemspec ${GEM_HOME}"
    fix_interpreter "bin/*" core/coreutils bin/env

    gem build ${pkg_name}.gemspec
  popd
}

do_install() {
  pushd "$HAB_CACHE_SRC_PATH/$pkg_dirname/"
    build_line "Gem install ${pkg_name} gem"
    yes | gem install ${pkg_name}-*.gem --no-document
  popd

  wrap_bin 'gatherlog'
}

# Need to wrap the gatherlogs binary to ensure GEM_HOME/GEM_PATH is correct
wrap_bin() {
  local bin="$pkg_prefix/bin/$1"
  local real_bin="$GEM_PATH/gems/${pkg_name}-${pkg_version}/bin/$1"

  build_line "Adding wrapper $bin to $real_bin"
  cat <<EOF > "$bin"
#!$(pkg_path_for core/bash)/bin/bash
set -e

source $pkg_prefix/RUNTIME_ENVIRONMENT
export GEM_PATH GEM_HOME PATH

exec $real_bin \$@
EOF
  chmod -v 755 "$bin"
}

do_strip() {
  return 0
}
