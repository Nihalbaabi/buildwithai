import { Droplets, Wifi, WifiOff, Clock, ArrowDownCircle, RefreshCw } from "lucide-react";
import { Switch } from "@/components/ui/switch";

interface Props {
  waterLevel: number;
  tankCapacity: number;
  outletOn: boolean;
  refillOn: boolean;
  onToggleOutlet: () => void;
  onToggleRefill: () => void;
  firebaseStatus: "idle" | "sending" | "success" | "error";
  lastPush: string;
}

export function WaterTankCard({
  waterLevel,
  tankCapacity,
  outletOn,
  refillOn,
  onToggleOutlet,
  onToggleRefill,
  firebaseStatus,
  lastPush,
}: Props) {
  const pct = Math.min(100, Math.max(0, (waterLevel / tankCapacity) * 100));

  // Water fill colour: red → amber → blue as level rises
  const fillColor =
    pct < 20
      ? "from-red-500 to-red-400"
      : pct < 50
      ? "from-amber-500 to-amber-400"
      : "from-blue-500 to-cyan-400";

  const statusIcon =
    firebaseStatus === "success" ? (
      <Wifi className="h-4 w-4 text-blue-500" />
    ) : firebaseStatus === "error" ? (
      <WifiOff className="h-4 w-4 text-destructive" />
    ) : firebaseStatus === "sending" ? (
      <Wifi className="h-4 w-4 text-muted-foreground animate-pulse" />
    ) : (
      <Clock className="h-4 w-4 text-muted-foreground" />
    );

  return (
    <div className="animate-slide-up rounded-xl border border-border bg-card shadow-sm overflow-hidden">
      {/* Header strip */}
      <div className="h-1.5 bg-gradient-to-r from-blue-500 to-cyan-400 to-transparent" />

      <div className="p-5 space-y-5">
        {/* Title row */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2.5">
            <Droplets className="h-5 w-5 text-blue-500" />
            <h2 className="text-base font-semibold">Water Tank</h2>
          </div>
          <div className="flex items-center gap-2">
            {statusIcon}
            <span className="text-[10px] text-muted-foreground capitalize">
              {firebaseStatus === "idle" ? "Waiting" : firebaseStatus}
            </span>
          </div>
        </div>

        {/* Tank visualisation */}
        <div className="flex items-end gap-4">
          {/* Tank bar */}
          <div className="relative flex-1 h-28 rounded-lg bg-muted overflow-hidden border border-border">
            <div
              className={`absolute bottom-0 left-0 right-0 bg-gradient-to-t ${fillColor} transition-all duration-700 ease-out`}
              style={{ height: `${pct}%` }}
            >
              {/* animated ripple */}
              {(outletOn || refillOn) && (
                <div className="absolute inset-x-0 top-0 h-1 bg-white/30 animate-pulse" />
              )}
            </div>
            {/* Level label inside bar */}
            <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
              <span className="text-xl font-bold tabular-nums text-foreground drop-shadow">
                {waterLevel.toFixed(1)}
              </span>
              <span className="text-xs text-muted-foreground">L</span>
            </div>
          </div>

          {/* Stats */}
          <div className="space-y-1 text-right">
            <p className="text-2xl font-bold tabular-nums tracking-tight">
              {pct.toFixed(0)}
              <span className="text-sm font-normal text-muted-foreground ml-0.5">%</span>
            </p>
            <p className="text-xs text-muted-foreground">of {tankCapacity} L</p>
            {outletOn && (
              <p className="text-[11px] text-red-500 font-medium">−1 L/s draining</p>
            )}
            {refillOn && (
              <p className="text-[11px] text-blue-500 font-medium">+5 L/sec refilling</p>
            )}
          </div>
        </div>

        {/* Controls */}
        <div className="space-y-2.5">
          {/* Outlet switch */}
          <div
            className={`flex items-center justify-between rounded-lg border px-4 py-3 transition-all duration-200 ${
              outletOn
                ? "border-red-400/40 bg-red-500/5 shadow-sm"
                : "border-border bg-card"
            }`}
          >
            <div className="flex items-center gap-3">
              <div
                className={`flex h-9 w-9 items-center justify-center rounded-md transition-colors duration-200 ${
                  outletOn ? "bg-red-500/15 text-red-500" : "bg-muted text-muted-foreground"
                }`}
              >
                <ArrowDownCircle className="h-[18px] w-[18px]" />
              </div>
              <div>
                <p className="text-sm font-medium leading-none">Outlet Switch</p>
                <p className="mt-1 text-xs text-muted-foreground">
                  1 L/sec drain{outletOn ? " · Active" : ""}
                </p>
              </div>
            </div>
            <Switch checked={outletOn} onCheckedChange={onToggleOutlet} />
          </div>

          {/* Refill switch */}
          <div
            className={`flex items-center justify-between rounded-lg border px-4 py-3 transition-all duration-200 ${
              refillOn
                ? "border-blue-400/40 bg-blue-500/5 shadow-sm"
                : "border-border bg-card"
            }`}
          >
            <div className="flex items-center gap-3">
              <div
                className={`flex h-9 w-9 items-center justify-center rounded-md transition-colors duration-200 ${
                  refillOn ? "bg-blue-500/15 text-blue-500" : "bg-muted text-muted-foreground"
                }`}
              >
                <RefreshCw className="h-[18px] w-[18px]" />
              </div>
              <div>
                <p className="text-sm font-medium leading-none">Refill Switch</p>
                <p className="mt-1 text-xs text-muted-foreground">
                  5 L/sec refill{refillOn ? " · Active" : ""}
                </p>
              </div>
            </div>
            <Switch checked={refillOn} onCheckedChange={onToggleRefill} />
          </div>
        </div>

        {lastPush && (
          <p className="text-[11px] text-muted-foreground">
            Last push: {lastPush.replace("_", " ")}
          </p>
        )}
      </div>
    </div>
  );
}
