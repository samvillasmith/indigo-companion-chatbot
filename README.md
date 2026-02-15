# Indigo Companion Chatbot

**Build your own AI companion with voice, memory, and a 3D avatar.**

Indigo Companion Chatbot is an open-source stack for creating multi-modal AI companions. Combine text generation, expressive text-to-speech, speech-to-text, long-term memory, and a lip-synced 3D avatar into a private, conversational experience. You talk, they listen. They respond, you hear their voice, and their avatar speaks the words.

Everything runs privately — text generation through Venice AI (no logging, no content filters), voice synthesis on a rented GPU, and the avatar, memory, and chat interface all on your local machine.

Create any character you want. Give them a personality, a backstory, a voice, and a face.

---

## Demo

```
You: "hey, what are you up to?"
Her: "just modding my keyboard again, i swapped to tangerine switches
      and they feel amazing." *holds it up proudly*

[Audio plays through your headphones in her voice]
[3D avatar lip-syncs to the audio on your desktop]
```

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  YOUR PC                                                        │
│                                                                 │
│  ┌──────────────┐    ┌──────────────────────────────────────┐   │
│  │ VMagicMirror  │    │  SillyTavern (localhost:8000)        │   │
│  │              │    │                                      │   │
│  │  3D Avatar   │◄───│  Chat UI + Extensions                │   │
│  │  Lip Sync    │    │  ├─ Vector Storage (local embeddings)│   │
│  │  Expressions │    │  ├─ World Info / Lore Book           │   │
│  │              │    │  ├─ TTS (OpenAI-compatible)          │   │
│  └──────┬───────┘    │  └─ STT (Browser Speech API)        │   │
│         │            └──────────┬───────────────┬───────────┘   │
│         │                       │               │               │
│    Stereo Mix /            Venice AI API    Orpheus TTS API     │
│    VB-Cable                (text gen)       (voice gen)         │
│   (audio mirror)                │               │               │
└─────────────────────────────────┼───────────────┼───────────────┘
                                  │               │
                          ┌───────▼───────┐ ┌─────▼──────────────┐
                          │  Venice AI    │ │  RunPod (RTX 4090) │
                          │  Cloud API    │ │                    │
                          │  No logging   │ │  llama.cpp :1234   │
                          │  Uncensored   │ │  Orpheus-FastAPI   │
                          └───────────────┘ │  :8888             │
                                            └────────────────────┘
```

### Component Roles

| Component           | Role                        | Runs On        | Cost            |
|---------------------|-----------------------------|----------------|-----------------|
| SillyTavern         | Chat UI + orchestration     | Your PC        | Free            |
| Venice AI           | Text generation (LLM)       | Cloud API      | Free tier / Paid|
| Orpheus TTS         | Voice synthesis             | RunPod GPU     | ~$0.60/hr       |
| VMagicMirror        | 3D avatar + lip sync        | Your PC        | Free            |
| VRoid Studio        | Avatar creation             | Your PC        | Free            |
| Vector Storage      | Conversation memory (RAG)   | Your PC        | Free            |
| World Info          | Character lore/backstory    | Your PC        | Free            |
| Browser STT         | Speech-to-text input        | Your PC        | Free            |

---

## Features

- **Voice conversations** — speak through your mic, hear them respond through headphones
- **Expressive TTS** — Orpheus 3B generates natural, emotional speech (not robotic)
- **Long-term memory** — vector storage remembers past conversations via semantic search
- **Character lore** — World Info injects backstory when relevant keywords appear
- **3D avatar** — VRM model with idle animations, mouse tracking, and lip sync
- **Any character** — design your own personality, appearance, voice, and backstory
- **At your discretion** — no content filters, no logging, fully private
- **Privacy-first** — runs on your hardware, character data stays on your machine
- **Modular** — swap any component (local LLM, different TTS, etc.)

---

## Prerequisites

### On Your PC
- Windows 10/11
- Node.js (LTS) — [nodejs.org](https://nodejs.org)
- Git — [git-scm.com](https://git-scm.com)
- Chrome (recommended for STT)
- ~2 GB disk space

### Cloud
- Venice AI account + API key — [venice.ai](https://venice.ai)
- RunPod account — [runpod.io](https://runpod.io) (~$0.60/hr for RTX 4090)

---

## Quick Start

If you've already done the full setup and just want to start a session:

```
1. Start RunPod pod → bash /workspace/runpod-orpheus-startup.sh
2. Open VMagicMirror
3. Run C:\AI\SillyTavern\start.bat
4. Update TTS endpoint URL if pod ID changed
5. Chat
6. Stop RunPod pod when done
```

---

## Full Setup Guide

### Phase 1: Chat (SillyTavern + Venice AI)

<details>
<summary><strong>1.1 Install SillyTavern</strong></summary>

```powershell
mkdir C:\AI
cd C:\AI
git clone https://github.com/SillyTavern/SillyTavern.git
cd SillyTavern
.\start.bat
```

Opens at `http://localhost:8000`.
</details>

