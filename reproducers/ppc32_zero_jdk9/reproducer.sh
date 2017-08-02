#!/bin/bash
#
# Reproducer which triggers an issue (SEGV or other) when run with a
# problematic hotspot (libjvm.so).

JDK=/openjdk9-hs-comp/build/linux-ppc-normal-zero-slowdebug/images/jdk/
HOTSPOT=/openjdk9-hs-comp/build/linux-ppc-normal-zero-fastdebug/jdk/lib/server

JMODS_DIR_TMP=/openjdk9-hs-comp/build/linux-ppc-normal-zero-fastdebug/images/jmods
SUPPORT_FILE_TMP=/openjdk9-hs-comp/build/linux-ppc-normal-zero-fastdebug/support/jmods/java.activation.jmod
rm -rf $JMODS_DIR_TMP $SUPPORT_FILE_TMP
mkdir -p $JMODS_DIR_TMP
mkdir -p $(dirname $SUPPORT_FILE_TMP)

JDK_EXPL=$JDK/../../jdk

JAVA_HOME=$JDK \
$JAVA_HOME/bin/java \
-XXaltjvm=$HOTSPOT \
-Dsun.java.launcher.is_altjvm=true \
-Dapplication.home=$JDK_EXPL \
-Xms8m -XX:+UseSerialGC -Xms32M -Xmx512M -XX:TieredStopAtLevel=1 \
-cp $JDK_EXPL/modules/jdk.jlink \
-Djdk.module.main=jdk.jlink jdk.tools.jmod.Main create --module-version 9-internal \
--target-platform linux-ppc --module-path $JMODS_DIR_TMP --exclude "**{_the.*,_*.marker,*.diz,*.debuginfo,*.dSYM/**,*.dSYM,*.pdb,*.map}" \
--class-path $JDK_EXPL/modules/java.activation --legal-notices $JDK_EXPL/../support/modules_legal/java.base $SUPPORT_FILE_TMP
exit $?
