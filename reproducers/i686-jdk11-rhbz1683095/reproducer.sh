#!/bin/bash
JDK=openjdk-11/build/linux-x86-normal-server-release/images/jdk
#JDK=$1
HOTSPOT=openjdk-11/build/linux-x86-normal-server-release/jdk/lib/server
# Retrieved from JDK 11 test sources
GC_BASHER_CLASSES=/gc-basher-classes
for i in $(seq 50); do
  ${JDK}/bin/java \
    -XXaltjvm=$HOTSPOT \
    -Dsun.java.launcher.is_altjvm=true \
    -cp $GC_BASHER_CLASSES \
    -XX:MaxRAMPercentage=6 -Xmx256m \
    -XX:+UseG1GC TestGCBasherWithG1 120000
  retval=$?
  echo "iteration $i"
  if [ $retval -ne 0 ]; then
    exit $retval
  fi
done
exit $retval
