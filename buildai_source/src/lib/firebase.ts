import { initializeApp } from "firebase/app";
import { getDatabase, ref, set, onValue } from "firebase/database";

const firebaseConfig = {
  apiKey: "AIzaSyDC0PuenM-vzg9KvpRI_AvhlLHf4cdzKeo",
  authDomain: "eco-track-e75ad.firebaseapp.com",
  projectId: "eco-track-e75ad",
  storageBucket: "eco-track-e75ad.firebasestorage.app",
  messagingSenderId: "1043700479151",
  appId: "1:1043700479151:web:f04ff956d246658a58d05a",
  measurementId: "G-N1YENEG84H",
  databaseURL: "https://eco-track-e75ad-default-rtdb.asia-southeast1.firebasedatabase.app"
};

const app = initializeApp(firebaseConfig);
const database = getDatabase(app);

export function formatTimestamp(date: Date): string {
  const pad = (n: number) => String(n).padStart(2, "0");
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}_${pad(date.getHours())}-${pad(date.getMinutes())}-${pad(date.getSeconds())}`;
}

export interface EnergyPayload {
  timestamp: string;
  power: {
    bedroom: number;
    livingRoom: number;
    kitchen: number;
    total: number;
  };
  energy: {
    bedroom: number;
    livingRoom: number;
    kitchen: number;
  };
}

export interface WaterTankPayload {
  timestamp: string;
  tankLevel: number;       // litres, 0-1000 (primary field)
  waterLevel: number;      // alias for tankLevel (backward compat)
  flowRate: number;        // Liters per minute drained/filled
  motorStatus: boolean;    // true = motor is ON (refilling)
  outletOn: boolean;       // true = outlet draining
  refillOn: boolean;       // alias for motorStatus (backward compat)
  sections?: {
    kitchen: number;
    washroom1: number;
    washroom2: number;
  };
}

export async function writeUserData(userId: string, pathSegment: string, payload: any) {
  if (!userId || userId.trim() === '' || userId === 'undefined' || userId === 'null') {
    console.error(`Blocked invalid Firebase write. UserId is invalid: ${userId}`);
    return;
  }
  const fullPath = `users/${userId}/energy/${pathSegment}`;
  await set(ref(database, fullPath), payload);
}

export async function pushLiveData(userId: string, payload: EnergyPayload) {
  await writeUserData(userId, 'live', payload);
}

export async function pushLogData(userId: string, payload: EnergyPayload) {
  await writeUserData(userId, `logs/${payload.timestamp}`, payload);
}

export async function pushWaterLiveData(userId: string, payload: WaterTankPayload) {
  if (!userId || userId.trim() === '' || userId === 'undefined' || userId === 'null') return;
  const fullPath = `users/${userId}/water/live`;
  await set(ref(database, fullPath), payload);
}

export async function pushWaterLogData(userId: string, payload: WaterTankPayload) {
  if (!userId || userId.trim() === '' || userId === 'undefined' || userId === 'null') return;
  const fullPath = `users/${userId}/water/logs/${payload.timestamp}`;
  await set(ref(database, fullPath), payload);
}

export function listenToControl(userId: string, callback: (data: any) => void) {
  if (!userId || userId.trim() === '' || userId === 'undefined' || userId === 'null') return () => {};
  const fullPath = `users/${userId}/energy/control`;
  const controlRef = ref(database, fullPath);
  return onValue(controlRef, (snapshot) => {
    callback(snapshot.val());
  });
}

export { database };
