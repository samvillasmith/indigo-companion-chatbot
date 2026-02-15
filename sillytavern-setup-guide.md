# SillyTavern Complete Setup Guide

Everything needed to configure SillyTavern with Venice AI, Orpheus TTS, Vector Storage, World Info, and STT for the Indigo Companion Chatbot stack.

---

## 1. Install SillyTavern

### Prerequisites
- Node.js (LTS from nodejs.org)
- Git (from git-scm.com)

### Install
```powershell
mkdir C:\AI
cd C:\AI
git clone https://github.com/SillyTavern/SillyTavern.git
cd SillyTavern
.\start.bat
```

Opens in browser at `http://localhost:8000`

---

## 2. API Connection (Text Generation — Venice AI)

Click the **plug icon** (API Connection, top left).

| Setting                | Value                                    |
|------------------------|------------------------------------------|
| API                    | Chat Completion                          |
| Chat Completion Source | Custom (OpenAI-compatible)               |
| Custom Endpoint        | `https://api.venice.ai/api/v1`           |
| Custom API Key         | Your Venice AI API key                   |
| Model ID               | Select your preferred Venice model       |

Click **Connect**. Green dot = connected.

> **Using a different provider?** Any OpenAI-compatible API works here — OpenRouter, local KoboldCpp (`http://localhost:5001`), Ollama (`http://localhost:11434/v1`), etc. Just change the endpoint and key.

---

## 3. Create Your Character

Click the **character icon** → Create New Character.

### Description

The most important field. Defines personality, appearance, speech patterns, and behavior. Write in third person. Use `{{user}}` as a placeholder for the player's name and `{{char}}` for the character's name.

**Template:**
```
{{char}} is a [occupation/role] with [physical description —
hair, eyes, build, clothing style].

{{char}} is [personality traits — 3-5 core traits]. They [behavioral patterns —
how they act around {{user}}, habits, quirks].

{{char}} talks [speech style — formal/casual, verbal tics, slang, accent].
They [communication quirks — pet names, emojis, trailing off, etc.].
```

**Tips:**
- 300-500 tokens is the sweet spot. Too short and the character is flat, too long and it eats context.
- Be specific. "She's nice" is weak. "She nervously fidgets with her sleeves when she's lying" is strong.
- Include how they relate to `{{user}}` — are they flirty, guarded, clingy, distant?
- Include speech patterns — the model mirrors these closely.

### First Message

The opening scene when a new chat starts. Sets the tone for everything. Use `*asterisks*` for actions/narration and `"quotes"` for dialogue.

**Template:**
```
*[Scene description — where they are, what they're doing, atmosphere.
Use {{user}} to reference the player.]*

"[Opening dialogue — their first words to {{user}}.]"

*[A small action or detail that shows personality.]*
```

**Tips:**
- Show, don't tell. Don't describe personality — demonstrate it through action and dialogue.
- Keep it to 1-3 paragraphs. This gets sent with every new chat.
- End with something that invites a response.

### Scenario

The context. 1-2 sentences max.

**Template:**
```
{{user}} and {{char}} are [relationship]. [Setting and situation].
```

### Examples of Dialogue

**This is the #1 way to control response length and style.** The model mirrors whatever format appears here. If your examples are 1-2 sentences, responses will be 1-2 sentences. If they're 5 paragraphs, expect 5-paragraph responses.

**Format:**
```
<START>
{{user}}: [short message]
{{char}}: [response in the EXACT style and length you want]
<START>
{{user}}: [another message]
{{char}}: [another response]
```

Each `<START>` marks a separate conversation. Include 3-5 examples covering different moods — casual, emotional, funny, flirty, whatever fits your character.

**Tips:**
- Keep examples short if you want short responses. This matters more than any instruction.
- Include both dialogue and action in the style you want.
- Show the character's voice — their specific word choices, humor, quirks.

### Character's Note

Behavioral instructions injected close to the generation context. More effective than system prompts for character-specific rules.

- **Depth:** 4
- **Role:** System

