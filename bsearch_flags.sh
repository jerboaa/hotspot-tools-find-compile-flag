#!/bin/bash
#set -xv

# The build script. First passed argument are the
# cflags to use.
BUILD_SCRIPT="$(pwd)/build.sh"
REPRODUCER_SCRIPT="$(pwd)/reproducer.sh"

TMP_DIR="$(mktemp -d)"

# Supported OPTO flags by GCC 4.8.5
# See: https://gcc.gnu.org/onlinedocs/gcc-4.8.5/gcc/Optimize-Options.html
declare -a ALL_FLAGS=(
-fno-auto-inc-dec 
-fno-compare-elim 
-fno-cprop-registers 
-fno-dce 
-fno-defer-pop 
-fno-delayed-branch 
-fno-dse 
-fno-guess-branch-probability 
-fno-if-conversion2 
-fno-if-conversion 
-fno-ipa-pure-const 
-fno-ipa-profile 
-fno-ipa-reference 
-fno-merge-constants
-fno-split-wide-types 
-fno-tree-bit-ccp 
-fno-tree-builtin-call-dce 
-fno-tree-ccp 
-fno-tree-ch 
-fno-tree-copyrename 
-fno-tree-dce 
-fno-tree-dominator-opts 
-fno-tree-dse 
-fno-tree-forwprop 
-fno-tree-fre 
-fno-tree-phiprop 
-fno-tree-slsr 
-fno-tree-sra 
-fno-tree-pta 
-fno-tree-ter 
-fno-unit-at-a-time
-fno-omit-frame-pointer
-fno-thread-jumps 
-fno-align-functions
-fno-align-jumps 
-fno-align-loops
-fno-align-labels 
-fno-caller-saves 
-fno-crossjumping 
-fno-cse-follow-jumps
-fno-cse-skip-blocks 
-fno-delete-null-pointer-checks 
-fno-devirtualize 
-fno-expensive-optimizations 
-fno-gcse
-fno-gcse-lm  
-fno-hoist-adjacent-loads 
-fno-inline-small-fno-unctions 
-fno-indirect-inlining 
-fno-ipa-sra 
-fno-optimize-sibling-calls 
-fno-partial-inlining 
-fno-peephole2 
-fno-regmove 
-fno-reorder-blocks
-fno-reorder-fno-unctions 
-fno-rerun-cse-after-loop  
-fno-sched-interblock
-fno-sched-spec 
-fno-schedule-insns
-fno-schedule-insns2 
-fno-strict-aliasing
-fno-strict-overflow 
-fno-tree-switch-conversion
-fno-tree-tail-merge 
-fno-tree-pre 
-fno-tree-vrp
-fno-inline-fno-unctions
-fno-unswitch-loops
-fno-predictive-commoning
-fno-gcse-after-reload
-fno-tree-vectorize
-fno-vect-cost-model
-fno-tree-partial-pre
-fno-ipa-cp-clone)

split() {
  local len=${#FLAGS[@]}
  local file1=$1
  local file2=$2

  local half=$(( $len / 2 ))
  local first=""
  local second=""
  echo
  echo "splitting ${FLAGS[@]}"
  echo
  i=0
  while [ $i -lt $half ]; do
    first="${first} ${FLAGS[$i]}"
    i=$(( $i + 1 ))
  done
  while [ $i -lt $len ]; do
    second="${second} ${FLAGS[$i]}"
    i=$(( $i + 1 ))
  done
  echo "$first" > $file1
  echo "$second" > $file2
}

update_vars() {
  len_first=$(cat $first | wc -w)
  len_second=$(cat $second | wc -w)
  total=$(( $len_second + $len_first ))
}

check_success() {
  local retval=$1
  local msg=$2

  if [ $retval -ne 0 ]; then
     echo "Error: $msg"
     exit 1
  fi
}

run_build() {
  local cflags_file=$1
  local cflags="$(echo $(cat $cflags_file))"
  echo
  echo "running build with: $cflags"
  echo
  $BUILD_SCRIPT "$cflags"
  check_success $? "Build failed with cflags: $cflags"
}

run_reproducer() {
  $REPRODUCER_SCRIPT
  return $?
}

FLAGS=( "${ALL_FLAGS[@]}" )
first="$TMP_DIR/first.cflags"
second="$TMP_DIR/second.cflags"
split $first $second
update_vars

while [ $total -gt 1 ]; do
  run_build $first
  run_reproducer
  if [ $? -eq 0 ]; then
     echo "First half contained flag which fixes issue."
     FLAGS=( $(cat $first) )
  else
     echo "Second half contained flag which fixes issue."
     FLAGS=( $(cat $second) )
  fi
  split $first $second
  update_vars
done

if [ $len_first -eq 1 ]; then
  echo "Flag which fixes issue is: $(cat $first)"
else
  echo "Flag which fixes issue is: $(cat $second)"
fi
rm -rf $TMP_DIR
