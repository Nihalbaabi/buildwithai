import { useState, useEffect, useRef, useCallback } from "react";
import { getDatabase, ref, onValue } from "firebase/database";
import {
  formatTimestamp,
  pushWaterLiveData,
  pushWaterLogData,
  type WaterTankPayload,
} from "@/lib/firebase";

const TANK_CAPACITY = 1000; // litres
const OUTLET_RATE_PER_SEC = 1;   // L/s when outlet open → 60 L/min
const REFILL_RATE_PER_SEC = 5;   // L/s when motor on  → 300 L/min
const PERIODIC_INTERVAL_MS = 60_000; // 1 minute
const TICK_MS = 1_000; // 1 second

export function useWaterTank(userId: string) {
  const [outlets, setOutlets] = useState({ kitchen: false, washroom1: false, washroom2: false });
  const [refillOn, setRefillOn] = useState(false);   // motorStatus
  const [waterLevel, setWaterLevel] = useState<number>(() => {
    const stored = localStorage.getItem(`waterLevel_${userId}`);
    return stored !== null ? parseFloat(stored) : TANK_CAPACITY;
  });
  const [lastPush, setLastPush] = useState("");
  const [firebaseStatus, setFirebaseStatus] = useState<
    "idle" | "sending" | "success" | "error"
  >("idle");

  const waterLevelRef = useRef(waterLevel);
  waterLevelRef.current = waterLevel;
  const outletsRef = useRef(outlets);
  outletsRef.current = outlets;
  const refillOnRef = useRef(refillOn);
  refillOnRef.current = refillOn;

  // ── Compute net flow rate in L/min ────────────────────────────────────────
  const computeFlowRate = (outletsState: typeof outlets, refill: boolean): number => {
    let rate = 0;
    const activeOutletsCount = Object.values(outletsState).filter(Boolean).length;
    rate += activeOutletsCount * OUTLET_RATE_PER_SEC * 60; // convert L/s → L/min
    if (refill) rate += REFILL_RATE_PER_SEC * 60;
    return parseFloat(rate.toFixed(2));
  };

  // ── Firebase push ──────────────────────────────────────────────────────────
  const pushToFirebase = useCallback(
    async (level: number, outletsState: typeof outlets, refill: boolean) => {
      const now = new Date();
      const ts = formatTimestamp(now);
      const flowRate = computeFlowRate(outletsState, refill);
      const anyOutletOn = Object.values(outletsState).some(Boolean);

      const payload: WaterTankPayload = {
        timestamp: ts,
        tankLevel: parseFloat(level.toFixed(2)),
        waterLevel: parseFloat(level.toFixed(2)),  // backward compat
        flowRate,
        motorStatus: refill,
        outletOn: anyOutletOn,
        refillOn: refill,  // backward compat
        sections: {
          kitchen: outletsState.kitchen ? OUTLET_RATE_PER_SEC * 60 : 0,
          washroom1: outletsState.washroom1 ? OUTLET_RATE_PER_SEC * 60 : 0,
          washroom2: outletsState.washroom2 ? OUTLET_RATE_PER_SEC * 60 : 0,
        }
      };
      setFirebaseStatus("sending");
      try {
        await Promise.all([
          pushWaterLiveData(userId, payload),
          pushWaterLogData(userId, payload),
        ]);
        setFirebaseStatus("success");
        setLastPush(ts);
        console.log(`[useWaterTank] Pushed: level=${level.toFixed(2)}L, flow=${flowRate}L/min, motor=${refill}`);
      } catch (err) {
        console.error("[useWaterTank] Firebase push failed:", err);
        setFirebaseStatus("error");
      }
    },
    [userId]
  );

  // ── 1-second tick: drain & refill simulation ──────────────────────────────
  useEffect(() => {
    const tick = setInterval(() => {
      const outletsState = outletsRef.current;
      const anyOutletOn = Object.values(outletsState).some(Boolean);
      const activeOutletsCount = Object.values(outletsState).filter(Boolean).length;
      const refill = refillOnRef.current;
      if (!anyOutletOn && !refill) return;

      setWaterLevel((prev) => {
        let next = prev;
        // a. Simulate Tank Drain (outlets open)
        if (anyOutletOn) next -= (OUTLET_RATE_PER_SEC * activeOutletsCount);
        // b. Simulate Motor Fill
        if (refill) next += REFILL_RATE_PER_SEC;

        // --- AUTOMATION TRIGGERS ---
        // 1. Auto-Shutoff: Tank is full
        if (next >= TANK_CAPACITY && refill) {
          console.log("[AutoSystem] Tank Full (1000L). Automatically stopping motor.");
          setRefillOn(false);
          refillOnRef.current = false;
          // Push immediately so app UI knows it stopped
          pushToFirebase(TANK_CAPACITY, outletsState, false);
        }

        // 2. Auto-Refill: Level dropped below 150L
        if (next < 150 && !refill) {
           console.log("[AutoSystem] Low Water Detected (<150L). Automatically starting motor.");
           setRefillOn(true);
           refillOnRef.current = true;
           pushToFirebase(next, outletsState, true);
        }

        next = Math.min(TANK_CAPACITY, Math.max(0, next));
        waterLevelRef.current = next;
        localStorage.setItem(`waterLevel_${userId}`, next.toFixed(2));
        return next;
      });
    }, TICK_MS);
    return () => clearInterval(tick);
  }, [userId]);

  // ── Periodic DB push every minute ─────────────────────────────────────────
  useEffect(() => {
    const interval = setInterval(() => {
      const outletsState = outletsRef.current;
      const anyOutletOn = Object.values(outletsState).some(Boolean);
      const refill = refillOnRef.current;

      if (anyOutletOn || refill) {
        // c. Send Continuous Updates to Firebase
        pushToFirebase(waterLevelRef.current, outletsState, refill);
      } else {
        // Still push periodic idle state so Flutter always has fresh data
        pushToFirebase(waterLevelRef.current, { kitchen: false, washroom1: false, washroom2: false }, false);
        console.log("[useWaterTank] Periodic idle push (level only).");
      }
    }, PERIODIC_INTERVAL_MS);
    return () => clearInterval(interval);
  }, [userId, pushToFirebase]);

  // ── Sync with Firebase Control (Listening to EcoTrack commands) ───────────
  useEffect(() => {
    if (!userId || userId === 'undefined') return;
    
    const db = getDatabase();
    const waterRef = ref(db, `users/${userId}/water/live`);
    const unsubscribe = onValue(waterRef, (snapshot) => {
      const data = snapshot.val();
      if (data && data.motorStatus !== undefined) {
         // Only update if it differs from current internal state
         if (data.motorStatus !== refillOnRef.current) {
            console.log(`[useWaterTank] External command received: Motor -> ${data.motorStatus}`);
            setRefillOn(data.motorStatus);
            refillOnRef.current = data.motorStatus;
         }
      }
    });

    return () => unsubscribe();
  }, [userId]);

  // ── Toggle handlers (immediate DB push) ───────────────────────────────────
  const toggleOutlet = useCallback((id: 'kitchen' | 'washroom1' | 'washroom2') => {
    const nextState = { ...outletsRef.current, [id]: !outletsRef.current[id] };
    outletsRef.current = nextState;
    setOutlets(nextState);
    console.log(`[useWaterTank] Outlet ${id} toggled → ${nextState[id]}. Pushing immediately.`);
    pushToFirebase(waterLevelRef.current, nextState, refillOnRef.current);
  }, [pushToFirebase]);

  const toggleRefill = useCallback(() => {
    const next = !refillOnRef.current;
    refillOnRef.current = next;
    setRefillOn(next);
    console.log(`[useWaterTank] Motor (refill) toggled → ${next}. Pushing immediately.`);
    pushToFirebase(waterLevelRef.current, outletsRef.current, next);
  }, [pushToFirebase]);

  return {
    waterLevel,
    outlets,
    refillOn,
    toggleOutlet,
    toggleRefill,
    lastPush,
    firebaseStatus,
    tankCapacity: TANK_CAPACITY,
  };
}
