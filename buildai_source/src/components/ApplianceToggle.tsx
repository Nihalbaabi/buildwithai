import { Switch } from "@/components/ui/switch";
import { Appliance } from "@/lib/houseConfig";
import { Lightbulb, Fan, Monitor, Tv, Lamp, Flame, Refrigerator } from "lucide-react";

const iconMap: Record<string, React.ElementType> = {
  Lightbulb, Fan, Monitor, Tv, Lamp, Flame, Refrigerator,
};

interface Props {
  appliance: Appliance;
  isOn: boolean;
  onToggle: () => void;
}

export function ApplianceToggle({ appliance, isOn, onToggle }: Props) {
  const Icon = iconMap[appliance.icon] || Lightbulb;

  return (
    <div
      className={`flex items-center justify-between rounded-lg border px-4 py-3 transition-all duration-200 ${
        isOn
          ? "border-primary/30 bg-primary/5 shadow-sm"
          : "border-border bg-card"
      }`}
    >
      <div className="flex items-center gap-3">
        <div
          className={`flex h-9 w-9 items-center justify-center rounded-md transition-colors duration-200 ${
            isOn ? "bg-primary/15 text-primary" : "bg-muted text-muted-foreground"
          }`}
        >
          <Icon className="h-4.5 w-4.5" />
        </div>
        <div>
          <p className="text-sm font-medium leading-none">{appliance.name}</p>
          <p className="mt-1 text-xs text-muted-foreground">
            {appliance.watts}W{isOn ? " · Active" : ""}
          </p>
        </div>
      </div>
      <Switch checked={isOn} onCheckedChange={onToggle} />
    </div>
  );
}
