# 🌿 SaveSphere — AI-Powered Smart Home Energy & Water Manager

> **Hackathon Project** | Google AI Integration | Flutter + React + Firebase

---

## Problem Statement

Households waste significant electricity and water every day — not because they don't care, but because they have **no real-time visibility** into their consumption. Traditional utility bills arrive monthly, by which time it's too late to change behaviour. Smart meters exist, but lack intelligent, actionable insights in a language users understand.

**SaveSphere solves this** by combining a live home simulation dashboard with a natural-language AI assistant — giving users real-time awareness, predictive billing, and voice-controlled smart home management powered by **Google Gemini AI**.

---

## Project Description

SaveSphere is a **full-stack smart home management system** consisting of two connected applications:

| Component | Tech Stack | Role |
|---|---|---|
| **SaveSphere Mobile App** (`SaveSphere_Complete/ecotrack`) | Flutter + Dart | AI assistant, analytics, notifications, billing |
| **Home Simulation Dashboard** (`buildai_source`) | React + Vite + TypeScript | Real-time appliance simulation, water tank control |

Both apps are **connected via Firebase Realtime Database** — the web simulator acts as the "smart home sensor", and the Flutter app reads that live data to power its insights and AI responses.

---

## Google AI Usage

### Tools / Models Used

- **Google Gemini 1.5 Flash** (`gemini-1.5-flash`) via `google_generative_ai` Dart SDK
- **Google Firebase Realtime Database** (data sync layer)

### How Google AI Was Used

The SaveSphere Flutter app integrates Gemini 1.5 Flash as the brain of its AI voice assistant. Every time a user asks a question (by voice or text), the app:

1. **Collects real-time sensor data** — current power per room (Bedroom, Living Room, Kitchen), kWh consumed today and this month, estimated bill in ₹, water tank level, flow rate, and daily water usage.
2. **Sends this live context to Gemini** alongside the user's natural language query.
3. **Gemini returns a concise, data-driven 1–2 sentence answer** that references actual numbers from the user's home.

This means instead of hardcoded responses, users get answers like:

> *"Your kitchen is drawing the most power at 1200 W right now — consider turning off the oven when not in use to bring your estimated bill of ₹842 down."*

Gemini also maintains **chat history** across the session so follow-up questions are handled contextually.

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
- **Firebase sync** — All toggle states and sensor readings push to Firebase every 60 seconds (and immediately on change)
- **Firebase status indicator** — Live badge showing sync state (idle / sending / success / error)

### 📱 SaveSphere Flutter App

#### 🤖 AI Voice Assistant (Gemini Powered)
- Speak or type any question about energy or water usage
- Gemini AI responds with accurate, real-time data from your home
- Maintains conversation context across the session
- Falls back to rule-based responses if network is unavailable
- Text-to-Speech output using female voice (flutter_tts)

#### ⚡ Energy Analytics
- **Live power monitoring** — Real-time Watt readings per room
- **Hourly, daily, weekly, monthly charts** — Powered by `fl_chart`
- **Room-wise breakdown** — See which room consumes most energy
- **Peak usage detection** — Identifies the hour and day of peak consumption
- **Estimated monthly bill (₹)** — Calculated using tiered electricity slab tariffs

#### 💧 Water Analytics
- **Live tank level** — Real-time percentage and litre reading
- **Section-wise drainage tracking** — Kitchen, Washroom 1, Washroom 2
- **Flow rate monitoring** — L/min reading synced from the simulator
- **Daily water usage summary**

#### 💰 Money Management
- Set a monthly energy budget — get notified at 50%, 75%, and 100%
- Bi-monthly billing cycle support
- Slab-based tariff calculation

#### 🔔 Smart Notifications
- High power usage alert (> 1980 W)
- Budget threshold alerts (50% / 75% / 100%)
- Peak hour warnings (6 PM – 10 PM)
- Electricity slab change notifications

