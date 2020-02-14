#!/bin/bash
JDK=openjdk-11/openjdk/build/jdk/
#JDK=$1
export JAVA_HOME=$JDK
HOTSPOT=openjdk-11/openjdk/build/support/modules_libs/java.base/server/
  ${JDK}/bin/java \
    -XXaltjvm=$HOTSPOT \
    -Dsun.java.launcher.is_altjvm=true \
    -version
  retval=$?
exit $retval
