# change the ILLIXR_HOME path and source_env.sh path for your path

```bash
export ILLIXR_HOME=/shared/workspace/{YOUR_NETID}/cs534/illixr_cs534
export PATH=$PATH:${ILLIXR_HOME}/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${ILLIXR_HOME}/lib

source ${ILLIXR_HOME}/cs534_project/build_files/source_env.sh

cd ${ILLIXR_HOME}/build
```

# Create the libomp shim (only needed once — persists across reconfigures).

```bash
mkdir -p local_deps/omp_shim

ln -sf /software/gcc-11.2.0-rh8/lib64/libgomp.so \
       local_deps/omp_shim/libomp.so
```

# Clean configure and build.

```bash
cd ${ILLIXR_HOME}/cs534_project/build_files

rm -f CMakeCache.txt

rm -rf CMakeFiles/

bash ${ILLIXR_HOME}/cs534_project/build_files/build_config_script.sh

cd ${ILLIXR_HOME}/build

cmake --build . -j4 2>&1 | tee build.log
```

# Install.

```bash
cmake --install .
```

# Run with offline_scannet.
# First time:

```bash
mkdir -p ~/lib-override

ln -sf /path/to/libstdc++.so.6  ~/lib-override/

cd /tmp

wget http://archive.ubuntu.com/ubuntu/pool/universe/l/llvm-toolchain-14/libomp5-14_14.0.0-1ubuntu1.1_amd64.deb

dpkg -x libomp5-14_14.0.0-1ubuntu1.1_amd64.deb /tmp/libomp-extract

cp /tmp/libomp-extract/usr/lib/llvm-14/lib/libomp.so.5 ~/lib-override/

cd ~/lib-override && ln -sf libomp.so.5 libomp.so
```

# First time and every time:

```bash
cd ${ILLIXR_HOME}$/build

export LD_PRELOAD=~/lib-override/libomp.so

export LD_LIBRARY_PATH=~/lib-override:${ILLIXR_HOME}$/lib:${ILLIXR_HOME}$/build:/software/cuda-11.6/lib64:/software/cuda-11.6/extras/CUPTI/lib64

Xvfb :99 -screen 0 1920x1080x24 &

export DISPLAY=:99

export OMP_NUM_THREADS=1

./main.opt.exe -y ${ILLIXR_HOME}$/cs534_project/configs/fps_15.yaml
```

# if double free error:

```bash
gdb --args ./main.opt.exe -y ${ILLIXR_HOME}$/cs534_project/configs/fps_15.yaml

run
```