**Template:**
```
[{{char}} keeps responses to 1-3 sentences. They are [tone]. They [content guidelines].]
```

**Examples:**
```
[{{char}} keeps responses to 1-3 sentences. They are casual and brief.]
```
```
[{{char}} writes 2-4 paragraphs. They are descriptive and poetic. They focus on internal emotions.]
```
```
[{{char}} is explicit and direct. They use graphic language when appropriate. No euphemisms.]
```

---

## 4. Prompt Settings

Click the **sliders icon** (top bar).

### System Prompt

Global instructions that apply to all characters. Add at the top of the prompts list:

```
Write short, punchy responses. 1-3 sentences max. Brief actions, casual dialogue. Never monologue.
```

Adjust to your preference:
- Remove brevity instructions for longer, more descriptive responses
- Add content guidelines here if they should apply to every character
- Keep it short — this gets sent with every message

### Post-History Instructions

Instructions injected after the chat history, right before generation. Find it in the prompts list → click pencil icon:

```
[Write concise responses. 1-3 sentences of dialogue with minimal narration.]
```

### Sampler Settings

| Setting              | Value  | Notes                                        |
|----------------------|--------|----------------------------------------------|
| Max Response Length  | 300    | 150 for terse, 500+ for descriptive          |
| Temperature          | 0.8    | 0.6 = focused, 1.0 = creative/chaotic       |
| Stream               | ☑️ On  | Required for paragraph-by-paragraph TTS      |

> **Streaming** is important — it lets TTS start narrating the first paragraph while the rest generates, cutting perceived wait time significantly.

---

## 5. Vector Storage (Conversation Memory)

Click the **puzzle piece icon** (Extensions) → find **Vector Storage**.

This gives your character long-term memory. They'll recall things from past conversations without you repeating them.

### Core Settings

| Setting                          | Value                              |
|----------------------------------|------------------------------------|
| Vectorization Source             | Local (Transformers)               |
| Embedding Model                 | all-MiniLM-L6-v2 (default)        |
| Query messages                  | 4                                  |
| Score threshold                 | 0.25                               |

### Enable all checkboxes:

- ☑️ Include in World Info Scanning
- ☑️ Enable for World Info
- ☑️ Enable for files
- ☑️ Enabled for chat messages

### Chat Vectorization Settings

| Setting              | Value                    |
|----------------------|--------------------------|
| Injection Template   | `Past events: {{text}}`  |
| Injection Position   | In-chat @ Depth          |
| Depth                | 4                        |
| as                   | System                   |
| Chunk size           | 400                      |
| Retain#              | 5                        |
| Insert#              | 3                        |

### World Info & File Settings

| Setting              | Value                              |
|----------------------|------------------------------------|
| Max Entries          | 5                                  |
| Injection Position   | Before Main Prompt / Story String  |

### Summarization

Leave both summarize checkboxes **unchecked** — it slows things down and eats context.

### How It Works

- Embedding model runs locally in your browser via Transformers.js
- Vectors stored as files in `SillyTavern/data/default-user/vectors/`
- Automatic — every message is indexed as you chat
- When you send a message, semantically similar past messages are retrieved and injected
- No cloud, no database, just files on disk

**Useful buttons:**
- **"Vectorize All"** — re-index all past messages at once
- **"View Stats"** — see how much is stored

---

## 6. World Info / Lore Book (Permanent Knowledge)

Click the **globe icon** (World Info) → Create a new book → **Activate** it.

World Info stores permanent facts your character knows. When you type a trigger keyword, the matching entry gets injected into the prompt automatically.

### How to Create Entries

Each entry needs:
- **Title/Memo** — label for your reference (not sent to the model)
- **Keys** — comma-separated trigger words
- **Content** — the lore text that gets injected when a key matches

### Recommended Entry Categories

