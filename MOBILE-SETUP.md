# Indigo Companion — Mobile Setup Guide

This guide documents how to access the Indigo Companion Chatbot from an iPhone (or any mobile device) with full VRM avatar, lip sync, TTS voice, and speech input — all running privately on your home PC.

---

## Architecture Overview

```
iPhone (Safari) → Tailscale VPN → Home PC (SillyTavern) → Venice AI (LLM)
                                                         → RunPod GPU (Orpheus TTS)
                                                         → VRM Extension (3D Avatar)
```

Your phone connects to your PC over Tailscale's encrypted mesh VPN. SillyTavern serves the chat UI, VRM avatar, and TTS audio. The LLM runs through Venice AI. Voice synthesis runs on a rented RTX 4090 via RunPod.

---

## Prerequisites

- Indigo Companion Chatbot fully configured on your PC (see main README)
- SillyTavern on the **staging** branch
- Tailscale account (free tier)
- RunPod account with Orpheus TTS pod
- iPhone with Safari

---

## Step 1: Switch SillyTavern to Staging Branch

The VRM extension requires the staging branch.

```bash
cd /c/AI/SillyTavern
git fetch origin
git checkout staging
git pull origin staging
./start.bat
```

---

## Step 2: Install Tailscale (Remote Access)

Tailscale creates a private encrypted tunnel between your phone and PC that works from anywhere — WiFi, cellular, any network.

### On your PC:
1. Download and install from https://tailscale.com/download
2. Sign in with Google, Microsoft, or Apple
3. Note your PC's Tailscale IP (e.g., `100.84.168.25`)

### On your iPhone:
1. Install Tailscale from the App Store
2. Sign in with the **same account**
3. Both devices should appear as connected in the Tailscale app

### Configure SillyTavern for remote access:

Edit `C:\AI\SillyTavern\config.yaml`:

```yaml
listen: true
whitelistMode: true
whitelist:
  - ::1
  - 127.0.0.1
  - 100.64.0.0/10    # Tailscale IP range
```

Restart SillyTavern.

### Privacy note:
Tailscale is just a network pipe. It doesn't inspect, filter, or log your traffic. End-to-end encrypted with WireGuard.

---

## Step 3: Start Orpheus TTS on RunPod

Start your existing RunPod pod, open the web terminal, and run:

```bash
bash /workspace/runpod-orpheus-startup.sh
```

Wait for "Orpheus TTS is LIVE", then copy your pod's port 8888 proxy URL from the RunPod dashboard:
```
https://[YOUR-POD-ID]-8888.proxy.runpod.net
```

### Startup script contents (saved at /workspace/runpod-orpheus-startup.sh):

```bash
#!/bin/bash
set -e
echo "Starting Orpheus TTS..."

apt-get update -qq && apt-get install -y -qq libportaudio2 psmisc > /dev/null 2>&1
echo "✓ Dependencies"

pip install -q -r /workspace/Orpheus-FastAPI/requirements.txt 2>/dev/null
echo "✓ Python packages"

mkdir -p /models
cp -r /workspace/models/* /models/ 2>/dev/null || true
echo "✓ Model"

fuser -k 8888/tcp 2>/dev/null || true
sleep 2
echo "✓ Port 8888 free"

export LD_LIBRARY_PATH=/workspace/llama-build/bin:$LD_LIBRARY_PATH

/workspace/llama-build/bin/llama-server \
    -m /models/orpheus-3b-0.1-ft-q4_k_m.gguf \
    -c 8192 -ngl 99 --host 0.0.0.0 --port 1234 &

echo "Waiting for llama server..."
for i in {1..30}; do
    curl -s http://127.0.0.1:1234/health > /dev/null 2>&1 && echo "✓ llama server ready" && break
    sleep 1
done

cd /workspace/Orpheus-FastAPI
sed -i 's/ORPHEUS_PORT=5005/ORPHEUS_PORT=8888/g' .env
export PYTHONIOENCODING=utf-8
python app.py
```

