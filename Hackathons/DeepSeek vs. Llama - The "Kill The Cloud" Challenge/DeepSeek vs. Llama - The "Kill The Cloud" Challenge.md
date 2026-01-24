Source:
1. https://unstop.com/hackathons/deepseek-vs-llama-the-kill-the-cloud-challenge-guru-gobind-singh-indraprastha-university-ggsipu-delhi-1619510
2. https://docs.google.com/document/d/e/2PACX-1vQDRAOEquDMVkm8nCV5AU9ArgwrUqGb_ig5NPMxNvpxP820JMtSjNDDBmQ-kKATXxr0GECcDiRMdT9H/pub
3. https://aistudio.google.com/prompts/1eIIX_oeORwLXc7ULADT_ixRY8eFpnkC4


| Date                                 | What to do                                                                                                                                                       |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Fri, Jan 23, 2026 (Day 0)**        | Register + confirm deadline (30 Jan) • Complete Unstop profile • Join WhatsApp + Discord • Create folder `KillTheCloud_2026/` • Create “team” (only if required) |
| **Sat, Jan 24, 2026 (Day 1)**        | Pick 1 idea (one sentence) • Define “Magic Moment” • Finalize project name • Write Problem Statement (100–200 words) • Write Solution Summary (3–6 lines)        |
| **Sun, Jan 25, 2026 (Day 2)**        | Build slides **1–6**: Title • User + pain • Magic moment (ZERO internet) • Why on-device • Model selection • Core architecture diagram (NO CLOUD)                |
| **Mon, Jan 26, 2026 (Day 3)**        | Build slides **7–10**: Feasibility • Risks + mitigations • Differentiation • Future scope                                                                        |
| **Tue, Jan 27, 2026 (Day 4)**        | Add product feel: UI mock • User journey diagram • Cloud vs on-device table • Offline Mode Toggle (Fast/Reasoning/Battery Saver)                                 |
| **Wed, Jan 28, 2026 (Day 5)**        | Polish deck: spacing/alignment/fonts • Remove text walls • Improve diagrams • Export PDF with correct file name                                                  |
| **Thu, Jan 29, 2026 (Day 6)**        | Submission prep: paste Problem + Solution in Unstop • Upload PDF • Final spelling/link check • Prepare 60s pitch + 3 judge Q&As                                  |
| **Fri, Jan 30, 2026 (Deadline Day)** | Final re-check • Submit early ✅ • Stay active on Discord for judging rounds                                                                                      |

Todo:

## 0) Register like a pro (Day 0)

✅ **Unstop setup**

* [ ] Confirm registration + deadline: **30 Jan 2026**
* [ ] Fill profile cleanly (headline + skills + 1–2 projects)

✅ **Comms setup**

* [ ] Join WhatsApp updates group
* [ ] Join Discord (final judging happens here)
* [ ] Create a single folder: `KillTheCloud_2026/`

✅ **Solo dev hack**

* [ ] Create a “team” using a friend alt (if rules enforce 2–4)
  *(If they truly enforce team-only, don’t risk disqualification.)*

---

## 1) Win strategy (before idea selection)

Your submission is judged on:
**Originality + clarity + feasibility + offline/on-device necessity + architecture quality.**

So your winning angle should scream:
✅ “This only works **because** it’s offline”
✅ “This is **privacy-critical**”
✅ “This needs **instant latency**”
✅ “Data never leaves device — provably”

---

## 2) Pick a winning idea (1 hour max)

### The best hackathon ideas are:

* Narrow user + urgent pain + clear “magic moment”
* One killer workflow (not 10 features)
* Easy to diagram in a clean architecture slide

✅ Your filtering checklist:

* [ ] Is there **sensitive data**? (health/identity/private speech)
* [ ] Is **connectivity unreliable**?
* [ ] Does latency matter **a lot**?
* [ ] Can the AI output directly trigger an action?

### 5 “easy-to-win” idea templates (steal one)

Pick ONE and build the deck around it:

**A) Offline Emergency Medic (rural / disaster)**
Symptoms + camera + voice → triage + step-by-step treatment checklist offline.

**B) Private Therapy Companion (journaling + tone)**
Voice + local diary → mood insights + CBT steps, no cloud ever.

**C) Offline Legal/Police Safety Mode**
Records + summarizes interactions locally, generates rights checklist + scripts.

**D) Factory Safety Copilot (edge device)**
Camera/audio → detects hazard patterns offline, alerts instantly.

**E) Offline Personal Finance Guardian**
Reads SMS/bank notifications locally → fraud detection + spending insights.

✅ Todo (decision)

* [ ] Pick your idea in **one sentence**
* [ ] Define your “Magic Moment” in **one screenshot-level scene**

---

## 3) Write deliverables first (your final text submission)

This hackathon wants **clear writing + architecture deck**.

### A) Project name (10 mins)

* [ ] Short, punchy, product-y
  Examples: **VaultMind**, **SubwayDoc**, **ZeroSignal**, **PocketGuardian**

### B) Problem statement (100–200 words)

