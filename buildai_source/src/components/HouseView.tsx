import {
  Bed, Sofa, CookingPot, Zap, Droplets, Wifi, WifiOff, Clock,
  ArrowDownCircle, RefreshCw, Lightbulb, Fan, Monitor, Tv, Lamp, Flame, Refrigerator,
} from "lucide-react";
import { Switch } from "@/components/ui/switch";
import { Room } from "@/lib/houseConfig";

const applianceIconMap: Record<string, React.ElementType> = {
  Lightbulb, Fan, Monitor, Tv, Lamp, Flame, Refrigerator,
};

const roomMeta: Record<string, { icon: React.ElementType; color: string; bg: string }> = {
  bedroom:    { icon: Bed,        color: "#60a5fa", bg: "rgba(96,165,250,0.07)"  },
  livingRoom: { icon: Sofa,       color: "#4ade80", bg: "rgba(74,222,128,0.07)"  },
  kitchen:    { icon: CookingPot, color: "#fb923c", bg: "rgba(251,146,60,0.07)"  },
};

interface HouseViewProps {
  title: string;
  userId: string;
  rooms: Room[];
  switches: Record<string, boolean>;
  onToggle: (id: string) => void;
  power: { bedroom: number; livingRoom: number; kitchen: number; total: number };
  energy: { bedroom: number; livingRoom: number; kitchen: number };
  firebaseStatus: "idle" | "sending" | "success" | "error";
  lastPush: string;
  waterLevel: number;
  tankCapacity: number;
  outlets: { kitchen: boolean; washroom1: boolean; washroom2: boolean };
  refillOn: boolean;
  onToggleOutlet: (id: "kitchen" | "washroom1" | "washroom2") => void;
  onToggleRefill: () => void;
  waterFirebaseStatus: "idle" | "sending" | "success" | "error";
  waterLastPush: string;
}

