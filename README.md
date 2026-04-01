# 🌿 SaveSphere — AI-Powered Smart Home Energy & Water Manager

> **Hackathon Project** | Google AI Integration | Flutter + React + Firebase + ESP32

---

## Problem Statement

Households waste significant electricity and water every day — not because they don't care, but because they have **no real-time visibility** into their consumption. Traditional utility bills arrive bimonthly, by which time it's too late to change behaviour. Existing smart home systems are either too expensive, too complex, or lack intelligent AI-driven insights in a language users understand.

**SaveSphere solves this** by building a complete IoT + AI ecosystem:
- **Hardware layer** — ESP32 microcontrollers with current sensors and flow sensors capture real energy and water data from your actual home.
- **Simulation layer** — A web-based virtual home lets you demonstrate the full system without physical hardware.
- **Intelligence layer** — Google Gemini AI analyses live sensor data and answers natural-language questions, predicts bills, and lets you control appliances using your voice.

---

## Project Description

SaveSphere is a **complete IoT smart home management system** that works in two modes:

| Mode | Data Source | Use Case |
|---|---|---|
| **Simulation Mode** | Web Dashboard (React + Vite) | Demo & hackathon — virtual appliances simulate real usage |
| **Real Home Mode** | ESP32 + Sensors → Firebase | Deployed in an actual home with physical hardware |

The system has three layers:

| Layer | Component | Tech Stack |
|---|---|---|
| **Hardware** | ESP32 + Current Sensors + Flow Sensors | C++ (Arduino), MQTT/HTTP → Firebase |
| **Simulation** | Home Simulation Dashboard | React, Vite, TypeScript |
| **App** | SaveSphere Mobile App | Flutter, Dart, Gemini AI |

All data — whether from real sensors or the virtual simulator — flows into **Firebase Realtime Database**, which the Flutter app reads to power its analytics and Gemini AI assistant.

### 📁 Repository Structure

```
buildwithai/
├── SaveSphere_Complete/     ← 📱 Flutter Product App
│   └── ecotrack/            (The main mobile application)
│       ├── lib/             Flutter source code (providers, screens, services)
│       ├── pubspec.yaml     Flutter dependencies
│       └── ...
│
├── buildai_source/          ← 🖥️ Home Simulation Dashboard (Web App)
│   ├── src/                 React + Vite + TypeScript source code
│   ├── package.json         Node.js dependencies
│   └── ...
│
└── README.md
```

| Folder | Type | Description |
|---|---|---|
| **`SaveSphere_Complete/`** | 📱 Flutter Product App | The main SaveSphere mobile app — energy & water analytics, Gemini AI voice assistant, smart notifications |
| **`buildai_source/`** | 🖥️ Web Simulation Dashboard | Virtual home simulator — toggles appliances, simulates water tank, syncs live data to Firebase for the Flutter app to read |

> **How they connect:** Run `buildai_source` to simulate a home environment → data flows to Firebase → `SaveSphere_Complete` reads it and brings it to life with AI insights.

### 🌍 Global Scalability

SaveSphere is built to work **anywhere in the world** — not just Kerala or India. The core system is utility-agnostic:

> **The calculation logic never changes. Only the rates and API endpoints do.**

| What changes per country/region | What stays the same |
|---|---|
| Electricity tariff rates ($/kWh, £/kWh, ₹/unit) | All sensor logic, Firebase sync, flutter app |
| Water authority API (KWA → BWSSB → Thames Water → etc.) | Section-wise flow tracking & analytics |
| Currency symbol (₹, $, €, £) | AI assistant, voice control, chart engine |
| Billing cycle (monthly, bi-monthly, quarterly) | Real-time monitoring & notifications |
| Slab/tiered rate structure | ESP32 firmware & relay control |

```
User in Kerala       → KWA API  + KSEB rates   → ₹  bill estimate
User in Bangalore    → BWSSB API + BESCOM rates  → ₹  bill estimate
User in UK           → Thames Water + Octopus Energy API → £  bill estimate
User in UAE          → DEWA API                 → AED bill estimate
User in USA          → Local utility API         → $  bill estimate
```

- Adding a **new region** = adding its tariff config + linking its utility API
- The app **auto-switches currency, rates, and billing logic** based on the user's region setting
- **No code rewrite needed** — only a new entry in the rates configuration file