#### 🎨 Settings & Customization
- Dark / Light / System theme toggle (also controllable via AI voice command)
- Monthly budget configuration
- Expected usage targets

---

## System Architecture

```
┌─────────────────────────────────┐       ┌──────────────────────────────┐
│   Home Simulation (Web App)     │       │   SaveSphere (Flutter App)   │
│   React + Vite + TypeScript     │       │   Dart + Flutter             │
│                                 │       │                              │
│  ┌─────────┐  ┌──────────────┐  │       │  ┌────────────────────────┐  │
│  │ Appliance│  │  Water Tank  │  │──────▶│  │  EnergyDataProvider    │  │
│  │ Toggles  │  │  Simulation  │  │       │  │  WaterDataProvider     │  │
│  └─────────┘  └──────────────┘  │       │  └────────────────────────┘  │
│         │            │          │       │             │                 │
│         ▼            ▼          │       │             ▼                 │
│   ┌─────────────────────────┐   │       │  ┌────────────────────────┐  │
│   │  Firebase Realtime DB   │◀──┼───────┼─▶│  GeminiService         │  │
│   │  (Live + Log nodes)     │   │       │  │  (Gemini 1.5 Flash)    │  │
│   └─────────────────────────┘   │       │  └────────────────────────┘  │
└─────────────────────────────────┘       │             │                 │
                                          │             ▼                 │
                                          │  ┌────────────────────────┐  │
                                          │  │  Voice Assistant UI     │  │
                                          │  │  Charts & Analytics     │  │
                                          │  └────────────────────────┘  │
                                          └──────────────────────────────┘
```

---

## Proof of Google AI Usage

> 📁 Add screenshots to the `/proof` folder showing the Gemini AI responding in the app.

![AI Proof Screenshot](./proof/screenshot1.png)

---

## Screenshots

> 📁 Add project screenshots to the `/assets` folder.

![Home Simulation Dashboard](./assets/screenshot1.png)
![SaveSphere AI Assistant](./assets/screenshot2.png)
![Energy Analytics](./assets/screenshot3.png)
![Water Tank Management](./assets/screenshot4.png)

---

## Demo Video

[▶️ Watch Demo on Google Drive](#)

*(Max 3 minutes — showcasing the AI assistant answering live energy questions)*

---

## Installation Steps

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (>= 3.10)
- [Node.js](https://nodejs.org/) (>= 18)
- A Firebase project with Realtime Database enabled

---

### 1. Clone the Repository

```bash
git clone https://github.com/Nihalbaabi/buildwithai.git
cd buildwithai
```

---

### 2. Home Simulation Web App

```bash
# Navigate to the web app
cd buildai_source

# Install dependencies
npm install

# Run the development server
npm run dev
```

Open [http://localhost:5173](http://localhost:5173) in your browser.

---

### 3. SaveSphere Flutter App

```bash
# Navigate to the Flutter app
cd SaveSphere_Complete/ecotrack

# Install Flutter dependencies
flutter pub get

# Run on a connected Android/iOS device or emulator
flutter run
```

---

### 4. Firebase Configuration

Both apps connect to the same Firebase Realtime Database. Update the Firebase config in:

- **Web app**: `buildai_source/src/lib/firebase.ts`
- **Flutter app**: `SaveSphere_Complete/ecotrack/lib/config/` (firebase options)

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile App | Flutter, Dart |
| Web Simulator | React, Vite, TypeScript, TailwindCSS |
| AI | Google Gemini 1.5 Flash |
| Database | Firebase Realtime Database |
| Charts | fl_chart (Flutter) |
| Voice | flutter_tts, speech_to_text |
| State Management | Provider (Flutter) |
| Notifications | flutter_local_notifications |

---

## Team

Built with ❤️ for the Hackathon using **Google Cloud AI Credits**

> ⚠️ **Note**: The Gemini API key in this project is for demo purposes. Please replace it with your own key from [Google AI Studio](https://aistudio.google.com).
