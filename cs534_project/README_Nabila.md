# change the ILLIXR_HOME path and source_env.sh path for your path
export ILLIXR_HOME=/shared/workspace/ntasnim/cs534/illixr_cs534
source /shared/workspace/ntasnim/cs534/illixr_cs534/cs534_project/build_files/source_env.sh

cd $ILLIXR_HOME/build

# Create the libomp shim (only needed once — persists across reconfigures).
mkdir -p local_deps/omp_shim
ln -sf /software/gcc-11.2.0-rh8/lib64/libgomp.so \
       local_deps/omp_shim/libomp.so

# Clean configure and build.
rm -f CMakeCache.txt
rm -rf CMakeFiles/
bash /shared/workspace/ntasnim/cs534/illixr_cs534/cs534_project/build_files/build_config_script.sh
cmake --build . -j8 2>&1 | tee build.log
