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
  cd openjdk9-hs-comp
  # Debug build config:
  #  one of: "slowdebug" or "release"
  #  or "fastdebug"
  DEBUG=fastdebug
  JDK_TO_BUILD_WITH=/etc/alternatives/java_sdk_1.8.0

  make CONF=$DEBUG clean-hotspot

  bash configure  --with-boot-jdk="$JDK_TO_BUILD_WITH"  \
                  --disable-warnings-as-errors \
                  --with-debug-level="$DEBUG"  \
                  --disable-zip-debug-info \
                  --enable-unlimited-crypto  \
                  --with-zlib=system \
                  --with-giflib=system  \
                  --with-stdc++lib=dynamic \
                  --enable-dtrace=no \
                  --with-num-cores=8 \
                  --with-jvm-variants=zero \
                  --with-extra-cflags="$cflags" \
                  --with-extra-cxxflags="$cflags"
  if [ $? -ne 0 ]; then
    echo "Error: configure failed"
    exit 1
  fi

  make  SCTP_WERROR=  DEBUG_BINARIES=true  ENABLE_FULL_DEBUG_SYMBOLS=0  POST_STRIP_CMD=""  DISABLE_INTREE_EC=true  CONF=$DEBUG LOG=trace hotspot
  retval=$?

  # Leave openjdk9-hs-comp dir
  cd ..
  return $retval
}

build_hotspot "$__CFLAGS"
exit $?
