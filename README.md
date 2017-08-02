Hotspot JVM scripts
===================

Finds a compiler OPTO flag which, if disabled, passes a reproducer.

Usage
=====

First, create a reproducer which triggers the issue `reproducer.sh`.
Adjust symlink as necessary.

Create a build script, `build.sh`, which builds HotSpot with the given
set of flags.

Change `ALL_FLAGS` variable according to your GCC version and invoke
the script as follows:

    ./bsearch_flags.sh

