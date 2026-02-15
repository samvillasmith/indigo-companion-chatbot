#!/bin/bash
# ============================================================
# RunPod Orpheus TTS Startup Script
# ============================================================
# Run this after restarting your Orpheus TTS pod.
# Prerequisites: Everything already built and saved in /workspace
#
# Pod setup (when creating a NEW pod):
#   - GPU: RTX 4090
#   - Template: PyTorch
#   - Container disk: 30 GB
#   - Volume disk: 20 GB
#   - Expose HTTP Ports: 8888
#
# For a FRESH pod (nothing in /workspace), run:
#   bash runpod-orpheus-setup.sh
#
# For a RESTARTED pod (files already in /workspace), run:
#   bash runpod-orpheus-startup.sh
# ============================================================

set -e

echo "============================================"
echo "  Orpheus TTS - Pod Restart Startup Script"
echo "============================================"
echo ""

# --- Step 1: Install runtime dependencies ---
echo "[1/5] Installing runtime dependencies..."
apt-get update -qq && apt-get install -y -qq libportaudio2 psmisc > /dev/null 2>&1
echo "  ✓ Dependencies installed"

# --- Step 2: Copy model to /models if not present ---
echo "[2/5] Checking model files..."
if [ ! -f /models/orpheus-3b-0.1-ft-q4_k_m.gguf ]; then
    echo "  Copying model from /workspace..."
    mkdir -p /models
    cp -r /workspace/models/* /models/
    echo "  ✓ Model copied"
else
    echo "  ✓ Model already in place"
fi

# --- Step 3: Free up port 8888 (Jupyter uses it by default) ---
echo "[3/5] Freeing port 8888..."
fuser -k 8888/tcp 2>/dev/null || true
sleep 2
echo "  ✓ Port 8888 available"

# --- Step 4: Start llama.cpp server for Orpheus ---
echo "[4/5] Starting llama.cpp inference server on port 1234..."
if [ -f /workspace/llama-build/bin/llama-server ]; then
    LLAMA_SERVER="/workspace/llama-build/bin/llama-server"
elif [ -f /workspace/llama.cpp/build/bin/llama-server ]; then
    LLAMA_SERVER="/workspace/llama.cpp/build/bin/llama-server"
else
    echo "  ✗ ERROR: llama-server binary not found in /workspace!"
    echo "    Run the full setup script instead: bash runpod-orpheus-setup.sh"
    exit 1
fi

$LLAMA_SERVER \
    -m /models/orpheus-3b-0.1-ft-q4_k_m.gguf \
    -c 8192 \
    -ngl 99 \
    --host 0.0.0.0 \
    --port 1234 &

LLAMA_PID=$!
echo "  ✓ llama.cpp server started (PID: $LLAMA_PID)"

# Wait for llama server to be ready
echo "  Waiting for llama server to initialize..."
for i in {1..30}; do
    if curl -s http://127.0.0.1:1234/health > /dev/null 2>&1; then
        echo "  ✓ llama server is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "  ⚠ llama server took too long, continuing anyway..."
    fi
    sleep 1
done

# --- Step 5: Start Orpheus-FastAPI on port 8888 ---
echo "[5/5] Starting Orpheus-FastAPI on port 8888..."
if [ ! -d /workspace/Orpheus-FastAPI ]; then
    echo "  ✗ ERROR: Orpheus-FastAPI not found in /workspace!"
    echo "    Run the full setup script instead: bash runpod-orpheus-setup.sh"
    exit 1
fi

cd /workspace/Orpheus-FastAPI

# Ensure .env has port 8888
if grep -q "ORPHEUS_PORT=5005" .env 2>/dev/null; then
    sed -i 's/ORPHEUS_PORT=5005/ORPHEUS_PORT=8888/g' .env
fi

export PYTHONIOENCODING=utf-8
python app.py &

ORPHEUS_PID=$!
echo "  ✓ Orpheus-FastAPI started (PID: $ORPHEUS_PID)"

# Wait for Orpheus to be ready
echo "  Waiting for Orpheus-FastAPI to initialize..."
for i in {1..60}; do
    if curl -s http://127.0.0.1:8888/docs > /dev/null 2>&1; then
        echo "  ✓ Orpheus-FastAPI is ready"
        break
    fi
    if [ $i -eq 60 ]; then
        echo "  ⚠ Orpheus-FastAPI took too long, check logs above for errors"
    fi
    sleep 1
done

echo ""
echo "============================================"
echo "  ✓ Orpheus TTS is LIVE"
echo "============================================"
echo ""
echo "SillyTavern TTS settings:"
echo "  Provider:  OpenAI Compatible"
echo "  Endpoint:  https://YOUR-POD-ID-8888.proxy.runpod.net/v1/audio/speech"
echo "  API Key:   none"
echo "  Model:     orpheus"
echo "  Voices:    tara,leah,jess,mia,zoe,leo,dan,zac"
echo ""
echo "Process IDs:"
echo "  llama.cpp:      $LLAMA_PID"
echo "  Orpheus-FastAPI: $ORPHEUS_PID"
echo ""
echo "To stop everything:  kill $LLAMA_PID $ORPHEUS_PID"
echo ""
