#!/bin/bash
#set -xv

# The build script. First passed argument are the
# cflags to use.
BUILD_SCRIPT="$(pwd)/build.sh"
REPRODUCER_SCRIPT="$(pwd)/reproducer.sh"

TMP_DIR="$(mktemp -d)"

# Supported OPTO flags by GCC 10, GCC 9.1.0
# See: https://gcc.gnu.org/onlinedocs/gcc-9.1.0/gcc/Optimize-Options.html#Optimize-Options
declare -a ALL_FLAGS=(
-fno-allocation-dce
-fno-align-functions
-fno-align-jumps
-fno-align-labels
-fno-align-loops
-fno-auto-inc-dec
-fno-branch-count-reg
-fno-caller-saves
-fno-code-hoisting
-fno-combine-stack-adjustments
-fno-compare-elim
-fno-cprop-registers
-fno-crossjumping
-fno-cse-follow-jumps
-fno-cse-skip-blocks
-fno-dce
-fno-defer-pop
-fno-delayed-branch
-fno-delete-null-pointer-checks
-fno-devirtualize
-fno-devirtualize-speculatively
-fno-dse
-fno-expensive-optimizations
-fno-finite-loops
-fno-forward-propagate
-fno-gcse
-fno-gcse-after-reload
-fno-gcse-lm
-fno-guess-branch-probability
-fno-hoist-adjacent-loads
-fno-if-conversion
-fno-if-conversion2
-fno-indirect-inlining
-fno-inline-functions
-fno-inline-functions-called-once
-fno-inline-small-functions
-fno-ipa-bit-cp
-fno-ipa-cp
-fno-ipa-cp-clone
-fno-ipa-icf
-fno-ipa-profile
-fno-ipa-pure-const
-fno-ipa-ra
-fno-ipa-reference
-fno-ipa-reference-addressable
-fno-ipa-sra
-fno-ipa-vrp
-fno-isolate-erroneous-paths-dereference
-fno-loop-interchange
-fno-loop-unroll-and-jam
-fno-lra-remat
-fno-merge-constants
-fno-move-loop-invariants
-fno-omit-frame-pointer
-fno-optimize-sibling-calls
-fno-optimize-strlen
-fno-partial-inlining
-fno-peel-loops
-fno-peephole2
-fno-predictive-commoning
-fno-reorder-blocks
-fno-reorder-blocks-and-partition
-fno-reorder-functions
-fno-rerun-cse-after-loop
-fno-sched-interblock
-fno-sched-spec
-fno-schedule-insns
-fno-schedule-insns2
-fno-shrink-wrap
-fno-shrink-wrap-separate
-fno-split-paths
-fno-split-wide-types
-fno-ssa-backprop
-fno-ssa-phiopt
-fno-store-merging
-fno-strict-aliasing
-fno-thread-jumps
-fno-tree-bit-ccp
-fno-tree-builtin-call-dce
-fno-tree-ccp
-fno-tree-ch
-fno-tree-coalesce-vars
-fno-tree-copy-prop
-fno-tree-dce
-fno-tree-dominator-opts
-fno-tree-dse
-fno-tree-forwprop
-fno-tree-fre
-fno-tree-loop-distribute-patterns
-fno-tree-loop-distribution
-fno-tree-loop-vectorize
-fno-tree-partial-pre
-fno-tree-phiprop
-fno-tree-pre
-fno-tree-pta
-fno-tree-scev-cprop
-fno-tree-sink
-fno-tree-slp-vectorize
-fno-tree-slsr
-fno-tree-sra
-fno-tree-switch-conversion
-fno-tree-tail-merge
-fno-tree-ter
-fno-tree-vrp
-fno-unit-at-a-time
-fno-unswitch-loops
-fno-vect-cost-model
-fno-version-loops-for-strides
)

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

sanity_check() {
  all_flags="$TMP_DIR/all.cflags"
  echo "${ALL_FLAGS[@]}" > $all_flags
  run_build $all_flags
  run_reproducer
  if [ $? -ne 0 ]; then
    echo "Sanity check failed. Disabling all flags does NOT fix the build!"
    exit 1
  fi
}

sanity_check

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
