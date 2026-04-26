#!/bin/bash
# Run ILLIXR Ada offline ScanNet experiments sequentially
# Reads experiment names from experiments.txt and runs each corresponding YAML config

CONFIG_DIR="/shared/workspace/ntasnim/cs534/illixr_cs534/cs534_project/configs"
BUILD_DIR="/shared/workspace/ntasnim/cs534/illixr_cs534/build"
EXPERIMENTS_FILE="${CONFIG_DIR}/experiments.txt"

# How long to wait after last frame before killing (seconds)
POST_COMPLETION_WAIT=120

# Environment setup
export LD_PRELOAD=~/lib-override/libomp.so
export LD_LIBRARY_PATH=~/lib-override:/shared/workspace/ntasnim/cs534/illixr_cs534/lib:/shared/workspace/ntasnim/cs534/illixr_cs534/build:/software/cuda-11.6/lib64:/software/cuda-11.6/extras/CUPTI/lib64
export OMP_NUM_THREADS=1
export DISPLAY=:99

# Start Xvfb if not already running
if ! pgrep -x Xvfb > /dev/null; then
    Xvfb :99 -screen 0 1920x1080x24 &>/dev/null &
    sleep 1
    echo "Started Xvfb"
fi

cd "$BUILD_DIR" || exit 1

while IFS= read -r experiment; do
    # Skip empty lines and comments
    [[ -z "$experiment" || "$experiment" == \#* ]] && continue

    yaml_file="${CONFIG_DIR}/${experiment}.yaml"

    if [[ ! -f "$yaml_file" ]]; then
        echo "WARNING: ${yaml_file} not found, skipping"
        continue
    fi

    echo "=========================================="
    echo "Running experiment: ${experiment}"
    echo "Config: ${yaml_file}"
    echo "Started at: $(date)"
    echo "=========================================="

    # Run in background, log to file
    ./main.opt.exe -y "$yaml_file" > "${experiment}_log.txt" 2>&1 &
    PID=$!

    # Monitor: wait for completion, then give time for file write
    while kill -0 $PID 2>/dev/null; do
        if grep -q "Scene Management processed all frames\|sending last frame" "${experiment}_log.txt" 2>/dev/null; then
            echo "Last frame sent, waiting ${POST_COMPLETION_WAIT}s for output file..."
            sleep $POST_COMPLETION_WAIT
            kill $PID 2>/dev/null
            sleep 2
            kill -9 $PID 2>/dev/null
            break
        fi
        sleep 5
    done

    wait $PID 2>/dev/null

    # Show log tail
    echo "--- Log tail ---"
    tail -5 "${experiment}_log.txt"
    echo ""

    # Check for output and rename
    newest_obj=$(ls -t *.obj 2>/dev/null | head -1)
    if [[ -n "$newest_obj" ]]; then
        echo "Output: $newest_obj ($(du -h "$newest_obj" | cut -f1))"
        mv "$newest_obj" "${experiment}_output.obj"
        echo "Renamed to: ${experiment}_output.obj"
    else
        echo "WARNING: No .obj output found for ${experiment}"
    fi

    # Cleanup any lingering processes
    pkill -f "main.opt.exe" 2>/dev/null
    sleep 3

    echo "Finished: ${experiment} at $(date)"
    echo ""
done < "$EXPERIMENTS_FILE"

echo "All experiments complete."
ls -lh *_output.obj 2>/dev/null