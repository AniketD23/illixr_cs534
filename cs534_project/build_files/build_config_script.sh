# !/bin/bash
# this goes in the illixr build folder

if [[ -z "$ILLIXR_HOME" ]]; then
  echo "Error: ILLIXR_HOME is not set"
  exit 1
fi

${ILLIXR_HOME}/build/bin_cmake/cmake-3.31.11-linux-x86_64/bin/cmake .. \
  -DCMAKE_VERBOSE_MAKEFILE=ON \
  -DCMAKE_INSTALL_PREFIX=/shared/workspace/akdas3/cs534 \
  -DBUILD_SHARED_LIBS=ON \
  -DCMAKE_C_FLAGS="-I${ILLIXR_HOME}/build/local_deps" \
  -DCMAKE_CXX_FLAGS="-I${ILLIXR_HOME}/build/local_deps" \
  -DOpenMP_C_FLAGS="-fopenmp" \
  -DOpenMP_C_LIB_NAMES="gomp" \
  -DOpenMP_gomp_LIBRARY=/usr/lib/gcc/x86_64-linux-gnu/11/libgomp.so \
  -DOpenMP_CXX_LIBRARY=/usr/lib/gcc/x86_64-linux-gnu/11/libgomp.so \
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

  # -DCMAKE_PREFIX_PATH="" .. \
  # -DOpenMP_CXX_LIBRARY=/usr/lib/gcc/x86_64-linux-gnu/11/libgomp.so \  