> 🌐 This makes SaveSphere a globally deployable resource management platform. A college in London, a hospital in Dubai, or a hostel in Bangalore can all run the same app with localised billing logic.

---

## Google AI Usage

### Tools / Models Used

- **Google Gemini 1.5 Flash** (`gemini-1.5-flash`) via `google_generative_ai` Dart SDK — used as the core brain of the voice assistant
- **Google Firebase Realtime Database** — used as the bi-directional data layer between hardware, simulation, and app
- **Google Firebase Authentication** — used for securing user accounts and personalized data handling
- **Google Vertex AI** — leveraged using Google Cloud credits to generate core app architectures and scalable services
- **Google AI Studio** — used for prompt engineering, testing intents, and fine-tuning Gemini responses
- **Google Gemini (Chat)** — used extensively for project idea generation, brainstorming features, and scoping the hardware architecture
- **Gemini Nano & Banana** — used to generate custom, high-quality app icons and logos
- **Gemini & Vertex AI** — used to generate the dynamic splash page video and UI template layouts

### How Google AI Was Used

Google's AI and Cloud ecosystem powers SaveSphere entirely end-to-end. Beyond just integrating language models, we used Google's generative tools to build the app, design its assets, and architect the hardware ecosystem. Here is a full breakdown:

#### 1. Gemini Voice Assistant (App Core)
The primary feature of the SaveSphere app is its Gemini-powered voice assistant, utilizing **Gemini 1.5 Flash**. Every time a user asks a question, the app:
- **Collects real-time sensor data** (current watts per room, tank levels, flow rate, monthly ₹ bills) directly from Firebase.
- **Sends this live context** to Gemini alongside the user's natural language query (e.g., *"Why is my usage so high today?"*).
- **Outputs intelligent, localized advice**: *"Your kitchen is drawing the most power at 1200 W right now — consider turning off the oven when not in use to bring down your estimated bill of ₹842."*
- **Maintains chat history** across the session so follow-up contextual questions seamlessly work.

#### 2. App Icons, Logos, and Media Generation
Because we built from scratch without graphic designers, we used **Gemini Nano & Banana** to generate all our custom, high-quality icons and the core app logo.
For our dynamic animated launch screen, we used **Gemini and Vertex AI** to conceptualize and render the high-quality splash page video that plays when the user opens the Flutter app.

#### 3. Idea Generation and System Architecture
Before writing a single line of code, we used **Google Gemini via Chat** as our primary co-architect. Gemini helped brainstorm the project, designed the precise "Sleep Mode" leak detection algorithm (time-based flow tracking), and scoped the physical ESP32 + sensor hardware topology required to make this work in a real home.

#### 4. App Development and UI Templates
Using our Google Cloud credits, we leveraged **Google Vertex AI** to structurally generate parts of our user interface layouts and scalable Dart services for our Flutter product application. **Google AI Studio** was used to test prompts, fine-tune temperature, and map intent boundaries before locking in our system instructions in the official SDK.

#### 5. Data and Security (Firebase Suite)
The entire project's real-time communication between the ESP32 hardware, the web simulator, and the Flutter app is managed by **Google Firebase Realtime Database**. We also utilize **Firebase Authentication** to manage user accounts securely and ensure a personalized UI/AI dashboard for every user.

---

## Proof of Google AI Usage

<div style="display: flex; flex-wrap: wrap; gap: 10px;">
  <img src="./SaveSphere_Complete/ecotrack/assets/proof/proof1.png" width="300" />
  <img src="./SaveSphere_Complete/ecotrack/assets/proof/proof2.png" width="300" />
  <img src="./SaveSphere_Complete/ecotrack/assets/proof/proof3.png" width="300" />
  <img src="./SaveSphere_Complete/ecotrack/assets/proof/proof4.png" width="300" />
  <img src="./SaveSphere_Complete/ecotrack/assets/proof/proof6.png" width="300" />
  <img src="./SaveSphere_Complete/ecotrack/assets/proof/proof7.jpg" width="300" />
  <img src="./SaveSphere_Complete/ecotrack/assets/proof/proof8.jpg" width="300" />
  <img src="./SaveSphere_Complete/ecotrack/assets/proof/proof9.jpg" width="300" />
  <img src="./SaveSphere_Complete/ecotrack/assets/proof/proof%2010.png" width="300" />
  <img src="./SaveSphere_Complete/ecotrack/assets/proof/proof11.png" width="300" />
