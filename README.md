# Nadi: The Body Knows
### Live Biosensor Installation · Probabilistic Raga Agent · Real-Time Biofeedback System

![Nadi installation view](installation.jpg)
*Installation view, Sympoietics, York University, 2026*

---

## Overview

Nadi: The Body Knows is a live biosensor installation that maps a performer's heart rate to Hindustani classical ragas in real time through a five-process signal chain running entirely on a single machine. A MAX30102 optical pulse sensor reads photoplethysmographic data from the fingertip. A probabilistic agent in SuperCollider selects between three ragas — Bhairav, Bhimpalasi, and Bhupali — using a transition probability matrix modulated by HR zone, time of day, dwell time, and an internal mood variable. A browser-based visualization renders ambient ink-diffusion effects synchronized to the agent's state via WebSocket relay.

The agent does not simply mirror physiological state. Over ninety seconds it climbs an autonomy arc from 0.0 to 1.0, gradually decoupling from the incoming HR signal and generating its own musical material freely. The moment participants noticed the music had stopped following them was the work's central event.

Performed and exhibited at *Sympoietics*, York University, April 2026.

---

## Signal Chain

```
Finger → Arduino (MAX30102) → Python bridge (OSC) → SuperCollider (agent + synthesis)
                                                            ↓
                                               Python relay (WebSocket)
                                                            ↓
                                                    Browser (canvas visuals)
```

| Process | Language | Role |
|---------|----------|------|
| **Arduino** | C++ | Reads MAX30102 IR sensor via PPG, computes BPM, outputs over USB serial at 9600 baud |
| **Python bridge** | Python | Reads serial port, validates BPM (30–200), packages as OSC message, sends to SuperCollider port 57120 |
| **SuperCollider** | SuperCollider | Receives `/hr` OSC, runs probabilistic raga agent every 3 seconds, drives melody + tabla synthesis, emits state OSC on port 57200 |
| **Python relay** | Python | Listens for OSC on port 57200, converts to JSON, broadcasts via WebSocket on port 8765 |
| **Browser** | HTML/JS | Receives WebSocket JSON, updates Canvas animation — ink diffusion responds to raga, HR, and autonomy level |

No internet required. No cloud. Five processes communicating over localhost.

---

## The Probabilistic Agent

Heart rate does not determine raga selection — it modulates probabilities. Three 3×3 transition matrices govern low-HR (< 65 bpm), mid-HR (65–85 bpm), and high-HR (> 85 bpm) zones. Being in Bhairav with high HR produces approximately 25% probability of moving to Bhupali per decision cycle — not a certainty. Sustained physiological pressure over multiple cycles is what shifts the agent's behaviour, producing inertia: the machine commits to a raga and resists momentary fluctuations.

Three additional modifiers adjust base probabilities at each decision point:

- **Time-of-day modifier** — at dawn, Bhairav is favoured regardless of HR; at evening, Bhupali
- **Dwell-time counter** — agent resists switching for the first 8 cycles; after 20 cycles it develops restlessness independent of HR
- **Mood variable** — drifts slowly toward the HR zone over time, providing a smoothed physiological trajectory the agent consults alongside real-time HR

### Autonomy Arc

| Phase | Autonomy | Behaviour |
|-------|----------|-----------|
| Listening | 0.0 – 0.2 | Follows HR-mediated matrix closely |
| Negotiating | 0.2 – 0.5 | Begins weighing internal mood against HR signal |
| Asserting | 0.5 – 0.8 | 40% of decisions from agent's own evolving state |
| Free | 0.8 – 1.0 | Ignores HR entirely; generates chromatic phrases at variable tempos |

---

## Musical Content

Each raga is implemented with composed phrases based on authentic *chalan* (characteristic movement patterns), incorporating three named Hindustani ornaments: *meend* (slide from below), *gamaka* (oscillation/vibrato), and *kan* (grace note from above). SuperCollider synthesis approximates sitar timbre via layered Pluck UGens with sympathetic string detune. A continuous tanpura drone at Sa–Sa–Ma–Pa grounds the tonal foundation throughout.

