import { Zap, Wifi, WifiOff, Clock } from "lucide-react";

interface Props {
  totalWatts: number;
  totalEnergy: number;
  firebaseStatus: "idle" | "sending" | "success" | "error";
  lastPush: string;
}

export function PowerHeader({ totalWatts, totalEnergy, firebaseStatus, lastPush }: Props) {
  const kw = (totalWatts / 1000).toFixed(2);

  return (
    <div className="animate-slide-up">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <Zap className="h-5 w-5 text-primary" />
          </div>
        </div>

        <div className="flex items-center gap-6">
          {/* Power display */}
          <div className="text-right">
            <p className="text-3xl font-bold tabular-nums tracking-tight">
              {totalWatts}
              <span className="text-base font-normal text-muted-foreground ml-1">W</span>
            </p>
            <p className="text-xs text-muted-foreground tabular-nums">
              {kw} kW · {totalEnergy.toFixed(4)} kWh total
            </p>
          </div>

          {/* Firebase status */}
          <div className="flex flex-col items-center gap-1 min-w-[48px]">
            {firebaseStatus === "success" ? (
              <Wifi className="h-4 w-4 text-primary" />
            ) : firebaseStatus === "error" ? (
              <WifiOff className="h-4 w-4 text-destructive" />
            ) : firebaseStatus === "sending" ? (
              <Wifi className="h-4 w-4 text-muted-foreground animate-pulse" />
            ) : (
              <Clock className="h-4 w-4 text-muted-foreground" />
            )}
            <span className="text-[10px] text-muted-foreground capitalize">
              {firebaseStatus === "idle" ? "Waiting" : firebaseStatus}
            </span>
          </div>
        </div>
      </div>

      {lastPush && (
        <p className="mt-2 text-[11px] text-muted-foreground">
          Last push: {lastPush.replace("_", " ")}
        </p>
      )}
    </div>
  );
}