Checklist:

* [ ] user persona
* [ ] pain
* [ ] why cloud fails
* [ ] why on-device wins (privacy + latency + reliability)

### C) Solution summary (3–6 lines)

Checklist:

* [ ] input → model(s) → output/action
* [ ] “data stays local” sentence included

---

## 4) Architecture deck that wins (THIS is the game)

Make a **7–10 slide deck**. Judges love clean structure.

### Slide-by-slide todo list (copy this)

**Slide 1 — Title**

* [ ] Name + tagline (“Intelligence Unchained” vibe)

**Slide 2 — The user + pain**

* [ ] Persona card (1 user)
* [ ] 1 real scenario (offline setting)

**Slide 3 — Magic Moment**

* [ ] Step 1 → Step 2 → Step 3 flow
* [ ] One bold line: “Works with ZERO internet.”

**Slide 4 — Why On-Device AI**

* [ ] Privacy: data never leaves device
* [ ] Latency: instant
* [ ] Reliability: works anywhere

**Slide 5 — Model selection (Logic)**
You *must* show you understand tradeoffs:

* [ ] DeepSeek (reasoning strength)
* [ ] Llama (speed / smaller variants)
* [ ] Optional: Whisper-style STT, TTS, VAD (offline voice pipeline)
* [ ] Explain **why each model exists** in your system

**Slide 6 — Core System Architecture (diagram)**

* [ ] Input: mic/camera/text
* [ ] On-device pipeline: VAD → STT → LLM → safety layer → action
* [ ] Storage: encrypted local vector store (optional)
* [ ] Output: voice/text/alerts
* [ ] Big red stamp: **NO CLOUD**

**Slide 7 — Feasibility**
Must mention:

* [ ] Quantization (ex: 4-bit)
* [ ] Memory constraints (smaller model option)
* [ ] Battery strategy (on-demand inference, streaming)
* [ ] Fallbacks (lite model vs heavy reasoning mode)

**Slide 8 — Risks + mitigations**
This is a judge-winning slide.

* [ ] hallucinations → guardrails + confidence + “ask user”
* [ ] privacy → encryption + no external calls
* [ ] safety → disclaimers + escalation logic

**Slide 9 — Differentiation**

* [ ] Why this beats cloud apps
* [ ] Why this beats normal offline apps
* [ ] 2–3 key “defensibility” points

**Slide 10 — Future scope**

* [ ] model updates via offline packages
* [ ] multilingual support
* [ ] edge deployment variants

✅ Deck rules (very important)

* [ ] **One idea. One story.**
* [ ] **Readable fonts.** No walls of text.
* [ ] 1 diagram + 1 flowchart is enough.
* [ ] Always use “**works offline**” repeatedly.

---

## 5) Make it feel “real” (without coding)

Judges love when it feels like a product.

Add these (fast + powerful):

* [ ] 1 UI mock (Figma / even PPT shapes)
* [ ] 1 user journey diagram
* [ ] 1 latency/privacy comparison table (Cloud vs On-device)

**Bonus (kills it):**

* [ ] Include “Offline Mode Toggle”: **Fast / Reasoning / Battery Saver**

---

## 6) Judge-proof feasibility checklist

Before submission, validate your own idea:

* [ ] Can it run with a **small model** if needed?
* [ ] Does it avoid needing external databases?
* [ ] Are outputs safe even if the model is wrong?
* [ ] Is it useful even with **partial accuracy**?

If any answer is “no”, simplify the scope.

---

## 7) Submission checklist (final 2 hours)

✅ Packaging

* [ ] Export deck as **PDF**
* [ ] File name: `ProjectName_KillTheCloud_ArchitectureDeck.pdf`
* [ ] Put your 100–200 word statement into a clean final version

✅ Unstop submission

* [ ] Paste Problem + Solution carefully (no formatting bugs)
* [ ] Upload PDF
* [ ] Double-check title spelling and links

✅ Discord ready

* [ ] Prepare a 60-second pitch
* [ ] Prepare 3 likely judge Q&As:

  * “Why on-device?”
  * “How is it feasible?”
  * “What model + why?”

---

## 8) The winning “judge pitch” script (memorize this)

Use this structure:

1. **User + pain** (10s)
2. **Magic moment** (15s)
3. **Why offline** (10s)
4. **Architecture** (15s)
5. **Feasibility** (10s)

Total: **~60 seconds**.

---

## 9) Extra unfair advantages (solo dev edition)

* [ ] Make your deck *look premium* (consistent font + spacing)
* [ ] Use 1 strong icon set (no clutter)
* [ ] Add 1 crisp diagram with arrows (judges remember visuals)
* [ ] Write like a product designer: clear and human

---

## 10) Suggested timeline for this hackathon (Jan 23 → Jan 29)

* **Day 1:** Pick idea + write problem + solution
* **Day 2:** Build slides 1–6 (story + architecture)
* **Day 3:** Feasibility + risks + differentiation slides
* **Day 4:** Polish visuals + export PDF + final checks
* **Day 5:** Submission + pitch practice

---