| Raga | Time | Rasa | Character |
|------|------|------|-----------|
| Bhairav | Dawn | Shanta (peace) | Austere, contemplative — komal Re and komal Dha |
| Bhimpalasi | Afternoon | Shringar (longing) | Warmth and longing — characteristic ascending skip |
| Bhupali | Evening | Ananda (joy) | Pentatonic, bright, celebratory |

---

## Visualization

The browser visualization receives state data — current raga, autonomy level, phase, HR — via WebSocket JSON. Ambient ink-diffusion effects in warm amber tones on a near-black background respond to the agent's internal state. In the Free phase, forms become erratic and accumulate rather than fading. The visual is not an interface — no controls, no readouts, no labels. It is a mood reflection, designed to be legible as feeling rather than data.

---

## Why This Matters for AI Safety Research

Nadi is a working prototype of several questions central to AI safety and alignment:

**Perceived agency vs. computational reality.** Participants consistently described the agent as "stubborn," "distracted," "making up its own mind" — attributing intentionality to a probabilistic system. This directly instantiates the distinction between AI systems genuinely possessing agency and humans perceiving them as doing so (Legaspi et al., 2023) — a distinction with immediate implications for how AI systems should be designed and evaluated in high-stakes contexts.

**The autonomy arc as alignment model.** The transition from a system that follows human input to one that operates independently is not just an artistic device — it is a controlled demonstration of alignment drift. The moment participants noticed the music had stopped following them is precisely the kind of behavioral shift that alignment research needs to detect, characterize, and where necessary, prevent.

**Biofeedback and adaptive AI in neurorehabilitation.** The transition probability matrix, dwell counter, and autonomy arc are design primitives for a class of adaptive health technology that does not yet fully exist. The architecture directly informs ongoing MRP research on AI-assisted rehabilitation for stroke survivors at York University — specifically, how a system can begin by following a patient's physiological lead and gradually introduce therapeutic challenge without losing the patient's trust.

---

## Repository Structure

```
nadi-the-body-knows/
  arduino/
    nadi.ino              ← MAX30102 sensor reading + BPM computation
  python/
    bridge.py             ← Serial → OSC bridge (port 57120)
    relay.py              ← OSC → WebSocket relay (port 8765)
  supercollider/
    nadi.scd              ← Probabilistic raga agent + synthesis engine
  html/
    visuals.html          ← Browser visualization (Canvas + WebSocket)
  paper/
    nadi_paper.pdf        ← Full theoretical paper (Sympoietics, York University, 2026)
  photos/
    installation.jpg      ← Exhibition documentation
  README.md
```

---

## Dependencies

**Arduino:** SparkFun MAX3010x library

**Python:** `pyserial`, `python-osc`, `websockets`
```bash
pip install pyserial python-osc websockets
```

**SuperCollider:** Standard SC3 installation with default SC synth server

**Browser:** Any modern browser — no installation required

---

## Running the System

1. Upload `arduino/nadi.ino` to Arduino Uno
2. Run `python bridge.py` — confirm serial port in script
3. Open SuperCollider, boot server, run `nadi.scd`
4. Run `python relay.py`
5. Open `html/visuals.html` in browser
6. Place finger on MAX30102 sensor

---

## Academic References

Bennett, D. M., Roudaut, O. A., & Mekler, E. (2023). How does HCI understand human agency and autonomy? *Proceedings of CHI 2023.* https://doi.org/10.1145/3544548.3580651

Haraway, D. J. (2016). *Staying with the trouble: Making kin in the Chthulucene.* Duke University Press.

Legaspi, R., Shi, Z., & Morales, Y. (2023). The sense of agency in human-AI interactions. *Knowledge-Based Systems, 286*, 111298. https://doi.org/10.1016/j.knosys.2023.111298

Lehrer, P., et al. (2020). Heart rate variability biofeedback improves emotional and physical health and performance. *Applied Psychophysiology and Biofeedback, 45*(3), 109–129.

Suchman, L. A. (1987). *Plans and situated actions.* Cambridge University Press.

---

## Stack
`Arduino C++` `Python` `SuperCollider` `OSC` `WebSocket` `HTML/JS` `MAX30102` `Biosensor` `Generative Music` `HCI` `Biofeedback`

---

*Performed at Sympoietics, York University, April 2026. Full theoretical paper available in `/paper/`. Directly informs ongoing MRP research on AI-assisted neurorehabilitation for stroke survivors.*
