import { useState, useEffect, useRef, useCallback } from "react";
import { HOUSE_CONFIG, SEND_INTERVAL_MS, SAVE_INTERVAL_MS, Room } from "@/lib/houseConfig";
import { formatTimestamp, pushLiveData, pushLogData, listenToControl, type EnergyPayload } from "@/lib/firebase";

type SwitchState = Record<string, boolean>;

interface RoomEnergy {
  bedroom: number;
  livingRoom: number;
  kitchen: number;
}

export function useEnergySimulation(userId: string) {
  const [switches, setSwitches] = useState<SwitchState>(() => {
    const all: SwitchState = {};
    HOUSE_CONFIG.forEach((room) =>
      room.appliances.forEach((a) => (all[a.id] = false))
    );
    return all;
  });

  const [energy, setEnergy] = useState<RoomEnergy>(() => ({
    bedroom: parseFloat(localStorage.getItem(`energyBedroom_${userId}`) || "0"),
    livingRoom: parseFloat(localStorage.getItem(`energyLivingRoom_${userId}`) || "0"),
    kitchen: parseFloat(localStorage.getItem(`energyKitchen_${userId}`) || "0"),
  }));

  const [lastPush, setLastPush] = useState<string>("");
  const [firebaseStatus, setFirebaseStatus] = useState<"idle" | "sending" | "success" | "error">("idle");

  const switchesRef = useRef(switches);
  switchesRef.current = switches;

  const energyRef = useRef(energy);
  energyRef.current = energy;

  useEffect(() => {
    const unsubscribe = listenToControl(userId, (data) => {
      if (data) {
        setSwitches((prev) => {
          const next = { ...prev };
          if (data.bedroom !== undefined) {
             next['bedroom_led'] = data.bedroom;
             next['bedroom_fan'] = data.bedroom;
             next['bedroom_pc'] = data.bedroom;
          }
          if (data.lrLight !== undefined) {
             next['living_tube'] = data.lrLight;
          }
          if (data.lrTV !== undefined) {
             next['living_tv'] = data.lrTV;
          }
          if (data.kitchen !== undefined) {
             next['kitchen_led'] = data.kitchen;
             next['kitchen_fridge'] = data.kitchen;
             next['kitchen_oven'] = data.kitchen;
          }
          return next;
        });
      }
    });
    return () => unsubscribe();
  }, [userId]);

  const getRoomPower = useCallback(
    (room: Room): number =>
      room.appliances.reduce(
        (sum, a) => sum + (switchesRef.current[a.id] ? a.watts : 0),
        0
      ),
    []
  );

  const toggle = useCallback((id: string) => {
    setSwitches((prev) => ({ ...prev, [id]: !prev[id] }));
  }, []);

  const computePower = useCallback(() => {
    const bedroom = getRoomPower(HOUSE_CONFIG[0]);
    const livingRoom = getRoomPower(HOUSE_CONFIG[1]);
    const kitchen = getRoomPower(HOUSE_CONFIG[2]);
    return { bedroom, livingRoom, kitchen, total: bedroom + livingRoom + kitchen };
  }, [getRoomPower]);

  const pushDataToFirebase = useCallback(async (overrideEnergy?: RoomEnergy) => {
    const power = computePower();
    const now = new Date();
    const ts = formatTimestamp(now);
    
    const e = overrideEnergy || energyRef.current;
    
    const payload: EnergyPayload = {
      timestamp: ts,
      power: {
        bedroom: power.bedroom,
        livingRoom: power.livingRoom,
        kitchen: power.kitchen,
        total: power.total,
      },
      energy: {
        bedroom: parseFloat(e.bedroom.toFixed(6)),
        livingRoom: parseFloat(e.livingRoom.toFixed(6)),
        kitchen: parseFloat(e.kitchen.toFixed(6)),
      },
    };

    setFirebaseStatus("sending");
    try {
      await Promise.all([pushLiveData(userId, payload), pushLogData(userId, payload)]);
      setFirebaseStatus("success");
      setLastPush(ts);
    } catch (err) {
      console.error("Firebase push failed:", err);
      setFirebaseStatus("error");
    }
  }, [computePower]);

  const isInitialSwitchPushRef = useRef(true);

  useEffect(() => {
    if (isInitialSwitchPushRef.current) {
      isInitialSwitchPushRef.current = false;
      return;
    }
    console.log(`[useEnergySimulation] Switch changed. Pushing immediate update to Firebase...`);
    pushDataToFirebase();
  }, [switches, pushDataToFirebase]);

  // Energy accumulation + Firebase push every minute
  useEffect(() => {
    const interval = setInterval(() => {
      const power = computePower();

      // Accumulate energy: power_watts / 1000 * (1/60) = kWh per minute
      const dE = (w: number) => (w / 1000) * (1 / 60);

      const nextEnergy = {
        bedroom: energyRef.current.bedroom + dE(power.bedroom),
        livingRoom: energyRef.current.livingRoom + dE(power.livingRoom),
        kitchen: energyRef.current.kitchen + dE(power.kitchen),
      };

      setEnergy(nextEnergy);
      
      localStorage.setItem(`energyBedroom_${userId}`, nextEnergy.bedroom.toFixed(6));
      localStorage.setItem(`energyLivingRoom_${userId}`, nextEnergy.livingRoom.toFixed(6));
      localStorage.setItem(`energyKitchen_${userId}`, nextEnergy.kitchen.toFixed(6));

      console.log(`[useEnergySimulation] Periodic check: total power = ${power.total}W`);
      if (power.total > 0) {
        console.log(`[useEnergySimulation] Pushing periodic update to Firebase...`);
        pushDataToFirebase(nextEnergy);
      } else {
        console.log(`[useEnergySimulation] Skipping periodic update (all appliances OFF).`);
      }
      
    }, SEND_INTERVAL_MS);

    return () => clearInterval(interval);
  }, [computePower, pushDataToFirebase]);

  return { switches, toggle, energy, computePower, lastPush, firebaseStatus };
}
