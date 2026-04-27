#!/bin/bash
# Run ILLIXR Ada offline ScanNet experiments sequentially
# Reads experiment names from experiments.txt and runs each corresponding YAML config
if [[ -z "$ILLIXR_HOME" ]]; then
  echo "Error: ILLIXR_HOME is not set"
  exit 1
fi

CONFIG_DIR="${ILLIXR_HOME}/cs534_project/configs"
BUILD_DIR="${ILLIXR_HOME}/build"
EXPERIMENTS_FILE="${CONFIG_DIR}/experiments.txt"
LOGS_DIR="${BUILD_DIR}/logs"
DATA_DIR="${BUILD_DIR}/recorded_data"

# How long to wait after last frame before killing (seconds)
POST_COMPLETION_WAIT=120

# Environment setup
export LD_PRELOAD=~/lib-override/libomp.so
export LD_LIBRARY_PATH=~/lib-override:${ILLIXR_HOME}/lib:${ILLIXR_HOME}/build:/software/cuda-11.6/lib64:/software/cuda-11.6/extras/CUPTI/lib64
export OMP_NUM_THREADS=1
export DISPLAY=:99
export ILLIXR_LOG_LEVEL=warn

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

    # Backup existing log and data directories before run
    if [[ -f "$LOGS_DIR/illixr.log" ]]; then
        backup_timestamp=$(date +%s)
        mv "$LOGS_DIR/illixr.log" "$LOGS_DIR/illixr_${backup_timestamp}.log"
        echo "Backed up previous log to: illixr_${backup_timestamp}.log"
    fi
    
    if [[ -d "$DATA_DIR" ]]; then
        backup_timestamp=$(date +%s)
        mv "$DATA_DIR" "${DATA_DIR}_${backup_timestamp}"
        echo "Backed up previous data directory to: recorded_data_${backup_timestamp}"
        mkdir -p "$DATA_DIR"
    fi


    # Run in background, log to file
    rm -f ${ILLIXR_HOME}/build/logs/illixr.log
    ./main.opt.exe -y "$yaml_file" > "${experiment}_log.txt" 2>&1 &
    PID=$!

    # Monitor: wait for completion, then give time for file write
    while kill -0 $PID; do
        if grep -q "Scene Management processed all frames\|sending last frame" "${experiment}_log.txt"; then
            echo "Last frame sent, waiting ${POST_COMPLETION_WAIT}s for output file..."
            sleep $POST_COMPLETION_WAIT
            kill $PID
            sleep 2
            kill -9 $PID
            break
        fi
        sleep 5
    done

    wait $PID

    # Show log tail
    echo "--- Log tail ---"
    tail -5 "${experiment}_log.txt"
    echo ""

    # Rename log file from this run
    if [[ -f "$LOGS_DIR/illixr.log" ]]; then
        mv "$LOGS_DIR/illixr.log" "$LOGS_DIR/illixr_${experiment}.log"
        echo "Saved log: illixr_${experiment}.log"
    fi
    
    # Rename data directory from this run
    if [[ -d "$DATA_DIR" ]]; then
        mv "$DATA_DIR" "${DATA_DIR}_${experiment}"
        echo "Saved data directory: recorded_data_${experiment}"
        mkdir -p "$DATA_DIR"
    fi
    
    # Check for output and rename
    newest_obj=$(ls -t *.obj | head -1)
    if [[ -n "$newest_obj" ]]; then
        echo "Output: $newest_obj ($(du -h "$newest_obj" | cut -f1))"
        mv "$newest_obj" "${experiment}_output.obj"
        echo "Renamed to: ${experiment}_output.obj"
    else
        echo "WARNING: No .obj output found for ${experiment}"
    fi

    # Cleanup any lingering processes
    pkill -f "main.opt.exe"
    sleep 3

    echo "Finished: ${experiment} at $(date)"
    echo ""
done < "$EXPERIMENTS_FILE"

echo "All experiments complete."
ls -lh *_output.obj

# Final cleanup: rename any remaining logs/data with timestamp
  if [[ -f "$LOGS_DIR/illixr.log" ]]; then
      final_timestamp=$(date +%s)
      mv "$LOGS_DIR/illixr.log" "$LOGS_DIR/illixr_final_${final_timestamp}.log"
  fi
  
  if [[ -d "$DATA_DIR" && $(ls -A "$DATA_DIR") ]]; then
      final_timestamp=$(date +%s)
      mv "$DATA_DIR" "${DATA_DIR}_final_${final_timestamp}"
  fi