<details>
<summary><strong>1.2 Connect Venice AI</strong></summary>

Click the **plug icon** (API Connection):

| Setting                | Value                              |
|------------------------|------------------------------------|
| API                    | Chat Completion                    |
| Chat Completion Source | Custom (OpenAI-compatible)         |
| Custom Endpoint        | `https://api.venice.ai/api/v1`     |
| Custom API Key         | Your Venice AI API key             |

Click **Connect**. Green dot = connected.
</details>

<details>
<summary><strong>1.3 Create Your Character</strong></summary>

Click the **character icon** → Create New Character.

A character card defines who your companion is. Fill in these fields:

**Description** — Who they are. Include personality traits, appearance, speech patterns, quirks, and how they relate to `{{user}}`. Write in third person. This is the most important field. Example structure:

```
[Name] is a [occupation] with [physical description].

[Name] is [personality traits]. They [behavioral patterns].

[Name] talks [speech style]. They [verbal habits and quirks].
```

**First Message** — The opening scene. Use `*asterisks*` for actions and `"quotes"` for dialogue. Use `{{user}}` as a placeholder for your name. This sets the tone for everything.

**Scenario** — The context. Where are you? What's your relationship? 1-2 sentences.

**Examples of Dialogue** — These control response length and style more than any other setting. The model mirrors whatever format you write here. Format:

```
<START>
{{user}}: [message]
{{char}}: [response in the style and length you want]
```

Include 3-5 examples. Each `<START>` marks a separate conversation.

> **Tip:** Short example dialogues are the single most effective way to control response length. If your examples are 1-2 sentences, the model writes 1-2 sentences.

**Character's Note** — Behavioral instructions injected close to the generation. Set **Depth: 4**, **Role: System**:

```
[Character keeps responses to 1-3 sentences. They are casual and brief.]
```
</details>

<details>
<summary><strong>1.4 Prompt & Sampler Settings</strong></summary>

Click the **sliders icon**.

**System Prompt** (top of prompts list):
```
Write short, punchy responses. 1-3 sentences max. Brief actions, casual dialogue. Never monologue.
```

Adjust to match the style you want. Remove brevity instructions for longer responses.

**Post-History Instructions** (click pencil icon):
```
[Write concise responses. 1-3 sentences of dialogue with minimal narration.]
```

**Sampler Settings:**

| Setting              | Value  | Notes                                        |
|----------------------|--------|----------------------------------------------|
| Max Response Length  | 300    | Increase to 500+ for longer responses        |
| Temperature          | 0.8    | Higher = more creative, lower = more focused |
| Stream               | ☑️ On  | Lets TTS start before full response finishes |
</details>

---

### Phase 2: Memory (Vector Storage + World Info)

<details>
<summary><strong>2.1 Vector Storage (Conversation Memory)</strong></summary>

Click the **puzzle piece icon** → find **Vector Storage**.

This gives your character memory of past conversations. Mention something from 50 messages ago, it gets retrieved and injected into the prompt automatically.

**Core Settings:**

| Setting                | Value                |
|------------------------|----------------------|
| Vectorization Source   | Local (Transformers) |
| Query messages         | 4                    |
| Score threshold        | 0.25                 |

**Enable all checkboxes:**
- ☑️ Include in World Info Scanning
- ☑️ Enable for World Info
- ☑️ Enable for files
- ☑️ Enabled for chat messages

**Chat Vectorization:**

| Setting              | Value                    |
|----------------------|--------------------------|
| Injection Template   | `Past events: {{text}}`  |
| Injection Position   | In-chat @ Depth          |
| Depth                | 4                        |
| as                   | System                   |
| Chunk size           | 400                      |
| Retain#              | 5                        |
| Insert#              | 3                        |

**World Info & File Settings:**

| Setting              | Value                              |
|----------------------|------------------------------------|
| Max Entries          | 5                                  |
| Injection Position   | Before Main Prompt / Story String  |

**Summarization:** Leave both unchecked.

**How it works:** The embedding model runs locally in your browser via Transformers.js. Vectors are stored as files in `SillyTavern/data/default-user/vectors/`. No cloud, no database — just files on disk. Use **"Vectorize All"** to re-index existing conversations.
</details>