---

## Step 4: Install VRM Extension

In SillyTavern on your PC:
1. Open Extensions panel (puzzle piece icon)
2. Click "Download Extensions & Assets"
3. Find "VRM" and download it
4. Optionally download the VRM Animation Assets Pack (112 animations)

---

## Step 5: iOS Safari AudioContext Fix (Lip Sync)

iOS Safari suspends AudioContext on page load and requires a user gesture to resume. The VRM extension creates a new AudioContext on every TTS playback, which breaks lip sync on mobile.

### The fix:

Edit `Extension-VRM/vrm.js`. Two changes:

**Change 1 — After line 62** (`let tts_lips_sync_job_id = 0;`), add a global AudioContext singleton:

```javascript
// Global AudioContext for lip sync (iOS Safari requires user gesture to resume)
let _lipsyncAudioContext = null;
function getLipsyncAudioContext() {
    if (!_lipsyncAudioContext) {
        _lipsyncAudioContext = new (window.AudioContext || window.webkitAudioContext)();
    }
    if (_lipsyncAudioContext.state === 'suspended') {
        _lipsyncAudioContext.resume();
    }
    return _lipsyncAudioContext;
}
// Resume audio context on first user interaction (required for iOS Safari)
['click', 'touchstart'].forEach(event => {
    document.addEventListener(event, () => {
        if (_lipsyncAudioContext && _lipsyncAudioContext.state === 'suspended') {
            _lipsyncAudioContext.resume();
            console.debug(DEBUG_PREFIX, 'AudioContext resumed via user gesture');
        }
    }, { once: false });
});
```

**Change 2 — In the `audioTalk` function** (around line 883), replace:

```javascript
const audioContext = new(window.AudioContext || window.webkitAudioContext)();
```

With:

```javascript
const audioContext = getLipsyncAudioContext();
```

This creates a single persistent AudioContext that gets resumed on the first screen tap. All subsequent TTS playback reuses the same context.

---

## Step 6: Custom CSS (Immersive Mobile UI)

The goal: fullscreen VRM avatar with a transparent input bar at the bottom. No visible chat messages.

Go to User Settings → Custom CSS and paste:

```css
#chat {
    height: 0 !important;
    min-height: 0 !important;
    padding: 0 !important;
    margin: 0 !important;
    border: none !important;
    flex: 0 !important;
}

#chat .mes {
    height: 0 !important;
    overflow: hidden !important;
    margin: 0 !important;
    padding: 0 !important;
    border: none !important;
}

#sheld {
    display: flex !important;
    flex-direction: column !important;
    justify-content: flex-end !important;
    background: transparent !important;
    border: none !important;
}

#send_form {
    background: rgba(255, 255, 255, 0.1) !important;
    border: 1px solid rgba(255, 255, 255, 0.2) !important;
    border-radius: 20px !important;
    backdrop-filter: blur(5px) !important;
    padding: 5px 10px !important;
    display: flex !important;
    align-items: center !important;
}

#send_textarea {
    background: transparent !important;
    color: white !important;
    border: none !important;
}

#send_but,
#send_but .fa-paper-plane,
#rightSendForm {
    display: flex !important;
    visibility: visible !important;
    opacity: 1 !important;
}
```

---

## Step 7: Extension Settings

### TTS Settings
| Setting | Value |
|---------|-------|
| Provider | OpenAI Compatible |
| Enabled | ✓ |
| Auto Generation | ✓ |
| Narrate by paragraphs (streaming) | ✓ |
| Narrate by paragraphs (not streaming) | ✓ |
| Only narrate "quotes" | ✓ |
| Ignore text inside asterisks | ✓ |
| Audio Playback Speed | 1.00 |
| Default Voice | disabled |
| Indigo Voice | tara |
| Provider Endpoint | `https://[POD-ID]-8888.proxy.runpod.net/v1/audio/speech` |
| Model | orpheus |
| Available Voices | tara,leah,jess,mia,zoe,leo,dan,zac |
| Speed | 1 |

