import { Room } from "@/lib/houseConfig";
import { ApplianceToggle } from "./ApplianceToggle";
import { Bed, Sofa, CookingPot } from "lucide-react";

const roomIcons: Record<string, React.ElementType> = {
  bedroom: Bed,
  livingRoom: Sofa,
  kitchen: CookingPot,
};

const roomColors: Record<string, string> = {
  bedroom: "from-[hsl(var(--room-bedroom))]",
  livingRoom: "from-[hsl(var(--room-living))]",
  kitchen: "from-[hsl(var(--room-kitchen))]",
};

interface Props {
  room: Room;
  switches: Record<string, boolean>;
  onToggle: (id: string) => void;
  powerWatts: number;
  energyKwh: number;
  isHighest: boolean;
  delay: number;
}

export function RoomCard({ room, switches, onToggle, powerWatts, energyKwh, isHighest, delay }: Props) {
  const Icon = roomIcons[room.id] || Bed;

  return (
    <div
      className="animate-slide-up rounded-xl border border-border bg-card shadow-sm overflow-hidden"
      style={{ animationDelay: `${delay}ms` }}
    >
      {/* Header strip */}
      <div className={`h-1.5 bg-gradient-to-r ${roomColors[room.id]} to-transparent`} />

      <div className="p-5">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2.5">
            <Icon className="h-5 w-5 text-muted-foreground" />
            <h2 className="text-base font-semibold">{room.name}</h2>
            {isHighest && powerWatts > 0 && (
              <span className="rounded-full bg-accent/15 px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wider text-accent">
                Highest
              </span>
            )}
          </div>
          <div className="text-right">
            <p className="text-lg font-bold tabular-nums">{powerWatts}W</p>
          </div>
        </div>

        <div className="space-y-2.5">
          {room.appliances.map((a) => (
            <ApplianceToggle
              key={a.id}
              appliance={a}
              isOn={switches[a.id]}
              onToggle={() => onToggle(a.id)}
            />
          ))}
        </div>
      </div>
    </div>
  );
}