<details>
<summary><strong>2.2 World Info / Lore Book (Permanent Knowledge)</strong></summary>

Click the **globe icon** → Create a new World Info book → **Activate** it.

World Info stores facts your character should always know. Unlike Vector Storage (which recalls what you talked about), World Info is a keyword lookup table — type a trigger word, matching lore gets injected.

Each entry has:
- **Keys** — trigger words that activate this entry
- **Content** — the lore text that gets injected

**Example entries:**

| Entry         | Keys                                          | Content                                                |
|---------------|-----------------------------------------------|--------------------------------------------------------|
| Family        | `family, parents, mom, dad, sister`           | Their family background, relationships, history        |
| Work/School   | `job, work, school, project`                  | What they do, current projects, career goals           |
| Hobbies       | `favorite, hobbies, games, music`             | Interests, favorites, passions                         |
| Relationship  | `relationship, dating, love, us`              | How they relate to {{user}}, attachment style          |
| Secrets       | `secret, past, afraid, nightmare`             | Hidden depths, fears, things they don't talk about     |
| Friends       | `friend, friends, bestie, crew`               | Their social circle, important people in their life    |

**Tips:**
- Use multiple keywords per entry to catch different phrasings
- Keep each entry under ~200 tokens
- Each entry's status dot must be **green** (enabled)
- The book must be **activated**, not just created

**Vector Storage vs World Info:**
- **Vector Storage** = episodic memory (what you talked about)
- **World Info** = permanent knowledge (facts they always know)
</details>

---

### Phase 3: Voice (Orpheus TTS on RunPod)

<details>
<summary><strong>3.1 Deploy Orpheus on RunPod</strong></summary>

**Create a pod:**

| Setting            | Value           |
|--------------------|-----------------|
| GPU                | RTX 4090        |
| Template           | PyTorch         |
| Container Disk     | 30 GB           |
| Volume Disk        | 20 GB           |
| Expose HTTP Ports  | 8888            |

**First-time setup:**
Upload `runpod-orpheus-setup.sh` to the pod and run:
```bash
bash runpod-orpheus-setup.sh
```
Takes ~15 minutes. Downloads model, builds llama.cpp, installs Orpheus-FastAPI.

**After restarts:**
```bash
bash /workspace/runpod-orpheus-startup.sh
```
Takes ~30 seconds.

**Cost:** ~$0.60/hr running, ~$0.10/day stopped. Always stop the pod when done.
</details>

<details>
<summary><strong>3.2 Configure TTS in SillyTavern</strong></summary>

Click the **speaker icon**.

| Setting                                    | Value                                                        |
|--------------------------------------------|--------------------------------------------------------------|
| Select TTS Provider                        | OpenAI Compatible                                            |
| ☑️ Enabled                                  | Checked                                                      |
| ☐ Narrate user messages                    | Unchecked                                                    |
| ☑️ Auto Generation                          | Checked                                                      |
| ☑️ Narrate by paragraphs (when streaming)   | Checked                                                      |
| ☑️ Only narrate "quotes"                    | Checked                                                      |
| ☑️ Ignore \*text\* inside asterisks         | Checked                                                      |
| Audio Playback Speed                       | 1.00                                                         |
| Provider Endpoint                          | `https://YOUR-POD-ID-8888.proxy.runpod.net/v1/audio/speech`  |
| API Key                                    | `none`                                                       |
| Model                                      | `orpheus`                                                    |
| Available Voices                           | `tara,leah,jess,mia,zoe,leo,dan,zac`                        |

**Available Orpheus voices:**

| Voice | Gender | Notes              |
|-------|--------|--------------------|
| tara  | Female | Warm, natural      |
| leah  | Female | Soft               |
| jess  | Female | Bright             |
| mia   | Female | Gentle             |
| zoe   | Female | Energetic          |
| leo   | Male   | Calm               |
| dan   | Male   | Casual             |
| zac   | Male   | Deep               |

Assign a voice to your character in the voice dropdown.

Find your pod's proxy URL: RunPod dashboard → click pod → HTTP Services → Port 8888.
</details>

<details>
<summary><strong>3.3 Speech-to-Text (Voice Input)</strong></summary>

Full voice conversations — speak instead of type.

1. Click the **puzzle piece icon** (Extensions)
2. Install **Speech Recognition** extension
3. Refresh browser

**Settings:**

| Setting          | Value                    |
|------------------|--------------------------|
| STT Provider     | Browser                  |
| Input Device     | Your headset microphone  |
| ☑️ Enabled        | Checked                  |