export function HouseView({
  title,
  rooms,
  switches,
  onToggle,
  power,
  energy,
  firebaseStatus,
  lastPush,
  waterLevel,
  tankCapacity,
  outlets,
  refillOn,
  onToggleOutlet,
  onToggleRefill,
  waterFirebaseStatus,
  waterLastPush,
}: HouseViewProps) {
  const waterPct = Math.min(100, Math.max(0, (waterLevel / tankCapacity) * 100));
  const totalEnergy = energy.bedroom + energy.livingRoom + energy.kitchen;
  const anyOutletOn = outlets.kitchen || outlets.washroom1 || outlets.washroom2;
  const activeOutletsCount = Object.values(outlets).filter(Boolean).length;
  const waterFill      = waterPct < 20 ? "#ef4444" : waterPct < 50 ? "#f59e0b" : "#3b82f6";
  const waterFillLight = waterPct < 20 ? "#fca5a5" : waterPct < 50 ? "#fcd34d" : "#93c5fd";

  const syncIcon =
    firebaseStatus === "success" ? <Wifi className="h-3.5 w-3.5 text-green-400" /> :
    firebaseStatus === "error"   ? <WifiOff className="h-3.5 w-3.5 text-red-400" /> :
    firebaseStatus === "sending" ? <Wifi className="h-3.5 w-3.5 text-yellow-400 animate-pulse" /> :
                                   <Clock className="h-3.5 w-3.5 text-muted-foreground" />;

  const wallColor    = "hsl(222 30% 10%)";
  const borderColor  = "hsl(220 20% 24%)";
  const dividerColor = "hsl(220 20% 20%)";

  return (
    <div className="animate-slide-up select-none">

      {/* ── Title ── */}
      <div className="mb-4">
        <h2 className="text-xl font-bold tracking-tight" style={{ color: "hsl(220 10% 92%)" }}>{title}</h2>
      </div>

      {/* ══════════ THE HOUSE ══════════ */}
      <div>

        {/* ── TRIANGULAR ROOF ── */}
        <svg
          viewBox="0 0 900 160"
          className="w-full"
          style={{ display: "block", marginBottom: -2 }}
          preserveAspectRatio="none"
        >
          <defs>
            <linearGradient id={`roofGrad`} x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor="hsl(222 40% 18%)" />
              <stop offset="100%" stopColor="hsl(222 30% 13%)" />
            </linearGradient>
            <pattern id="roofTiles" x="0" y="0" width="40" height="20" patternUnits="userSpaceOnUse">
              <line x1="0" y1="20" x2="20" y2="0" stroke="rgba(255,255,255,0.04)" strokeWidth="1" />
              <line x1="20" y1="20" x2="40" y2="0" stroke="rgba(255,255,255,0.04)" strokeWidth="1" />
            </pattern>
          </defs>
          {/* Roof fill */}
          <polygon points="0,160 450,5 900,160" fill={`url(#roofGrad)`} />
          <polygon points="0,160 450,5 900,160" fill="url(#roofTiles)" />
          {/* Roof outline */}
          <polyline points="0,160 450,5 900,160" fill="none" stroke="hsl(220 20% 32%)" strokeWidth="2.5" />
          {/* Ridge cap */}
          <circle cx="450" cy="5" r="5" fill="hsl(220 20% 45%)" />
          {/* Eave line */}
          <line x1="0" y1="160" x2="900" y2="160" stroke="hsl(220 20% 30%)" strokeWidth="2" />
        </svg>

        {/* House body (flat roof + rooms) */}
        <div className="rounded-b-2xl overflow-hidden" style={{ border: `2px solid ${borderColor}`, borderTop: "none" }}>

        {/* ── ROOF SECTION: water tank + refill + outlet cards ── */}
        <div
          style={{ background: "hsl(222 36% 13%)", borderBottom: `2px solid ${borderColor}` }}
        >
          {/* Top row: tank left, refill right */}
          <div className="flex items-start gap-4 px-5 pt-4 pb-2">
            {/* Water tank */}
            <div
              className="relative rounded-lg border-2 overflow-hidden flex-shrink-0"
              style={{
                width: 150, height: 86,
                borderColor: waterFill,
                background: "hsl(222 40% 8%)",
                boxShadow: `0 0 20px ${waterFill}55`,
              }}
            >
              {/* Water fill bar */}
              <div
                className="absolute bottom-0 left-0 right-0 transition-all duration-700 ease-out"
                style={{ height: `${waterPct}%`, background: `linear-gradient(to top, ${waterFill}cc, ${waterFill}44)` }}
              >
                {(anyOutletOn || refillOn) && (
                  <div className="absolute inset-x-0 top-0 h-1 animate-pulse" style={{ background: `${waterFillLight}88` }} />
                )}
              </div>
              {/* Lid */}
              <div
                className="absolute top-0 left-0 right-0 h-7 flex items-center justify-center gap-1.5"
                style={{ background: "hsl(222 40% 13%)", borderBottom: `2px solid ${waterFill}` }}
              >
                <Droplets className="h-3.5 w-3.5" style={{ color: waterFill }} />
                <span className="text-[10px] font-bold uppercase tracking-widest" style={{ color: waterFill }}>
                  Water Tank
                </span>
              </div>
              {/* Level */}
              <div className="absolute top-7 bottom-0 left-0 right-0 flex flex-col items-center justify-center pointer-events-none">
                <span className="text-lg font-bold tabular-nums text-white drop-shadow">{waterLevel.toFixed(0)} L</span>
                <span className="text-[11px]" style={{ color: waterFillLight }}>{waterPct.toFixed(0)}%</span>
              </div>
            </div>

            {/* Refill control */}
            <div className="flex flex-col gap-2 flex-1 mt-1">
              <div
                className="flex items-center justify-between rounded-lg px-3 py-2.5 transition-all duration-200"
                style={{
                  background: refillOn ? "rgba(59,130,246,0.12)" : "hsl(220 20% 13%)",
                  border: `1.5px solid ${refillOn ? "rgba(59,130,246,0.45)" : dividerColor}`,
                }}
              >
                <div className="flex items-center gap-2">
                  <RefreshCw className="h-4 w-4 flex-shrink-0" style={{ color: refillOn ? "#60a5fa" : "hsl(220 10% 50%)" }} />
                  <div>
                    <p className="text-xs font-semibold leading-none" style={{ color: "hsl(220 10% 88%)" }}>Refill</p>
                    <p className="text-[10px] mt-0.5" style={{ color: "hsl(220 10% 65%)" }}>5 L/s fill</p>
                  </div>
                </div>
                <Switch checked={refillOn} onCheckedChange={onToggleRefill} />
              </div>
              {(anyOutletOn || refillOn) && (
                <p className="text-[10px] text-center" style={{ color: waterFillLight }}>
                  {anyOutletOn && refillOn ? `Net ${5 - activeOutletsCount} L/s` : anyOutletOn ? `−${activeOutletsCount} L/s draining` : "+5 L/s refilling"}
                </p>
              )}
            </div>
          </div>

          {/* Branching pipes + outlet cards */}
          <div className="px-4 pb-4">
            {/* SVG: vertical trunk from tank bottom, then horizontal bar, then 3 drops */}
            <svg
              viewBox="0 0 300 36"
              className="w-full"
              style={{ display: "block", overflow: "visible" }}
            >
              {/* Vertical trunk down from tank bottom */}
              <line x1="75" y1="0" x2="75" y2="16"
                stroke={anyOutletOn ? waterFill : "hsl(220 20% 28%)"}
                strokeWidth="2"
                style={{ transition: "stroke 0.4s" }}
              />
              {/* Horizontal distribution bar */}
              <line x1="50" y1="16" x2="250" y2="16"
                stroke={anyOutletOn ? waterFill : "hsl(220 20% 28%)"}
                strokeWidth="2"
                style={{ transition: "stroke 0.4s" }}
              />
              {/* Branch to Kitchen (left ~16%) */}
              <line x1="50" y1="16" x2="50" y2="36"
                stroke={outlets.kitchen ? waterFill : "hsl(220 20% 28%)"}
                strokeWidth="2"
                style={{ transition: "stroke 0.4s" }}
              />
              {/* Branch to Washroom 1 (center ~50%) */}
              <line x1="150" y1="16" x2="150" y2="36"
                stroke={outlets.washroom1 ? waterFill : "hsl(220 20% 28%)"}
                strokeWidth="2"
                style={{ transition: "stroke 0.4s" }}
              />
              {/* Branch to Washroom 2 (right ~83%) */}
              <line x1="250" y1="16" x2="250" y2="36"
                stroke={outlets.washroom2 ? waterFill : "hsl(220 20% 28%)"}
                strokeWidth="2"
                style={{ transition: "stroke 0.4s" }}
              />
              {/* Animated flow drops on active branches */}
              {outlets.kitchen && (
                <circle r="2.5" fill={waterFill} opacity="0.9">
                  <animateMotion dur="0.7s" repeatCount="indefinite" path="M 50 0 L 50 36" />
                </circle>
              )}
              {outlets.washroom1 && (
                <circle r="2.5" fill={waterFill} opacity="0.9">
                  <animateMotion dur="0.7s" repeatCount="indefinite" path="M 150 0 L 150 36" />
                </circle>
              )}
              {outlets.washroom2 && (
                <circle r="2.5" fill={waterFill} opacity="0.9">
                  <animateMotion dur="0.7s" repeatCount="indefinite" path="M 250 0 L 250 36" />
                </circle>
              )}
            </svg>

            {/* Three outlet cards side-by-side */}
            <div className="grid grid-cols-3 gap-2">
              {([
                { id: "kitchen",   label: "Kitchen"    },
                { id: "washroom1", label: "Washroom 1" },
                { id: "washroom2", label: "Washroom 2" },
              ] as const).map((outlet) => {
                const isOn = outlets[outlet.id];
                return (
                  <div
                    key={outlet.id}
                    className="flex flex-col items-center gap-1 rounded-lg px-2 py-2 transition-all duration-200"
                    style={{
                      background: isOn ? `${waterFill}18` : "hsl(220 20% 11%)",
                      border: `1.5px solid ${isOn ? `${waterFill}55` : dividerColor}`,
                    }}
                  >
                    <span
                      className="text-[10px] font-semibold text-center leading-tight"
                      style={{ color: isOn ? waterFillLight : "hsl(220 10% 50%)" }}
                    >
                      {outlet.label}
                    </span>
                    <Switch
                      checked={isOn}
                      onCheckedChange={() => onToggleOutlet(outlet.id)}
                      style={{ transform: "scale(0.7)", transformOrigin: "center" }}
                    />
                  </div>
                );
              })}
            </div>
          </div>
        </div>

        {/* ── HOUSE BODY: three rooms ── */}
        <div
          className="grid grid-cols-1 md:grid-cols-3"
          style={{ background: wallColor }}
        >
          {rooms.map((room, idx) => {
            const meta   = roomMeta[room.id] || roomMeta.bedroom;
            const RoomIcon = meta.icon;
            const roomPwr  = power[room.id as "bedroom" | "livingRoom" | "kitchen"];
            const roomEng  = energy[room.id as "bedroom" | "livingRoom" | "kitchen"];
            const isActive = roomPwr > 0;

            return (
              <div
                key={room.id}
                className={`flex flex-col transition-all duration-300 ${
                  idx < 2 ? "border-b-[2px] md:border-b-0 md:border-r-[2px]" : ""
                }`}
                style={{
                  background: isActive ? meta.bg : "transparent",
                  borderColor: dividerColor,
                  boxShadow: isActive ? `inset 0 0 40px ${meta.color}18` : "none",
                }}
              >
                {/* Colour strip top */}
                <div className="h-1" style={{ background: isActive ? meta.color : dividerColor }} />

                <div className="p-4 flex flex-col gap-3">
                  {/* Room header */}
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <div
                        className="flex h-7 w-7 items-center justify-center rounded-md"
                        style={{ background: isActive ? `${meta.color}22` : "hsl(220 20% 16%)", color: isActive ? meta.color : "hsl(220 10% 46%)" }}
                      >
                        <RoomIcon className="h-[14px] w-[14px]" />
                      </div>
                      <span className="text-xs font-bold uppercase tracking-widest" style={{ color: isActive ? meta.color : "hsl(220 10% 50%)" }}>
                        {room.name}
                      </span>
                    </div>
                    <div className="text-right">
                      <p className="text-sm font-bold tabular-nums" style={{ color: isActive ? meta.color : "hsl(220 10% 55%)" }}>
                        {roomPwr} W
                      </p>
                      <p className="text-[10px] text-muted-foreground tabular-nums">{roomEng.toFixed(4)} kWh</p>
                    </div>
                  </div>

                  {/* Divider */}
                  <div className="h-px" style={{ background: dividerColor }} />

                  {/* Appliances */}
                  <div className="space-y-2">
                    {room.appliances.map((a) => {
                      const AIcon = applianceIconMap[a.icon] || Lightbulb;
                      const isOn  = switches[a.id];
                      return (
                        <div
                          key={a.id}
                          className="flex items-center justify-between rounded-lg px-3 py-2 transition-all duration-200"
                          style={{
                            background: isOn ? `${meta.color}18` : "hsl(220 20% 13%)",
                            border:     `1px solid ${isOn ? meta.color + "44" : dividerColor}`,
                          }}
                        >
                          <div className="flex items-center gap-2">
                            <div
                              className="flex h-6 w-6 items-center justify-center rounded"
                              style={{ background: isOn ? `${meta.color}25` : "hsl(220 20% 17%)", color: isOn ? meta.color : "hsl(220 10% 46%)" }}
                            >
                              <AIcon className="h-3 w-3" />
                            </div>
                            <div>
                              <p className="text-[11px] font-medium leading-none" style={{ color: isOn ? "#ffffff" : "hsl(220 10% 80%)" }}>{a.name}</p>
                              <p className="text-[10px] mt-0.5" style={{ color: isOn ? meta.color : "hsl(220 10% 60%)" }}>
                                {a.watts}W{isOn ? " · On" : ""}
                              </p>
                            </div>
                          </div>
                          <Switch checked={isOn} onCheckedChange={() => onToggle(a.id)} />
                        </div>
                      );
                    })}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
        </div> {/* close inner house body */}
      </div>   {/* close outer house wrapper */}
    </div>
  );
}