</div>

---

## Screenshots

<div style="display: flex; flex-wrap: wrap; gap: 10px;">
  <img src="./SaveSphere_Complete/ecotrack/assets/projectscreeshots/screenshot1.jpg" width="200" />
  <img src="./SaveSphere_Complete/ecotrack/assets/projectscreeshots/screenshot2.jpg" width="200" />
  <img src="./SaveSphere_Complete/ecotrack/assets/projectscreeshots/screenshot3.jpg" width="200" />
  <img src="./SaveSphere_Complete/ecotrack/assets/projectscreeshots/screenshot4.jpg" width="200" />
  <img src="./SaveSphere_Complete/ecotrack/assets/projectscreeshots/screeshot5.jpg" width="200" />
  <img src="./SaveSphere_Complete/ecotrack/assets/projectscreeshots/screenshot6.jpg" width="200" />
  <img src="./SaveSphere_Complete/ecotrack/assets/projectscreeshots/screenshot7.jpg" width="200" />
  <img src="./SaveSphere_Complete/ecotrack/assets/projectscreeshots/screenshot8.jpg" width="200" />
  <img src="./SaveSphere_Complete/ecotrack/assets/projectscreeshots/screenshot9.jpg" width="200" />
  <img src="./SaveSphere_Complete/ecotrack/assets/projectscreeshots/screenshot10.jpg" width="200" />
  <img src="./SaveSphere_Complete/ecotrack/assets/projectscreeshots/screenshot11.jpg" width="200" />
  <img src="./SaveSphere_Complete/ecotrack/assets/projectscreeshots/screenshot12.jpg" width="200" />
  <img src="./SaveSphere_Complete/ecotrack/assets/projectscreeshots/screenshot13.jpg" width="200" />
  <img src="./SaveSphere_Complete/ecotrack/assets/projectscreeshots/screenshot14.jpg" width="200" />
</div>

---

## Demo Video

