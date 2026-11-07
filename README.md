# JARVIS — personal AI assistant

A working local assistant: voice conversation, an AI brain, web search with
summaries, weather, live system telemetry, app launching and a permission-gated
file/command manager. Python backend, HTML/CSS/JS frontend, no build step.

The interface is a dark navy console with a reactive cyan AI core, a live
microphone waveform and a status dashboard.

---

## Quick start (Windows)

1. **Double-click `start.bat`.**
   The first run downloads a private copy of Python 3.12 and the dependencies
   into this folder (about a minute). Nothing is installed system-wide and no
   administrator rights are needed.
2. Your browser opens at **http://127.0.0.1:8000**.
3. Open **Settings → AI MODEL** and connect a model (details below).
4. Allow microphone access when the browser asks.

Requirements: Windows 10/11, internet for the first setup, and **Chrome or Edge**
for speech recognition (Firefox has no speech-to-text engine).

### Manual start

```bat
.venv\Scripts\python.exe run.py
```

Options: `run.py --no-browser` skips opening the browser. Set `JARVIS_PORT`
to change the port (default 8000, automatically shifts if busy).

---

## Connecting an AI model

The assistant speaks the standard OpenAI `/chat/completions` protocol, so any
compatible provider works. Pick one in **Settings → AI MODEL**.

| Provider | Cost | How to get a key |
| --- | --- | --- |
| **Groq** | Free tier | <https://console.groq.com/keys> · default `llama-3.3-70b-versatile` |
| **OpenRouter** | Free models available | <https://openrouter.ai/keys> · default `meta-llama/llama-3.3-70b-instruct` |
| **OpenAI** | Paid | <https://platform.openai.com/api-keys> · default `gpt-4o-mini` |
| **Ollama** | Free, fully local | Install from <https://ollama.com>, run `ollama pull llama3.2`, keep `ollama serve` running. No key needed. |
| **Custom** | Whatever you run | Any OpenAI-compatible base URL, e.g. LM Studio (`http://localhost:1234/v1`) |

Paste the key into Settings and press **Save key**, then **Test connection**.

**Where keys live:** `data/secrets.json` inside this project, readable only by
your Windows account. The browser receives only a masked hint such as
`gsk-…9f2a` — never the key itself. Alternatively put keys in a `.env` file
(copy `.env.example`), which takes priority over the interface. `data/` and
`.env` are git-ignored.

**Without a key** the assistant still works in command mode: system status,
weather, web search, files, time/date, app and website launching. It tells you
plainly that conversation needs a model instead of faking answers.

---

## Using it

### Voice

- **Click the AI core** (or the mic in the input bar) to start listening. The
  core reacts to your voice and the waveform shows live input levels.
- Click again, press `Esc`, or just stop talking. Your speech is sent when the
  browser finalises a phrase.
- Replies are spoken with the browser's speech synthesis engine. Choose the
  voice, rate, pitch and volume in **Settings → VOICE**; **Test** previews it.
- **Continuous conversation** (Settings → Voice): after each reply the mic opens
  again so you can talk back without clicking.
- **Wake word**: with “Require wake word” on, hands-free listening ignores
  speech until it hears “Jarvis” (configurable). One activation keeps the
  conversation open for two minutes.

Try: *“Jarvis, what’s the weather?”* · *“Open notepad”* · *“Search the web for
the F1 standings”* · *“System status”* · *“Explain black holes simply”*.

### AI brain

Conversation context is kept per browser session (last 24 turns) so follow-ups
like *“explain that more simply”* work. The model can call read-only tools on
its own — web search, system status, weather, file listing and file reading —
and must ask permission before changing anything. Pick a personality
(Professional, Friendly, Concise, Witty) in Settings.

### Computer assistant

Every state-changing action appears in a permission card showing exactly what
will happen (the executable and path, the URL, the full command, the file and
its size) before anything runs:

| Action | Risk | Notes |
| --- | --- | --- |
| Launch application | low | Allowlist of common apps (notepad, calculator, chrome, explorer, vscode, spotify, office, terminal…), resolved to real executables |
| Open website | low | `http(s)` only, opens in your default browser |
| Create / overwrite file | medium | Inside permitted folders only |
| Delete file or folder | high | Moves to the Recycle Bin via `send2trash` |
| Run system command | high | PowerShell, 30 s timeout, dangerous patterns refused, can be disabled entirely |

Read-only actions (list/read/search files) run immediately because they change
nothing. **Deny** cancels; the assistant never retries a denied action on its
own. “Auto-approve low risk” in Settings skips the prompt for app and website
launches only.

**Permitted folders** are your home folder and this project. Add more with
`JARVIS_ALLOWED_ROOTS` in `.env` (separate paths with `;`). Writing into
`C:\Windows`, `Program Files` and `ProgramData` is always refused.

### Internet search

