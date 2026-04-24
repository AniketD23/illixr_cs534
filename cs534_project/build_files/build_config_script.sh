#!/bin/bash

if [[ -z "$ILLIXR_HOME" ]]; then
  echo "Error: ILLIXR_HOME is not set"
  exit 1
fi

cd ${ILLIXR_HOME}/build 

${ILLIXR_HOME}/build/bin_cmake/cmake-3.31.11-linux-x86_64/bin/cmake .. \
  -DCMAKE_VERBOSE_MAKEFILE=ON \
  -DCMAKE_INSTALL_PREFIX=${ILLIXR_HOME} \
  -DBUILD_SHARED_LIBS=ON \
  -DCUDA_TOOLKIT_ROOT_DIR=$(dirname $(dirname $(which nvcc))) \
  -DCMAKE_CUDA_COMPILER=$(which nvcc) \
  -DCUDA_COMPAT_GCC=/software/gcc-11.2.0-rh8/bin/g++ \
  -DCMAKE_C_FLAGS="-I${ILLIXR_HOME}/build/local_deps -I/software/cuda-11.6/include" \
  -DCMAKE_CXX_FLAGS="-I${ILLIXR_HOME}/build/local_deps -I/software/cuda-11.6/include" \
  -DCMAKE_CUDA_FLAGS="--expt-relaxed-constexpr -Xcompiler=-fpermissive" \
  -DCMAKE_EXE_LINKER_FLAGS="-L${ILLIXR_HOME}/build/local_deps/omp_shim -Wl,-rpath,/software/gcc-11.2.0-rh8/lib64" \
  -DCMAKE_SHARED_LINKER_FLAGS="-L${ILLIXR_HOME}/build/local_deps/omp_shim -Wl,-rpath,/software/gcc-11.2.0-rh8/lib64" \
  -DOpenMP_C_FLAGS="-fopenmp" \
  -DOpenMP_C_LIB_NAMES="gomp" \
  -DOpenMP_gomp_LIBRARY=/software/gcc-11.2.0-rh8/lib64/libgomp.so \
  -DOpenMP_CXX_LIBRARY=/software/gcc-11.2.0-rh8/lib64/libgomp.so \
  -DOpenMP_CXX_FLAGS="-fopenmp" \
  -DOpenMP_CXX_LIB_NAMES="gomp" \
  -DUSE_ADA.OFFLINE_SCANNET=ON \
  -DUSE_TCP_NETWORK_BACKEND=OFF \
  -DUSE_ADA.DEVICE_RX=OFF \
  -DUSE_ADA.DEVICE_TX=OFF \
  -DUSE_ADA.SERVER_RX=ON \
  -DUSE_ADA.SERVER_TX=ON \
  -DUSE_ADA.INFINITAM=ON \
  -DUSE_ADA.MESH_COMPRESSION=ON \
  -DUSE_ADA.MESH_DECOMPRESSION_GREY=ON \
  -DUSE_ADA.SCENE_MANAGEMENT=ON \
  -DCMAKE_BUILD_TYPE=Release