| Category      | Example Keys                                        | What to Include                                         |
|---------------|-----------------------------------------------------|---------------------------------------------------------|
| Family        | `family, parents, mom, dad, sister, brother`        | Names, relationships, history, dynamics                  |
| Work/School   | `job, work, school, college, project, boss`         | Occupation, coworkers, current projects, goals           |
| Hobbies       | `favorite, hobbies, games, music, anime, movies`    | Interests, favorites, passions, skills                   |
| Relationship  | `relationship, dating, love, us, together`          | How they feel about {{user}}, attachment style, history  |
| Friends       | `friend, friends, bestie, crew, squad`              | Social circle, important people, group dynamics          |
| Secrets       | `secret, past, afraid, nightmare, regret`           | Hidden depths, fears, trauma, things they avoid          |
| Home          | `home, apartment, room, house, place`               | Where they live, what it looks like, roommates           |
| Appearance    | `wearing, outfit, look, dress, clothes`             | Wardrobe details, style preferences, signature looks     |

### Tips

- Use multiple keywords per entry to catch different phrasings
- Keep each entry under ~200 tokens so it doesn't eat too much context
- Make sure each entry's status dot is **green** (enabled)
- The book must be **activated** (click "No Worlds active. Click here to" and select your book)
- You can have multiple books — one per character, plus shared ones

### World Info vs Vector Storage

| Feature        | World Info                  | Vector Storage                  |
|----------------|-----------------------------|---------------------------------|
| What it stores | Facts you write             | Past conversation messages      |
| How it triggers| Keyword match               | Semantic similarity search      |
| Use for        | Permanent knowledge/lore    | Episodic memory of past chats   |
| Maintained by  | You (manual entries)        | Automatic (indexes as you chat) |

Both work together — World Info provides the backstory, Vector Storage provides the memory of what happened.

---

## 7. TTS Settings (Orpheus Voice on RunPod)

Click the **speaker icon** (TTS, top bar).

| Setting                                    | Value                                                          |
|--------------------------------------------|----------------------------------------------------------------|
| Select TTS Provider                        | OpenAI Compatible                                              |
| ☑️ Enabled                                  | Checked                                                        |
| ☐ Narrate user messages                    | Unchecked                                                      |
| ☑️ Auto Generation                          | Checked                                                        |
| ☑️ Narrate by paragraphs (when streaming)   | Checked *(reduces wait time)*                                  |
| ☑️ Only narrate "quotes"                    | Checked                                                        |
| ☑️ Ignore \*text\* inside asterisks         | Checked                                                        |
| Audio Playback Speed                       | 1.00                                                           |
| Provider Endpoint                          | `https://YOUR-POD-ID-8888.proxy.runpod.net/v1/audio/speech`   |
| API Key                                    | `none`                                                         |
| Model                                      | `orpheus`                                                      |
| Available Voices                           | `tara,leah,jess,mia,zoe,leo,dan,zac`                          |

### Available Voices

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

### Voice Assignments

In the voice dropdown below the settings, assign a voice to each character:

| Character      | Voice                        |
|----------------|------------------------------|
| Your character | Pick one that fits their vibe |
| {{user}}       | disabled                     |
| Narrator       | disabled (or pick one)       |

> **Finding your Pod ID:** RunPod dashboard → click your pod → HTTP Services → Port 8888 proxy URL.

### TTS Behavior Explained

- **Only narrate "quotes"** — actions in `*asterisks*` are shown as text but not spoken
- **Ignore \*text\* inside asterisks** — prevents the TTS from reading stage directions
- **Narrate by paragraphs** — starts playing audio as paragraphs arrive instead of waiting for the full response
- **Auto Generation** — automatically generates audio for every response without clicking

---

## 8. Speech-to-Text (Voice Input)

Full voice conversations — speak instead of type.

### Install the Extension

1. Click the **puzzle piece icon** (Extensions)
2. Click **"Download Extensions & Assets"** or **"Install extension"**
3. Search for **Speech Recognition**
4. Install it, then refresh your browser

### Configure

| Setting          | Value                              |
|------------------|------------------------------------|
| STT Provider     | Browser                            |
| Input Device     | Your headset microphone            |
| ☑️ Enabled        | Checked                            |

A **microphone icon** appears in the chat bar. Click it, speak, and your words get transcribed and sent.