**Search** tab or *“search the web for …”*. Results come from DuckDuckGo (no
API key); the top pages are fetched, their text extracted, and your model writes
a short summary with source links. Without a model you get the raw findings and
snippets. DuckDuckGo can rate-limit heavy use — retry after a moment.

### Dashboard

Live clock and date, weather from Open-Meteo (no key; set a city in Settings or
click **Use my location**), CPU / memory / disk usage, uptime, host details, and
battery state when the device reports one. Desktops without a battery show
“Mains power — no battery detected” rather than a made-up percentage. Activity
log shows the latest actions.

### Settings

Everything except voice preferences saves to the server automatically; the
voice list and sliders are browser-specific and live in `localStorage`.
`Settings → SYSTEM` shows the active engine, model, platform and version.

---

## How it is built

```
jarvis/
├─ start.bat            double-click launcher
├─ setup.ps1            project-local Python + dependencies
├─ run.py               starts uvicorn on 127.0.0.1, opens the browser
├─ requirements.txt
├─ server/
│  ├─ app.py            FastAPI routes + static hosting
│  ├─ config.py         settings/secrets, providers, personalities
│  ├─ assistant.py      intent routing, sessions, capability replies
│  ├─ intent.py         deterministic command parser (works offline)
│  ├─ brain.py          OpenAI-compatible client, tool loop, prompts
│  ├─ actions.py        allowlisted actions + permission registry
│  └─ services/         system.py · weather.py · websearch.py
├─ static/
│  ├─ index.html
│  ├─ css/styles.css
│  └─ js/               main · assistant · voice · core · dashboard · views · api · ui
└─ data/                created at runtime: settings.json, secrets.json
```

**Why commands are parsed locally:** *“open notepad”* and *“run the command
ipconfig”* are handled by a deterministic parser before the model sees them.
That means they work offline, cost no tokens, and cannot be reinterpreted by a
model. Everything else goes to the LLM, which can request tools.

---

## Security

- The server binds to **127.0.0.1 only** — nothing on your network can reach it.
- Mutating requests require a custom `X-Jarvis-Client: 1` header; other websites
  cannot send it cross-origin, so a random page cannot drive your assistant.
- No CORS headers are granted.
- API keys never leave the machine and are never returned to the browser.
- Command execution is refused for destructive patterns (format, diskpart,
  shutdown, registry deletion, shadow-copy tampering, recursive forced deletes)
  and is approval-gated even when allowed.
- Paths are resolved and checked against permitted roots before any read,
  write or delete.

Known limits: JARVIS runs with your user rights, so approvals are the real
safety boundary — read the permission card before pressing Allow. Speech
recognition in Chrome sends audio to Google's service; use text input or a
browser with on-device recognition if that matters to you.

---

## Configuration reference

| Variable | Purpose |
| --- | --- |
| `JARVIS_PROVIDER` | `openai`, `groq`, `openrouter`, `ollama`, `custom` |
| `JARVIS_MODEL` | Model name override |
| `JARVIS_BASE_URL` | OpenAI-compatible endpoint |
| `OPENAI_API_KEY` / `GROQ_API_KEY` / `OPENROUTER_API_KEY` / `JARVIS_API_KEY` | Provider keys |
| `JARVIS_CITY` | Default weather city |
| `JARVIS_PORT` | Port, default 8000 |
| `JARVIS_ALLOWED_ROOTS` | Extra permitted folders, `;`-separated |

---

## Troubleshooting

**Mic does nothing / “Microphone access was blocked”.** Allow the microphone
from the icon in the address bar (JARVIS runs on `localhost`, which browsers
treat as secure). Close other apps holding the mic — Teams, Zoom and OBS can
block exclusive access. Use Chrome or Edge; Firefox has no speech-to-text.

**No voices in the list.** Voice list loads asynchronously from Windows. Wait a
second and reopen Settings; if the system has no voices, install one under
Windows Settings → Time & Language → Speech.

**“No AI model is configured.”** Add a key, or start Ollama and select it. Press
**Test connection** for the exact error (bad key, wrong model name, endpoint
unreachable).

**Ollama errors.** `ollama serve` must be running and the model must be pulled
(`ollama pull llama3.2`). Model name must match exactly.

**Weather says “Location needed”.** Set a city in Settings, or click **Use my
location** and allow the browser prompt.

**Port already in use.** JARVIS automatically tries the next free port; the
console prints the URL it chose.

**Search returns nothing.** DuckDuckGo rate limits rapid queries; wait a minute.
Without a model, summaries are replaced by raw snippets.

**Reset everything.** Delete `data/settings.json` (settings) or
`data/secrets.json` (keys). Delete the whole `.venv` + `.python` folders to
re-run setup from scratch.

---

## Built with

Python, FastAPI, Uvicorn, httpx, psutil, BeautifulSoup, `ddgs`, send2trash,
python-dotenv; vanilla HTML/CSS/JS with the Web Speech API, Canvas 2D and the
Open-Meteo + DuckDuckGo APIs. All free and open source; fonts are Orbitron and
Inter (SIL Open Font License).
