#!/bin/bash
# ============================================================
# RunPod Orpheus TTS - FULL SETUP (Fresh Pod)
# ============================================================
# Run this ONLY on a brand new pod with nothing in /workspace.
# For restarted pods, use: bash runpod-orpheus-startup.sh
#
# Pod setup:
#   - GPU: RTX 4090
#   - Template: PyTorch
#   - Container disk: 30 GB
#   - Volume disk: 20 GB
#   - Expose HTTP Ports: 8888
#
# Total setup time: ~15 minutes
# ============================================================

set -e

echo "============================================"
echo "  Orpheus TTS - Full Setup (Fresh Pod)"
echo "============================================"
echo ""

# --- Step 1: System dependencies ---
echo "[1/7] Installing system dependencies..."
apt-get update -qq && apt-get install -y -qq build-essential cmake git libportaudio2 psmisc > /dev/null 2>&1
echo "  ✓ System dependencies installed"

# --- Step 2: Build llama.cpp ---
echo "[2/7] Building llama.cpp (this takes ~5-10 minutes)..."
cd /workspace
if [ ! -d llama.cpp ]; then
    git clone --quiet https://github.com/ggerganov/llama.cpp
fi
cd llama.cpp
cmake -B build -DGGML_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES=89 > /dev/null 2>&1
cmake --build build --config Release -j$(nproc) 2>&1 | tail -1
echo "  ✓ llama.cpp built"

# --- Step 3: Download Orpheus model ---
echo "[3/7] Downloading Orpheus TTS model..."
pip install -q huggingface-hub 2>/dev/null
python -c "
from huggingface_hub import hf_hub_download
hf_hub_download(
    'isaiahbjork/orpheus-3b-0.1-ft-Q4_K_M-GGUF',
    'orpheus-3b-0.1-ft-q4_k_m.gguf',
    local_dir='/workspace/models'
)
" 2>&1 | tail -1
mkdir -p /models
cp /workspace/models/orpheus-3b-0.1-ft-q4_k_m.gguf /models/
echo "  ✓ Orpheus model downloaded"

# --- Step 4: Clone and configure Orpheus-FastAPI ---
echo "[4/7] Setting up Orpheus-FastAPI..."
cd /workspace
if [ ! -d Orpheus-FastAPI ]; then
    git clone --quiet https://github.com/Lex-au/Orpheus-FastAPI.git
fi
cd Orpheus-FastAPI
pip install -q -r requirements.txt 2>/dev/null
cp .env.example .env
sed -i 's/Orpheus-3b-FT-Q8_0.gguf/orpheus-3b-0.1-ft-q4_k_m.gguf/g' .env
sed -i 's/ORPHEUS_PORT=5005/ORPHEUS_PORT=8888/g' .env
echo "  ✓ Orpheus-FastAPI configured"

# --- Step 5: Free port 8888 ---
echo "[5/7] Freeing port 8888..."
fuser -k 8888/tcp 2>/dev/null || true
sleep 2
echo "  ✓ Port 8888 available"

# --- Step 6: Start llama.cpp server ---
echo "[6/7] Starting llama.cpp inference server on port 1234..."
cd /workspace/llama.cpp
./build/bin/llama-server \
    -m /models/orpheus-3b-0.1-ft-q4_k_m.gguf \
    -c 8192 \
    -ngl 99 \
    --host 0.0.0.0 \
    --port 1234 &

LLAMA_PID=$!
echo "  ✓ llama.cpp server started (PID: $LLAMA_PID)"

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

# --- Step 7: Start Orpheus-FastAPI ---
echo "[7/7] Starting Orpheus-FastAPI on port 8888..."
cd /workspace/Orpheus-FastAPI
export PYTHONIOENCODING=utf-8
python app.py &

ORPHEUS_PID=$!
echo "  ✓ Orpheus-FastAPI started (PID: $ORPHEUS_PID)"

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
echo "  ✓ FULL SETUP COMPLETE"
echo "============================================"
echo ""
echo "SillyTavern TTS settings:"
echo "  Provider:  OpenAI Compatible"
echo "  Endpoint:  https://YOUR-POD-ID-8888.proxy.runpod.net/v1/audio/speech"
echo "  API Key:   none"
echo "  Model:     orpheus"
echo "  Voices:    tara,leah,jess,mia,zoe,leo,dan,zac"
echo ""
echo "Everything is saved in /workspace and will persist across pod restarts."
echo "Next time, just run:  bash /workspace/runpod-orpheus-startup.sh"
echo ""
echo "Process IDs:"
echo "  llama.cpp:      $LLAMA_PID"
echo "  Orpheus-FastAPI: $ORPHEUS_PID"
echo ""
echo "To stop everything:  kill $LLAMA_PID $ORPHEUS_PID"
echo ""

# Copy startup script to workspace for easy access after restarts
cp /workspace/Orpheus-FastAPI/../runpod-orpheus-startup.sh /workspace/ 2>/dev/null || true