### VRM Settings
| Setting | Value |
|---------|-------|
| Enabled | ✓ |
| Look at camera | ✓ |
| Blink | ✓ |
| TTS lips sync | ✓ |
| Auto-send interaction | ✗ |
| Lock models position/rotation/scale | ✗ |
| Use model cache | ✓ |
| Use animation cache | ✓ |
| Body hitboxes | ✗ |
| Show grid | ✗ |
| Light intensity | 100% |

### VRM Model Settings
| Setting | Value |
|---------|-------|
| Model | indigo2 |
| Model scale | 3.4x |
| Model center X offset | 0.06 |
| Model center Y offset | 0.36 |
| Model X rotation | 0.1 |

### Model Animations
| Expression | Animation |
|------------|-----------|
| Default | neutral |
| admiration | relaxed |
| amusement | relaxed |
| anger | angry |

### Prome (Visual Novel Extension) Settings
| Setting | Value |
|---------|-------|
| Enable Prome | ✓ |
| Hide Sheld (Message Box) | ✗ (unchecked — CSS handles this) |
| Enable Traditional VN Mode | ✓ |

---

## Step 8: Connect from iPhone

1. Make sure SillyTavern is running on your PC
2. Make sure Tailscale is connected on both devices
3. Open Safari on your iPhone
4. Go to: `http://[YOUR-PC-TAILSCALE-IP]:8000`
5. **Tap anywhere on the screen once** (resumes AudioContext for lip sync)
6. Send a message or tap the mic icon

### Add to Home Screen (PWA):
1. Tap the Share button in Safari (square with arrow)
2. Tap "Add to Home Screen"
3. Name it "Indigo" (or your character's name)
4. Tap Add

This gives you a fullscreen app experience with no browser chrome.

---

## Speech Input on Mobile

iOS Safari does not support the Web Speech API for speech recognition. Use iOS built-in dictation:

1. Tap the text input field
2. Tap the **microphone icon on the iOS keyboard** (bottom right, near space bar)
3. Speak your message
4. iOS transcribes it into the text field
5. Tap the send button

This uses Apple's on-device speech recognition — fast, accurate, and private.

---

## Troubleshooting

### No lip sync on mobile
- Make sure you applied the vrm.js AudioContext fix
- Tap the screen at least once after loading the page
- Restart SillyTavern after editing vrm.js

### "Not connected to API!"
- Tap the plug icon → make sure Venice AI endpoint and key are configured
- Tap Connect

### TTS not playing
- Check that your RunPod pod is running
- Verify the Provider Endpoint URL matches your current pod's proxy URL
- The pod ID changes if you create a new pod (stays the same on restart)

### Input bar not visible on mobile
- Make sure "Hide Sheld" is **unchecked** in Prome settings
- Verify Custom CSS is pasted in User Settings
- The CSS hides chat messages but keeps the input bar visible

### Avatar not showing
- Check VRM extension is enabled
- Verify model "indigo2" is selected
- Try "Click to reload all VRM models" in Debug Settings

### Long response times
- Add to Post-History Instructions: "Respond in 1-3 short sentences. Be casual and brief. Never write more than 50 words."
- Shorter responses = faster TTS generation = lower RunPod cost

---

## Cost

| Component | Cost |
|-----------|------|
| Tailscale | Free (personal use) |
| Venice AI | Per-token (or subscription) |
| RunPod (RTX 4090) | ~$0.69/hr while running |
| SillyTavern | Free |
| VRM Extension | Free |

**Stop your RunPod pod when not in use.** A typical conversation session costs well under a dollar.

---

## What We Built

A fully private AI companion accessible from your phone with:
- 3D VRM avatar with lip sync and eye tracking
- Custom neural voice via Orpheus TTS
- Long-term memory via vector storage and World Info
- Encrypted remote access from anywhere via Tailscale
- No content filters, no logging, no data leaving your control

All from open-source tools, composed into a system that didn't exist before.
