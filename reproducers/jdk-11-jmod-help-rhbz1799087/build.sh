#!/bin/bash
#
# Build script which expects the set of flags to pass to
# configure via --with-extra-cflags/--with-extra-cxxflags
# being passed in as the first argument.
#
# Example:
#
#  $ ./build.sh "-fno-tree-dce -fno-compare-elim"
#
__CFLAGS="$1"

build_hotspot() {
  local cflags="$1"
  # From here on out assume openjdk9-hs-comp directory
  # with a complete Openjdk9 forest exists
  pushd openjdk-11/openjdk/build
  # Debug build config:
  #  one of: "slowdebug" or "release"
  #  or "fastdebug"
  DEBUG=release
  JDK_TO_BUILD_WITH=/usr/lib/jvm/java-11-openjdk

  make CONF=$DEBUG clean-hotspot

  bash ../configure  --with-boot-jdk="$JDK_TO_BUILD_WITH" \
                  --with-debug-level="$DEBUG" \
		  --with-native-debug-symbols=internal \
		  --disable-warnings-as-errors \
                  --with-extra-cflags="$cflags" \
                  --with-extra-cxxflags="$cflags"
  if [ $? -ne 0 ]; then
    echo "Error: configure failed"
    exit 1
  fi

  make JAVAC_FLAGS=-g DISABLE_INTREE_EC=true LOG=debug hotspot
  retval=$?

  popd
  return $retval
}

build_hotspot "$__CFLAGS"
exit $?
