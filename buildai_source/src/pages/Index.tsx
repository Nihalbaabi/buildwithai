import { HOUSE_CONFIG } from "@/lib/houseConfig";
import { useEnergySimulation } from "@/hooks/useEnergySimulation";
import { useWaterTank } from "@/hooks/useWaterTank";
import { HouseView } from "@/components/HouseView";

const HomeSimulation = ({ userId, title }: { userId: string; title: string }) => {
  const { switches, toggle, energy, computePower, lastPush, firebaseStatus } =
    useEnergySimulation(userId);
  const power = computePower();
  const water = useWaterTank(userId);

  return (
    <HouseView
      title={title}
      userId={userId}
      rooms={HOUSE_CONFIG}
      switches={switches}
      onToggle={toggle}
      power={power}
      energy={energy}
      firebaseStatus={firebaseStatus}
      lastPush={lastPush}
      waterLevel={water.waterLevel}
      tankCapacity={water.tankCapacity}
      outlets={water.outlets}
      refillOn={water.refillOn}
      onToggleOutlet={water.toggleOutlet}
      onToggleRefill={water.toggleRefill}
      waterFirebaseStatus={water.firebaseStatus}
      waterLastPush={water.lastPush}
    />
  );
};

const Index = () => {
  return (
    <div className="min-h-screen px-4 py-8 sm:px-6 lg:px-8" style={{ background: "hsl(222 40% 6%)" }}>
      <div className="mx-auto max-w-2xl space-y-14">
        <div className="text-center pt-2 space-y-1">
          <h1 className="text-4xl font-extrabold tracking-tight lg:text-5xl" style={{ color: "hsl(220 10% 92%)" }}>
            Home Simulation
          </h1>
          <p className="text-sm text-muted-foreground">
            Real-time energy & water monitoring · Firebase synced
          </p>
        </div>

        <div className="grid gap-12 grid-cols-1">
          <div
            className="rounded-2xl p-6"
            style={{ background: "hsl(222 36% 9%)", border: "2px solid hsl(220 20% 18%)" }}
          >
            <HomeSimulation userId="user1" title="User 1 — Home" />
          </div>
          <div
            className="rounded-2xl p-6"
            style={{ background: "hsl(222 36% 9%)", border: "2px solid hsl(220 20% 18%)" }}
          >
            <HomeSimulation userId="user2" title="User 2 — Home" />
          </div>
        </div>


      </div>
    </div>
  );
};

export default Index;