A **microphone icon** appears in the chat bar. Click it to speak. Best in Chrome.

**Full voice conversation loop:**

1. Click mic → speak
2. Browser transcribes your voice to text
3. Venice AI generates the response
4. Orpheus TTS converts to audio → plays in your headphones
5. VMagicMirror lip syncs → avatar's mouth moves
</details>

---

### Phase 4: Avatar (VRoid Studio + VMagicMirror)

<details>
<summary><strong>4.1 Create Your Avatar</strong></summary>

1. Download **VRoid Studio** from [vroid.com/en/studio](https://vroid.com/en/studio) (free)
2. Create your character — customize hair, eyes, face, body, outfit
3. **Save** as `.vroid` (editable project file)
4. **Export** as `.vrm` to `C:\AI\Avatar\YourCharacter.vrm`

Exporting does NOT upload anything online. The file stays on your machine.

Optional: Buy custom textures from [Booth](https://booth.pm/) for higher quality skins and outfits.

> **Note:** VRoid Studio only has adult body types.
</details>

<details>
<summary><strong>4.2 Install VMagicMirror</strong></summary>

1. Download from [github.com/malaybaku/VMagicMirror/releases](https://github.com/malaybaku/VMagicMirror/releases)
2. Extract to `C:\AI\VMagicMirror\`
3. Run `VMagicMirror.exe`
4. Click **Load VRM** → select your `.vrm` file

**Configure:**

| Setting                      | Value           |
|------------------------------|-----------------|
| Background                   | Transparent     |
| Load VRM on startup          | ☑️ Enabled       |
| Mouse/keyboard tracking      | ☑️ On            |
| Breathing                    | ☑️ On            |
| Blinking                     | ☑️ On            |

Position the window next to SillyTavern.
</details>

<details>
<summary><strong>4.3 Lip Sync</strong></summary>

VMagicMirror only accepts recording devices for lip sync. Route your system audio into a virtual recording device.

**Option A — Stereo Mix (simplest):**

1. `Win + R` → `mmsys.cpl` → Recording tab
2. Right-click → Show Disabled Devices → Enable **Stereo Mix**
3. Play audio → verify green bars move
4. VMagicMirror → Lip Sync → select **Stereo Mix**
5. Crank sensitivity up if needed (+20 dB)

**Option B — VB-Audio Virtual Cable:**

1. Install from [vb-audio.com/Cable](https://vb-audio.com/Cable/) (free) → restart
2. Keep headphones as default output
3. Stereo Mix → Listen tab → ☑️ Listen to this device → set to CABLE Input
4. VMagicMirror → Lip Sync → select **CABLE Output**

**Option C — VoiceMeeter Banana:**

1. Install from [vb-audio.com/Voicemeeter](https://vb-audio.com/Voicemeeter) (free) → restart
2. Route audio to headphones + virtual output
3. VMagicMirror → Lip Sync → VoiceMeeter Output

> **Important:** Lip Sync must be set to an audio loopback device, NOT your microphone.
</details>

---

## Swapping Components

The stack is modular. Swap any piece:

| Layer            | Default           | Alternatives                                              |
|------------------|-------------------|-----------------------------------------------------------|
| Text Generation  | Venice AI         | KoboldCpp, Ollama (local), OpenRouter, any OpenAI-compat API |
| TTS              | Orpheus on RunPod | Kokoro (local, free), ElevenLabs, OpenAI TTS              |
| STT              | Browser API       | Whisper (local), Vosk                                     |
| Avatar           | VMagicMirror      | VTube Studio                                              |
| Avatar Creation  | VRoid Studio      | Any tool that exports `.vrm`                              |
| Chat UI          | SillyTavern       | —                                                         |

**Fully local (no cloud costs):** Use KoboldCpp or Ollama for text generation + Kokoro for TTS. Requires 8GB+ VRAM for 7-8B models.

---

## File Structure

```
C:\AI\
├── SillyTavern\                # Chat UI + extensions
│   ├── start.bat
│   └── data\default-user\
│       ├── characters\          # Character cards (JSON)
│       ├── worlds\              # World Info lore books
│       └── vectors\             # Conversation memory
│
├── Avatar\
│   ├── YourCharacter.vrm        # Exported 3D model
│   └── YourCharacter.vroid      # Editable project file
│
└── VMagicMirror\
    └── VMagicMirror.exe

RunPod (/workspace):
├── llama.cpp\build\bin\llama-server
├── models\orpheus-3b-0.1-ft-q4_k_m.gguf
├── Orpheus-FastAPI\app.py
└── runpod-orpheus-startup.sh
```

---

## Conversation Flow

```
                    ┌─── STT ───┐
                    │ You speak  │
                    └─────┬──────┘
                          │ text
                          ▼
              ┌───────────────────────┐
              │     SillyTavern       │
              │                       │
              │  1. Your message      │
              │  2. + Vector recall   │──── semantic search of past chats
              │  3. + World Info      │──── keyword match → lore injection
              │  4. + System prompt   │
              │  5. + Character card  │
              │  6. → Full prompt     │
              └───────────┬───────────┘
                          │
                          ▼
              ┌───────────────────────┐
              │      Venice AI        │
              │   (text generation)   │
              └───────────┬───────────┘
                          │ response text
                          ▼
              ┌───────────────────────┐
              │   Orpheus TTS         │
              │   (RunPod GPU)        │
              └───────────┬───────────┘
                          │ audio
                    ┌─────┴──────┐
                    ▼            ▼
              Headphones    VMagicMirror
              (you hear)    (lips move)
```

---

## Cost

| Component        | Cost                                         |
|------------------|----------------------------------------------|
| SillyTavern      | Free                                         |
| Venice AI        | Free tier available, paid for higher limits   |
| RunPod (Orpheus) | ~$0.60/hr running, ~$0.10/day storage        |
| VRoid Studio     | Free                                         |
| VMagicMirror     | Free                                         |
| VB-Cable         | Free                                         |

**Per session:** ~$0.60–$1.20 (1–2 hours). Or $0 if running fully local.

---

## Troubleshooting

<details>
<summary><strong>No audio</strong></summary>

- Unmute the SillyTavern browser tab
- Check Windows Volume Mixer
- Verify RunPod pod is running and TTS endpoint URL is correct
</details>

<details>
<summary><strong>TTS connection error (127.0.0.1:1234)</strong></summary>

llama.cpp crashed on the pod. Restart:
```bash
cd /workspace/llama.cpp && ./build/bin/llama-server \
  -m /models/orpheus-3b-0.1-ft-q4_k_m.gguf \
  -c 8192 -ngl 99 --host 0.0.0.0 --port 1234 &
```
</details>

<details>
<summary><strong>Port 8888 won't bind</strong></summary>

Jupyter holds it: `fuser -k 8888/tcp`
</details>

<details>
<summary><strong>Slow audio / long wait</strong></summary>

- Enable "Narrate by paragraphs (when streaming)"
- Enable Streaming in sampler settings
- Shorten responses via Character's Note + example dialogue
</details>

<details>
<summary><strong>Responses too long</strong></summary>

- Brevity instructions in Character's Note (Depth 4, System)
- Short example dialogues (1-2 sentences each)
- Start a new chat (old long messages train the model to be verbose)
</details>

<details>
<summary><strong>Lip sync wrong direction</strong></summary>

Lip Sync input must be Stereo Mix or VB-Cable — NOT your microphone. If set to mic, the avatar moves when *you* talk instead of when *they* talk.
</details>

<details>
<summary><strong>Vector Storage not working</strong></summary>

- All checkboxes enabled
- Click "Vectorize All" to re-index
- Source = Local (Transformers)
</details>

<details>
<summary><strong>World Info not triggering</strong></summary>

- Book must be **activated**
- Entry dots must be **green**
- Keywords must match what you type
</details>

<details>
<summary><strong>STT not working</strong></summary>

- Use Chrome
- Allow mic permissions
- Correct mic selected
</details>

<details>
<summary><strong>RunPod files gone after restart</strong></summary>

Only `/workspace` persists. Container disk is wiped on stop. Use the startup scripts.
</details>

---

## Credits

| Tool | Author |
|------|--------|
| [SillyTavern](https://github.com/SillyTavern/SillyTavern) | SillyTavern Community |
| [Orpheus TTS](https://github.com/canopyai/Orpheus-TTS) | Canopy AI |
| [Orpheus-FastAPI](https://github.com/Lex-au/Orpheus-FastAPI) | Lex-au |
| [llama.cpp](https://github.com/ggerganov/llama.cpp) | Georgi Gerganov |
| [VMagicMirror](https://github.com/malaybaku/VMagicMirror) | malaybaku |
| [VRoid Studio](https://vroid.com/en/studio) | pixiv |
| [Venice AI](https://venice.ai) | Venice AI |
| [VB-Audio Virtual Cable](https://vb-audio.com/Cable/) | VB-Audio |

---

## License

This is a configuration guide, not a software distribution. Each component has its own license. See individual project pages for terms.

---

*Half in light and half in dark is where we are.*
