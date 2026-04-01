# 🌿 SaveSphere — AI-Powered Smart Home Energy & Water Manager

> **Hackathon Project** | Google AI Integration | Flutter + React + Firebase + ESP32

---

## Problem Statement

Households waste significant electricity and water every day — not because they don't care, but because they have **no real-time visibility** into their consumption. Traditional utility bills arrive monthly, by which time it's too late to change behaviour. Existing smart home systems are either too expensive, too complex, or lack intelligent AI-driven insights in a language users understand.

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

## 🔌 Real Home Hardware Implementation

In a real home deployment, the web simulation dashboard is **replaced by physical IoT hardware**. The Firebase Realtime Database remains the central data hub — no changes needed in the Flutter app.

### Hardware Components

| Component | Purpose | Details |
|---|---|---|
| **ESP32 Microcontroller** | Central hub — reads sensors, posts to Firebase, receives control commands | Wi-Fi enabled, runs 24/7 |
| **Current Sensors (SCT-013)** | Measures electricity consumption per circuit | Clamp-on, non-invasive — placed on live wires for Bedroom, Living Room, Kitchen |
| **Flow Sensors (YF-S201)** | Measures water flow rate (L/min) | Installed on outlet pipes — Kitchen, Washroom 1, Washroom 2 |
| **Relay Module** | Controls appliances remotely | Receives ON/OFF commands from Firebase, switches mains-connected appliances |
| **Water Level Sensor** | Monitors overhead tank | Float sensor or ultrasonic sensor to measure tank level |

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

### Remote Control — App & Voice

The system supports **two-way communication** — not just monitoring but full remote control:

#### 📱 App Control
- Tap room icons on the Home screen to toggle rooms ON/OFF
- The app writes to `users/{id}/control` in Firebase
- The ESP32 listens to this node 24/7 using Firebase streaming and triggers the relay module
- UI updates **instantly** (optimistic update), then confirms via Firebase

#### 🎙️ Voice Control (via Gemini AI Assistant)
Users can speak natural commands to control their home:

| Voice Command | Action |
|---|---|
| *"Turn off the kitchen"* | Sends OFF command to kitchen relay via Firebase |
| *"Switch on the bedroom"* | Sends ON command to bedroom relay via Firebase |
| *"Turn off everything"* | Sends OFF to all rooms simultaneously |
| *"Turn on all lights"* | Sends ON to all rooms |
| *"What is my current power usage?"* | Gemini reads live sensor data and responds |
| *"What will my bill be this month?"* | Gemini calculates from kWh + tariff slab |
| *"How much water has been used today?"* | Gemini reads flow sensor total |
| *"Switch to dark mode"* | Changes app theme |

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

## Team

Built with ❤️ for the Hackathon using **Google Cloud AI Credits**

> ⚠️ **Note**: The Gemini API key in this project is for demo purposes. Please replace it with your own key from [Google AI Studio](https://aistudio.google.com).
