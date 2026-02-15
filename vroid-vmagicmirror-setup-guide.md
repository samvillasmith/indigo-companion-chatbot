# VRoid Studio + VMagicMirror Setup Guide

Give Indigo a 3D avatar body with lip sync tied to her Orpheus TTS voice.

---

## Architecture Overview

```
SillyTavern (text response)
  └→ Orpheus TTS (generates voice audio)
       └→ Your Headphones (you hear her)
       └→ Stereo Mix / VB-Cable (mirror of audio)
            └→ VMagicMirror (lip syncs to audio)
                 └→ Indigo's 3D model moves her mouth
```

VMagicMirror doesn't connect to SillyTavern directly. It listens to your system audio and syncs the avatar's lips to whatever sound is playing.

---

## Part 1: Create Indigo's 3D Model (VRoid Studio)

### Install

1. Download **VRoid Studio** from [vroid.com/en/studio](https://vroid.com/en/studio) (free, Windows)
2. Install and launch it

### Design Indigo

Create a new character and customize to match her description:

| Feature     | Setting                                        |
|-------------|------------------------------------------------|
| Hair        | Indigo-blue, messy/long                        |
| Eyes        | Hazel, round glasses                           |
| Body        | Curvy                                          |
| Outfit      | Crop top, oversized cardigan off one shoulder  |
| Extras      | Thigh-highs                                    |

VRoid has tons of sliders for face, body, hair, and clothes. You can also buy custom textures from [Booth](https://booth.pm/) for higher quality skins and outfits.

### Export

1. Click the **Export** icon (top right — share/upload arrow)
2. Select **"Export as VRM"**
3. Fill in metadata (name: Indigo, author: your name)
4. Save to `C:\AI\Avatar\Indigo.vrm`

> **Important:** Also **Save** the `.vroid` project file — that's your editable source. The `.vrm` is the final export for VMagicMirror. Exporting does NOT upload anything online.

---

## Part 2: Install & Configure VMagicMirror

### Install

1. Download from [github.com/malaybaku/VMagicMirror/releases](https://github.com/malaybaku/VMagicMirror/releases)
2. Extract to `C:\AI\VMagicMirror\`
3. Run `VMagicMirror.exe`
4. Click **Load VRM** → browse to `C:\AI\Avatar\Indigo.vrm`
5. Indigo appears on screen

### Configure Display

| Setting                          | Value / Action                                  |
|----------------------------------|------------------------------------------------|
| Background                       | Set to **transparent** (Window settings)       |
| Load VRM on startup              | ☑️ Enabled                                      |
| Mouse/keyboard tracking          | ☑️ On (she follows your cursor)                 |
| Idle animations                  | ☑️ Breathing, blinking, slight swaying          |

Position and resize the VMagicMirror window so Indigo sits next to your SillyTavern browser window.

---

## Part 3: Lip Sync Setup

VMagicMirror only accepts **microphone/recording devices** as lip sync input — it can't directly listen to your audio output. You need to route a copy of your system audio into a virtual recording device.

### Option A: Stereo Mix (try this first)

1. Press **Win + R** → type `mmsys.cpl` → Enter
2. Go to the **Recording** tab
3. Right-click empty space → check **"Show Disabled Devices"**
4. Find **Stereo Mix** → right-click → **Enable**
5. Test: play any audio and check if green bars move next to Stereo Mix
6. In VMagicMirror → **Lip Sync** → set input device to **Stereo Mix**
7. Adjust **Sensitivity** (try +20 dB if lips aren't moving enough)

> **If Stereo Mix doesn't appear or green bars don't move**, use Option B instead.

### Option B: VB-Audio Virtual Cable

1. Download from [vb-audio.com/Cable](https://vb-audio.com/Cable/) (free)
2. Install and **restart your PC**
3. After restart, a new device called **"CABLE Input"** appears in recording devices

**Audio routing with VB-Cable:**

1. Keep your **headphones as default output** (so you hear Indigo)
2. In **Windows Sound Settings** → Recording tab → enable **Stereo Mix**
3. Stereo Mix Properties → **Listen** tab → ☑️ "Listen to this device" → set to **CABLE Input**
4. In **VMagicMirror** → Lip Sync → select **CABLE Output** (the virtual cable's recording side)

This routes: Audio → Headphones (you hear it) → Stereo Mix mirrors it → CABLE Input → VMagicMirror reads CABLE Output for lip sync.

### Option C: VoiceMeeter Banana (most reliable)

If both above fail:

1. Download from [vb-audio.com/Voicemeeter](https://vb-audio.com/Voicemeeter) (free)
2. Install and restart
3. Set VoiceMeeter as your default audio device
4. Route output to both your headphones AND a virtual output
5. In VMagicMirror → Lip Sync → select **VoiceMeeter Output**

---

## Part 4: Expressions (Optional)

VMagicMirror supports VRM blend shapes for facial expressions:

| Expression    | Use                          |
|---------------|------------------------------|
| Happy         | Smiling                      |
| Angry         | Pouting                      |
| Surprised     | Wide eyes                    |
| Embarrassed   | Blushing                     |

These can be triggered with hotkeys in VMagicMirror. You can also connect them to SillyTavern's **Character Expressions** extension to change automatically based on chat mood (advanced setup).

---

## Part 5: Speech-to-Text (Talk to Indigo)

SillyTavern has a built-in speech recognition feature so you can speak instead of type.

### Setup

1. In SillyTavern, click the **Extensions** icon (puzzle piece)
2. Look for **Speech Recognition** (may need to scroll or install from the extensions list)
3. Set STT Provider to **Browser** (uses your browser's built-in speech recognition)
4. Set input device to your headset microphone
5. Enable it

A **microphone icon** appears in the chat bar. Click it, speak, and your words get transcribed and sent.

### Full Conversation Loop

1. You click the mic button and speak
2. Browser STT transcribes your voice to text
3. Text goes to Venice AI → Indigo's response generated
4. Orpheus TTS converts response to audio → plays in your headphones
5. VMagicMirror lip syncs to the audio → Indigo's mouth moves

---

## Startup Checklist

Every time you want to chat with Indigo:

1. ☐ Start **RunPod** pod → run `bash /workspace/runpod-orpheus-startup.sh`
2. ☐ Open **VMagicMirror** (Indigo auto-loads if configured)
3. ☐ Open **SillyTavern** in your browser
4. ☐ Verify TTS endpoint URL matches your current RunPod pod proxy URL
5. ☐ Send Indigo a message → hear her voice → see her lips move
6. ☐ **When done:** Stop the RunPod pod to save money

---

## Troubleshooting

### Lips moving but no sound
- Right-click the SillyTavern browser tab → make sure it's not muted
- Check Windows Volume Mixer → make sure the browser isn't muted
- Verify headphones are set as default output device

### Sound playing but lips not moving
- Check VMagicMirror Lip Sync input device (should be Stereo Mix or VB-Cable, NOT your microphone)
- Increase Lip Sync sensitivity in VMagicMirror
- Test: play any audio (YouTube) — if lips don't move, the audio routing is wrong

### Lip Sync dropdown only shows microphones
- This is normal — VMagicMirror only lists recording devices
- You need Stereo Mix, VB-Cable, or VoiceMeeter to route audio output into a recording device
- See Part 3 above

### VMagicMirror background isn't transparent
- Open Settings → Window → set background to transparent
- On some systems, look under the Streaming tab instead

### Speech recognition not working
- Make sure your browser supports Web Speech API (Chrome works best)
- Check microphone permissions in your browser
- Verify the correct mic is selected in STT settings