[▶️ Watch the SaveSphere Demo Video on Google Drive](https://drive.google.com/drive/folders/14NQEyWWBaxuD-CERfDyj7Cn_BemDZzlR)



## Installation Steps

```bash
# Clone the repository
git clone https://github.com/Nihalbaabi/buildwithai.git

# Go to project folder
cd buildwithai
```

### 1. Home Simulation Web App (buildai_source)

```bash
# Navigate to the web app
cd buildai_source

# Install dependencies
npm install

# Run the project
npm run dev
```



### 2. SaveSphere Flutter App (SaveSphere_Complete)

```bash
# Navigate to the Flutter app
cd SaveSphere_Complete/ecotrack

# Install dependencies
flutter pub get

# Run the project
flutter run
```

### 3. Firebase Configuration

Both apps connect to the same Firebase Realtime Database. Update the config in:

- **Web app**: `buildai_source/src/lib/firebase.ts`
- **Flutter app**: `SaveSphere_Complete/ecotrack/lib/config/` (firebase options)

---

## Key Features

### 🏠 Home Simulation Dashboard (Web App)

- **Dual-user simulation** — Simulates two independent households (User 1 & User 2) simultaneously
- **Per-appliance control** — Toggle individual appliances per room:
  - 🛏️ **Bedroom**: LED Bulb (15W), Ceiling Fan (75W), Computer (200W)
  - 🛋️ **Living Room**: Television (150W), Tube Light (20W)
  - 🍳 **Kitchen**: Fridge (300W), Oven (1200W), LED Bulb (20W)
- **Real-time power calculation** — Live Watt counter updates instantly on every toggle
- **Water Tank Simulation** — 1000L tank with:
  - Section-wise drain control (Kitchen, Washroom 1, Washroom 2)
  - Motor refill at 5 L/s (300 L/min)
  - Auto-shutoff when tank is full (1000L)
  - Auto-refill trigger when tank level drops below 150L
- **🌙 Sleep Mode Toggle** — Enable night-mode on the water dashboard:
  - Sets per-section flow time limits (default: 30 min for washrooms, 15 min for kitchen at night)
  - Any continuous flow exceeding the limit triggers a leak alert to the mobile app
  - Configurable thresholds — users can adjust limits based on household habits
- **Firebase sync** — All toggle states and sensor readings push to Firebase every 60 seconds (and immediately on change)
- **Firebase status indicator** — Live badge showing sync state (idle / sending / success / error)

### 📱 SaveSphere Flutter App

### 🤖 AI Voice Assistant (Gemini Powered)
- Speak or type any question about energy or water usage
- Gemini AI responds with accurate, real-time data from your home
- Maintains conversation context across the session
- Falls back to rule-based responses if network is unavailable
- Text-to-Speech output using female voice (flutter_tts)

### ⚡ Energy Analytics
- **Live power monitoring** — Real-time Watt readings per room
- **Hourly, daily, weekly, monthly charts** — Powered by `fl_chart`
- **Room-wise breakdown** — See which room consumes most energy
- **Peak usage detection** — Identifies the hour and day of peak consumption
- **Estimated monthly bill (₹)** — Calculated using tiered electricity slab tariffs

### 💧 Water Analytics
- **Live tank level** — Real-time percentage and litre reading
- **Section-wise drainage tracking** — Kitchen, Washroom 1, Washroom 2
- **Flow rate monitoring** — L/min reading synced from the simulator
- **Daily water usage summary**
- **🌙 Sleep Mode — Intelligent Night Leak Detection** *(Planned)*
  - User activates Sleep Mode before going to bed
  - System learns normal night-time usage patterns (e.g., a washroom visit uses water for max 30 minutes)
  - If water flow is detected from **any section beyond the threshold time**, the app raises an immediate alert:
    > *"⚠️ Continuous water flow detected from Washroom 1 for 45 minutes — possible leak or tap left open!"*
  - Works per section — Kitchen, Washroom 1, Washroom 2 each have independent timers
  - If **no one has used the washroom** but flow is still detected → immediate high-priority leak alert
  - Helps catch real-world issues like a running tap, broken float valve, or pipe burst while the household is asleep

### 💰 Money Management
- Set a monthly energy budget — get notified at 50%, 75%, and 100%
- Bi-monthly billing cycle support
- Slab-based tariff calculation

### 🚨 Emergency Remote Control
- **Turn off appliances from anywhere** — If you left home and realised the iron box, oven, or any room is still ON, open the app and switch it off instantly
- **Dual control methods** — both the **toggle switch** (tap room icon on the dashboard) and **voice command** (say *"Turn off kitchen"*) work from anywhere with internet
- **Turn off everything at once** — One tap or one voice command shuts down all rooms simultaneously
- **Works on simulation now** — All room controls in the web simulator are fully controllable via the Flutter app in real time through Firebase
- **Real-world equivalent** — In a real home, the same command travels: App → Firebase → ESP32 → Relay → appliance turns OFF within seconds
- **No distance limit** — Works from the next room, the next city, or another country as long as both devices are connected to the internet

> 💡 *Real-world example: You're at the office and remember you left the iron box plugged in. Open SaveSphere, tap Bedroom → OFF. Done. The relay at home cuts power instantly.*

### 🔔 Smart Notifications
- High power usage alert (> 1980 W)
- Budget threshold alerts (50% / 75% / 100%)
- Peak hour warnings (6 PM – 10 PM)
- Electricity slab change notifications
- **Appliance-left-on reminder** — If a high-wattage appliance (oven, iron) runs for more than a configurable duration (e.g. 2 hours), alert the user *(Planned)*

### 🎨 Settings & Customization
- Dark / Light / System theme toggle (also controllable via AI voice command)
- Monthly budget configuration
- Expected usage targets

---

## 🔌 Real Home Hardware Implementation

In a real home deployment, the web simulation dashboard is **replaced by physical IoT hardware**. The Firebase Realtime Database remains the central data hub — no changes needed in the Flutter app.

### Hardware Components

| Component | Purpose | Details |
|---|---|---|
| **ESP32 Microcontroller** | Central hub — reads sensors, posts to Firebase, receives control commands | Wi-Fi enabled, runs 24/7 |
| **Current Sensors (SCT-013)** | Measures electricity consumption per circuit | Clamp-on, non-invasive — placed on live wires for Bedroom, Living Room, Kitchen |
| **Flow Sensors (YF-S201)** | Measures water flow rate (L/min) | Installed on outlet pipes — Kitchen, Washroom 1, Washroom 2 |
| **Relay Module (4-channel)** | Controls appliances remotely | Receives ON/OFF commands from Firebase, switches mains-connected appliances |
| **Water Level Sensor** | Monitors overhead tank | Float sensor or ultrasonic sensor to measure tank level |

### 💰 Real-World Hardware Cost Estimate

The entire system can be built and deployed in a real home for **under ₹6,000** — making it one of the most affordable smart home solutions available.

| Component | Qty | Approx. Cost (₹) |
|---|---|---|
| ESP32 Dev Board (Wi-Fi + Bluetooth) | 1 | ₹350 – ₹500 |
| SCT-013 Non-Invasive Current Sensor | 3 (one per room) | ₹600 – ₹900 |
| YF-S201 Water Flow Sensor | 3 (Kitchen + 2 Washrooms) | ₹450 – ₹750 |
| 4-Channel Relay Module | 1 | ₹150 – ₹250 |
| HC-SR04 Ultrasonic Tank Level Sensor | 1 | ₹100 – ₹150 |
| Resistors, capacitors, burden resistors | — | ₹50 – ₹100 |
| Connecting wires, jumper cables | — | ₹100 – ₹150 |
| Project box / enclosure | 1 | ₹150 – ₹300 |
| Power supply (5V adapter) | 1 | ₹150 – ₹250 |
| **Total** | | **₹2,100 – ₹3,350** |

> ✅ **Even with premium components and professional installation, the total stays comfortably under ₹6,000.** No subscription, no cloud hardware fees — just Firebase's free Spark plan for most households.

> 🔧 **DIY Friendly** — All components are widely available on Amazon India, Robu.in, or local electronics shops. No soldering required for basic setup — breadboard-compatible connections work fine for a home prototype.

### How It Works — Real Home Data Flow

```
🏠 Real Home
│
├── 🔌 Current Sensors (SCT-013)
│    ├── Bedroom circuit  ──────────────┐
│    ├── Living Room circuit ───────────┤
│    └── Kitchen circuit  ─────────────┤
│                                      │
├── 💧 Flow Sensors (YF-S201)          │
│    ├── Kitchen outlet   ─────────────┤
│    ├── Washroom 1 outlet ────────────┤
│    └── Washroom 2 outlet ────────────┤
│                                      ▼
├── 🌊 Tank Level Sensor  ──────► ESP32 Microcontroller
│                                  (reads all sensors,
│                                   calculates kW & L/min)
│                                      │
│                                      ▼ HTTP POST
│                              Firebase Realtime DB
│                              /users/{id}/energy/live
│                              /users/{id}/water/live
│                                      │
│                    ┌─────────────────┴──────────────────┐
│                    ▼                                    ▼
│           SaveSphere Flutter App               ESP32 listens for
│           (reads data, runs Gemini AI,         control commands at
│            shows charts, notifies user)        /users/{id}/control
│                    │                                    │
│                    └──── User taps or says ─────────────┘
│                          "Turn off kitchen"  ──► Firebase ──► ESP32 ──► Relay OFF
```

### Sensor Data → Firebase Schema

The ESP32 pushes the following structure to Firebase every 60 seconds (and immediately on change):

```json
{
  "users": {
    "user1": {
      "energy": {
        "live": {
          "timestamp": "2026-04-01 07:00:00",
          "power": {
            "bedroom": 290,
            "livingRoom": 170,
            "kitchen": 1500,
            "total": 1960
          },
          "energy": {
            "bedroom": 12.4,
            "livingRoom": 8.1,
            "kitchen": 45.2
          },
          "switches": {
            "bedroom": true,
            "lrLight": true,
            "lrTV": false,
            "kitchen": true
          }
        }
      },
      "water": {
        "live": {
          "timestamp": "2026-04-01 07:00:00",
          "tankLevel": 720.5,
          "flowRate": 60.0,
          "motorStatus": false,
          "sections": {
            "kitchen": 60,
            "washroom1": 0,
            "washroom2": 0
          }
        }
      },
      "control": {
        "bedroom": true,
        "lrLight": true,
        "lrTV": false,
        "kitchen": true
      }
    }
  }
}
```

### 🚨 Remote & Emergency Control — App & Voice

The system supports **two-way communication** — not just monitoring but full remote control from anywhere in the world:

### 📱 App Toggle Control
- Tap room icons on the Home screen to toggle rooms ON/OFF
- The app writes to `users/{id}/control` in Firebase
- The ESP32 listens to this node 24/7 using Firebase streaming and triggers the relay module
- UI updates **instantly** (optimistic update), then confirms via Firebase
- **Works on Simulation** — The Home Simulation web dashboard responds to Flutter app toggles in real time through Firebase

### 🎙️ Voice Control (via Gemini AI Assistant)
Users can speak natural commands to control their home — including emergency shut-off from anywhere:

| Voice Command | Action | Use Case |
|---|---|---|
| *"Turn off the kitchen"* | Sends OFF to kitchen relay | Left oven on by mistake |
| *"Turn off the bedroom"* | Sends OFF to bedroom relay | Iron box left plugged in |
| *"Switch on the bedroom"* | Sends ON to bedroom relay | Turn on lights before arriving home |
| *"Turn off everything"* | Sends OFF to ALL rooms at once | Emergency shut-off when leaving home |
| *"Turn on all lights"* | Sends ON to all rooms | Welcome home automation |
| *"Is anything still on?"* | Gemini reads all switch states and reports | Quick check before sleeping |
| *"What is my current power usage?"* | Gemini reads live sensor data and responds | Usage awareness |
| *"What will my bill be this month?"* | Gemini calculates from kWh + tariff slab | Budget tracking |
| *"How much water has been used today?"* | Gemini reads flow sensor total | Water conservation |
| *"Switch to dark mode"* | Changes app theme | UI preference |

### ⚡ Emergency Use Cases

| Scenario | What to do | How SaveSphere helps |
|---|---|---|
| Left iron box on before going to office | Open app → tap Bedroom → OFF | Relay cuts power at home within seconds |
| Oven running, nobody home | Say *"Turn off kitchen"* | Voice command → Firebase → ESP32 → Relay OFF |
| Going on a trip — want everything off | Say *"Turn off everything"* | All relays switch OFF with one command |
| Child left AC on in empty room | Tap Living Room toggle in app | Instant remote control from anywhere |
| High power alert received | App notification → tap to turn off | React to alerts without rushing home |

All control commands are handled by the `AssistantProvider` — it detects intent, executes the action, and then asks Gemini to generate a natural confirmation response.

---

## System Architecture

### Simulation Mode (Hackathon Demo)

```
┌─────────────────────────────────┐       ┌──────────────────────────────┐
│   Home Simulation (Web App)     │       │   SaveSphere (Flutter App)   │
│   React + Vite + TypeScript     │       │   Dart + Flutter             │
│                                 │       │                              │
│  Appliance Toggles              │──────▶│  EnergyDataProvider          │
│  Water Tank Simulation          │       │  WaterDataProvider           │
│         │                       │       │         │                    │
│         ▼                       │       │         ▼                    │
│   Firebase Realtime DB   ◀──────┼───────┼──▶ GeminiService             │
│   (Live + Log nodes)            │       │   (Gemini 1.5 Flash)         │
└─────────────────────────────────┘       │         │                    │
                                          │         ▼                    │
                                          │  Voice Assistant + Charts    │
                                          └──────────────────────────────┘
```

### Real Home Mode (Production)

```
┌─────────────────────────────────┐       ┌──────────────────────────────┐
│   Physical Home Hardware        │       │   SaveSphere (Flutter App)   │
│                                 │       │   Dart + Flutter             │
│  Current Sensors (SCT-013)      │       │                              │
│  Flow Sensors (YF-S201)         │──────▶│  EnergyDataProvider          │
│  Tank Level Sensor              │       │  WaterDataProvider           │
│  ESP32 Microcontroller          │       │         │                    │
│  Relay Module                   │       │         ▼                    │
│         │                  ◀────┼───────┼── GeminiService + Voice AI   │
│         ▼                       │       │         │                    │
│   Firebase Realtime DB   ◀──────┼───────┼──▶ Remote Control Commands   │
│   (bi-directional sync)         │       │   (App toggle / Voice cmd)   │
└─────────────────────────────────┘       └──────────────────────────────┘
                  ▲
       ESP32 reads /control node
       and fires relay to switch
       physical appliances ON/OFF
```

---

## 🏢 Who Can Use SaveSphere?

SaveSphere is designed to scale across any building or institution where energy and water monitoring matters. Real-time visibility + AI-driven notifications can drive significant resource savings in all these settings:

| Setting | Use Case | Key Benefit |
|---|---|---|
| 🏠 **Homes** | Monitor daily appliance usage, control rooms remotely | Reduce monthly electricity & water bills |
| 🏫 **Hostels** | Multi-room tracking per floor or block | Prevent wastage in shared spaces without supervision |
| 🏛️ **Colleges & Universities** | Campus-wide energy audits, lab & classroom monitoring | Meet sustainability goals, reduce institutional costs |
| 🏥 **Hospitals** | 24/7 critical monitoring of high-load equipment areas | Ensure uninterrupted supply, flag anomalies early |
| 🏗️ **Office Buildings** | Floor-wise consumption tracking & AC/lighting control | Automate off-hours shutdowns, ESG reporting |
| 🏨 **Hotels & Guest Houses** | Per-room energy & water metering | Charge guests fairly, detect leaks in real time |
| 🕌 **Religious / Community Centres** | Peak-hour load management | Avoid overload during large gatherings |

> 💡 **The Core Idea**: When people can *see* their usage in real-time on their phone and receive instant alerts, they naturally reduce waste. SaveSphere replaces passive monthly bills with an **active, AI-powered feedback loop** that changes behaviour.

---

## ⚠️ Current Limitations / Missing Features

The following features are **planned but not yet implemented** in the current version. They are tracked here for transparency and roadmap clarity.

### 🔗 Utility Authority Integrations (Not Yet Implemented)

| Feature | Description | Status |
|---|---|---|
| **KSEB Bill Integration** | Auto-fetch actual electricity bills from Kerala State Electricity Board portal using consumer number | 🔜 Planned |
| **KWA Integration** | Connect to Kerala Water Authority API to fetch official water consumption records and compare with sensor data | 🔜 Planned |
| **EB / Water Bill OCR** | Scan a physical bill using the phone camera; Gemini Vision extracts the reading and adds it to the app | 🔜 Planned |
| **Tariff Slab Auto-Update** | Pull latest KSEB/KWA tariff rates automatically instead of hardcoded values | 🔜 Planned |

### 📱 App Features (Partially Implemented or Missing)

| Feature | Description | Status |
|---|---|---|
| **Multi-User / Multi-Room Dashboard** | A single admin view showing all users/blocks/floors in one screen (for hostels, colleges) | 🔜 Planned |
| **Sleep Mode — Smart Leak Detection** | Enable sleep mode on the water dashboard; if any section (Kitchen/Washroom 1/Washroom 2) shows continuous flow beyond its configured time limit (e.g. 30 min for washrooms at night), the app fires a room-specific leak alert — *"Continuous flow from Washroom 1 for 45 min — possible leak!"* | 🔜 Planned |
| **Daytime Leak Detection** | Detect abnormally long uninterrupted flow even during the day (e.g. a tap left running for 2+ hours) and alert the user | 🔜 Planned |
| **PDF / CSV Report Export** | Monthly energy & water usage reports exportable as PDF or spreadsheet | 🔜 Planned |
| **Google Calendar Integration** | Import schedules to predict peak hours (exam days, holidays) and pre-adjust usage targets | 🔜 Planned |
| **Offline Mode** | App works without internet — logs data locally and syncs when back online | 🔜 Planned |
| **Wear OS / Widget Support** | Quick glance at live usage from a smartwatch or home-screen widget | 🔜 Planned |
| **Gemini Vision — Bill Scanning** | Point camera at electricity/water bill; AI reads and imports data | 🔜 Planned |
| **Historical Comparison** | Compare this month vs. same month last year | 🔜 Planned |
| **Multi-Language Support** | Malayalam, Hindi, Tamil UI for broader accessibility in Kerala & India | 🔜 Planned |

### 🔌 Hardware (Not Yet Deployed)

| Feature | Description | Status |
|---|---|---|
| **Physical ESP32 Deployment** | Actual sensors installed in a home — currently running in simulation mode | 🔜 In Progress |
| **Solar Panel Monitoring** | Track energy generated from rooftop solar vs. consumed from the grid | 🔜 Planned |
| **Smart Meter Integration** | Direct API link to government smart meters (where available) | 🔜 Planned |
| **Automated Motor Control** | Water pump auto-ON/OFF based on tank level without manual intervention | ✅ Simulated |

---

## 🚀 Future Enhancements

A roadmap of high-impact features that would transform SaveSphere from a smart home tool into a **city-scale resource management platform**:

### Phase 2 — Deep Government Integration
- **KSEB Consumer Portal Sync** — Log in with your KSEB consumer number; the app pulls your official monthly units consumed, compares with sensor data, and flags billing discrepancies.
- **KWA Portal Sync** — Link your Kerala Water Authority account to cross-verify measured water usage against official bills.
- **Subsidy & Tariff Alerts** — Notify users when KSEB or KWA tariff slabs change so bill estimates stay accurate.
- **Government Demand-Response Programs** — Participate in grid load-shedding programs; the app automatically turns off non-critical appliances during peak grid demand.
- **Global Utility API Layer** — A pluggable adapter system where each region/country provides its electricity and water utility API credentials. The core engine remains identical; only rates, currency, and API endpoints are swapped. Target integrations: BESCOM (Bangalore), DEWA (Dubai), Ofwat-regulated utilities (UK), US EIA API, and more.

### Phase 3 — Institutional Scale
- **Admin Dashboard (Web)** — A central management portal for hostel wardens, college facility managers, or hospital engineers to view all buildings/floors in one place.
- **Role-Based Access** — Separate views for admins (all rooms), managers (one floor), and residents (their room only).
- **Automated Alerts to Authority** — If a hospital's water tank drops critically or power consumption spikes, auto-notify the facility manager and the backup generator controller.
- **Inter-Building Comparison** — Show how your building compares with similar institutions in the area; motivate competitive reduction.

### Phase 4 — AI & Prediction Upgrades
- **Predictive Bill Forecasting** — Use 3 months of historical data to predict next month's bill with high accuracy.
- **Anomaly Detection** — Gemini flags unusual spikes (e.g., "Your water usage jumped 300% at 2 AM — possible pipe burst").
- **AI-Powered Scheduling** — Gemini suggests the optimal time to run high-consumption appliances (washing machine, oven) to stay within budget.
- **Carbon Footprint Tracker** — Convert energy usage to kg CO₂ equivalent; show users their environmental impact.
- **Solar Generation Forecasting** — Based on weather data, predict how much solar energy will be generated tomorrow.

### Phase 5 — Community & Civic Impact
- **Neighbourhood Usage Map** — Anonymised heatmap of energy/water usage by area (opt-in).
- **Water Scarcity Alerts** — Push notifications when KWA announces water supply restrictions in the user's area.
- **Government Reporting** — Auto-generate compliance reports for institutions required to submit energy audits.
- **Save & Earn** — Gamification layer where users earn points for hitting savings targets; redeemable for utility credits (pilot with KSEB).

> 🌍 **Vision**: SaveSphere started as a hackathon project but addresses a real crisis — Kerala faces both electricity shortages during dry seasons and water scarcity. A widely-deployed SaveSphere network could give KWA and KSEB unprecedented ground-level visibility into consumption, enabling smarter distribution and dramatically reducing waste at scale.

---

## Tech Stack

| Layer | Technology |
|---|---|
| **Mobile App** | Flutter, Dart |
| **Web Simulator** | React, Vite, TypeScript, TailwindCSS |
| **AI (Language Model)** | Google Gemini 1.5 Flash |
| **Database & Sync** | Firebase Realtime Database |
| **IoT Microcontroller** | ESP32 (Wi-Fi enabled, Arduino C++) |
| **Energy Sensing** | SCT-013 Non-Invasive Current Sensors |
| **Water Sensing** | YF-S201 Hall Effect Flow Sensors |
| **Appliance Control** | Relay Module (controlled via ESP32) |
| **Water Tank** | Ultrasonic / Float Level Sensor |
| **Charts** | fl_chart (Flutter) |
| **Voice Input** | speech_to_text (Flutter) |
| **Voice Output** | flutter_tts (Flutter) |
| **State Management** | Provider (Flutter) |
| **Notifications** | flutter_local_notifications |

---


