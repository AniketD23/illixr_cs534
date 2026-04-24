#!/bin/bash
# source_env.sh — source this once per shell before building illixr_cs534.
#
# Usage:
#     export ILLIXR_HOME=/shared/workspace/{YOUR_NETID}/cs534/illixr_cs534
#     source source_env.sh
#
# See BUILD_FIXES_README.md for the full story of why each of these is needed.
#
# IMPORTANT: This script strips /software/gcc-11.2.0-rh8/lib64 from
# LD_LIBRARY_PATH and does NOT add it back. That path has an older
# libstdc++ (GLIBCXX_3.4.29) that breaks cmake and clang, both of which
# link against a newer one (GLIBCXX_3.4.30+).
#
# The produced .so files carry -Wl,-rpath,/software/gcc-11.2.0-rh8/lib64
# baked in (set via CMAKE_{EXE,SHARED}_LINKER_FLAGS), so runtime can find
# libgomp without LD_LIBRARY_PATH. If you need to run the binaries
# directly and the loader complains about libgomp, see the "Runtime"
# note at the bottom.

if [[ -z "$ILLIXR_HOME" ]]; then
  echo "Error: set ILLIXR_HOME before sourcing this file."
  echo "  export ILLIXR_HOME=/shared/workspace/{YOUR_NETID}/cs534/illixr_cs534"
  return 1 2>/dev/null || exit 1
fi

# 1. CUDA 11.6 (NOT 11.5 — 11.5's cudafe++ can't parse GCC 11 <functional>).
module unload cuda-toolkit/11.5 2>/dev/null
module load cuda-toolkit/11.6

# 2. GCC 11.2 module for libgomp runtime. We only want the binaries
#    (g++-11 for CUDA_COMPAT_GCC) and the library (libgomp.so for linking);
#    we DO NOT want this module's lib64 on LD_LIBRARY_PATH because its
#    libstdc++ is older than what cmake/clang need.
module load gcc/11.2.0-rh8

# 3. CRITICAL: strip /software/gcc-11.2.0-rh8 from LD_LIBRARY_PATH.
#    The module load above prepended it; we need it gone, permanently,
#    for the whole build. We leave it in LIBRARY_PATH (compile-time) via
#    CMake's link flags, and rpath it into the produced .so files.
export LD_LIBRARY_PATH=$(echo "$LD_LIBRARY_PATH" | tr ':' '\n' \
                         | grep -v '/software/gcc-11.2.0-rh8' | paste -sd:)

# 4. Bundled cmake 3.31.11 (system cmake 3.22.1 is too old, needs 3.24+).
export PATH="${ILLIXR_HOME}/build/bin_cmake/cmake-3.31.11-linux-x86_64/bin:${PATH}"

# 5. CPATH — extra include search path, honored by gcc and clang after
#    explicit -I flags. Makes cuda.h findable for subtargets that hardcode
#    -I /usr/local/cuda/include (doesn't exist on grandteton).
export CPATH="/software/cuda-11.6/include${CPATH:+:${CPATH}}"

# 6. LIBRARY_PATH — linker's equivalent of CPATH. Lets clang's
#    auto-appended -lomp resolve against the omp_shim without every
#    subtarget passing -L explicitly.
export LIBRARY_PATH="${ILLIXR_HOME}/build/local_deps/omp_shim${LIBRARY_PATH:+:${LIBRARY_PATH}}"

# Sanity check — make sure the tools we need actually work now.
echo "illixr_cs534 build environment ready."
echo "  ILLIXR_HOME:     $ILLIXR_HOME"
echo "  CUDA:            $(which nvcc 2>/dev/null) ($(nvcc --version 2>/dev/null | grep release | sed 's/^.*release /release /'))"
echo "  cmake:           $(which cmake) ($(cmake --version 2>/dev/null | head -1 | awk '{print $3}'))"
echo "  g++ (host):      $(g++ --version 2>/dev/null | head -1)"
echo "  clang (main):    $(clang --version 2>/dev/null | head -1)"
echo ""
echo "  CPATH:           $CPATH"
echo "  LIBRARY_PATH:    $LIBRARY_PATH"
echo "  LD_LIBRARY_PATH: $LD_LIBRARY_PATH"
echo ""

# Quick smoke test — does clang start without GLIBCXX errors?
if ! /usr/bin/clang --version >/dev/null 2>&1; then
  echo "WARNING: /usr/bin/clang is not working. Check LD_LIBRARY_PATH for"
  echo "  /software/gcc-11.2.0-rh8 — it should be stripped."
  echo "  Current: $LD_LIBRARY_PATH"
fi

# --- Runtime note ---------------------------------------------------------
# If you later run the built binaries and the dynamic loader complains
# that libgomp.so.1 is missing, you have two options:
#
#   (a) Add gcc-11.2's lib64 to LD_LIBRARY_PATH *only at runtime*:
#         export LD_LIBRARY_PATH="/software/gcc-11.2.0-rh8/lib64:$LD_LIBRARY_PATH"
#         ./main.opt.exe
#
#   (b) Confirm the rpath is baked in:
#         readelf -d path/to/libplugin.ada.infinitam.opt.so | grep RPATH
#       Should show /software/gcc-11.2.0-rh8/lib64. If so, no env change
#       needed.