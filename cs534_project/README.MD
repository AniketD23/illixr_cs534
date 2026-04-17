Instructions for running:

Change `DCMAKE_INSTALL_PREFIX` in `cs534_project/build/build_config_script.sh` to the directory containing this repo

```bash
export ILLIXR_HOME=/path/to/illixr
module load cuda-toolkit/11.5
mkdir build && cd build && mkdir local_deps && mkdir bin_cmake && cd bin_cmake
wget https://github.com/Kitware/CMake/releases/download/v3.31.11/cmake-3.31.11-linux-x86_64.tar.gz
tar -xvf cmake-3.31.11-linux-x86_64.tar.gz
cp /usr/lib/gcc/x86_64-linux-gnu/11/include/omp.h ${ILLIXR_HOME}/build/local_deps
cp  ${ILLIXR_HOME}/cs534_project/build/build_config_script.sh ${ILLIXR_HOME}/build 
cd ${ILLIXR_HOME}/build
bash build_config_script.sh
cmake --build . -j8
```