> **Note:** Browser STT works best in Chrome. Make sure microphone permissions are allowed in browser settings.

### Full Voice Loop

1. Click mic → speak
2. Browser transcribes your voice to text
3. Text goes to Venice AI → response generated
4. Orpheus TTS converts to audio → plays in headphones
5. VMagicMirror lip syncs → avatar's mouth moves

---

## 9. RunPod Pod Configuration (Orpheus TTS Backend)

| Setting            | Value           |
|--------------------|-----------------|
| GPU                | RTX 4090        |
| Template           | PyTorch         |
| Container Disk     | 30 GB           |
| Volume Disk        | 20 GB           |
| Expose HTTP Ports  | 8888            |

### Starting the Pod

**Fresh pod (first time):**
```bash
bash runpod-orpheus-setup.sh
```

**Restarted pod (files in /workspace):**
```bash
bash /workspace/runpod-orpheus-startup.sh
```

### Cost

- Running: ~$0.60/hr (RTX 4090)
- Stopped (storage only): ~$0.10/day
- **Always stop the pod when you're done**

---

## 10. Quick Start Checklist

Every time you want to chat:

1. ☐ **RunPod:** Start your Orpheus pod → run `bash /workspace/runpod-orpheus-startup.sh`
2. ☐ Wait for "Orpheus-FastAPI is ready" message
3. ☐ **VMagicMirror:** Open it (auto-loads your avatar if configured)
4. ☐ **SillyTavern:** Run `start.bat` → opens in browser
5. ☐ Verify TTS endpoint URL matches your current RunPod pod proxy URL
6. ☐ Send a message → hear the voice → see the lips move
7. ☐ **When done:** Stop the RunPod pod to save money

---

## 11. Troubleshooting

### No audio playing
- Right-click SillyTavern browser tab → make sure it's not muted
- Check Windows Volume Mixer → browser not muted
- Verify RunPod pod is running and TTS endpoint URL is correct

### TTS "Connection error to API at 127.0.0.1:1234"
- The llama.cpp server on the Orpheus pod crashed. SSH into the pod and restart:
  ```bash
  cd /workspace/llama.cpp && ./build/bin/llama-server -m /models/orpheus-3b-0.1-ft-q4_k_m.gguf -c 8192 -ngl 99 --host 0.0.0.0 --port 1234 &
  ```

### Port 8888 won't bind on RunPod
- Jupyter is using it. Kill it first:
  ```bash
  fuser -k 8888/tcp
  ```

### Audio takes too long to start
- Enable "Narrate by paragraphs (when streaming)" in TTS settings
- Enable Streaming in sampler settings
- Keep responses short via Character's Note and example dialogue

### Responses are too long
- Add brevity instructions to Character's Note (Depth 4, System)
- Use short example dialogues (1-2 sentences each)
- Lower Max Response Length in sampler settings
- Start a new chat (old long messages teach the model to be verbose)

### Responses are too short or flat
- Write longer, more detailed example dialogues
- Increase Max Response Length to 500+
- Increase Temperature to 0.9-1.0
- Add more detail to the character Description

### Vector Storage not working
- Check all checkboxes are enabled in extension settings
- Click "Vectorize All" to re-index existing conversations
- Verify Vectorization Source is set to Local (Transformers)

### World Info not triggering
- Make sure the book is **activated** (not just created)
- Check that each entry's status dot is **green**
- Verify your keywords match what you're typing in chat
- Try adding more keyword variations

### Speech recognition not working
- Use Chrome (best Web Speech API support)
- Check microphone permissions in browser settings
- Verify the correct mic is selected in STT settings

### Pod proxy URL changed
- Happens when you terminate and recreate a pod (not when you stop/start)
- Update the Provider Endpoint in SillyTavern TTS settings with the new URL

### Character feels generic or inconsistent
- Add more specific detail to the Description (speech patterns, quirks, habits)
- Add more World Info entries with specific lore
- Write better example dialogues that showcase their unique voice
- Use Character's Note for behavioral rules
