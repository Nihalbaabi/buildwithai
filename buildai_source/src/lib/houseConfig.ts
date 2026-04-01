export interface Appliance {
  id: string;
  name: string;
  watts: number;
  icon: string;
}

export interface Room {
  id: "bedroom" | "livingRoom" | "kitchen";
  name: string;
  appliances: Appliance[];
}

export const HOUSE_CONFIG: Room[] = [
  {
    id: "bedroom",
    name: "Bedroom",
    appliances: [
      { id: "bedroom_led", name: "LED Bulb", watts: 15, icon: "Lightbulb" },
      { id: "bedroom_fan", name: "Ceiling Fan", watts: 75, icon: "Fan" },
      { id: "bedroom_pc", name: "Computer", watts: 200, icon: "Monitor" },
    ],
  },
  {
    id: "livingRoom",
    name: "Living Room",
    appliances: [
      { id: "living_tv", name: "Television", watts: 150, icon: "Tv" },
      { id: "living_tube", name: "Tube Light", watts: 20, icon: "Lamp" },
    ],
  },
  {
    id: "kitchen",
    name: "Kitchen",
    appliances: [
      { id: "kitchen_fridge", name: "Fridge", watts: 300, icon: "Refrigerator" },
      { id: "kitchen_oven", name: "Oven", watts: 1200, icon: "Flame" },
      { id: "kitchen_led", name: "LED Bulb 2", watts: 20, icon: "Lightbulb" },
    ],
  },
];

export const SEND_INTERVAL_MS = 60000;
export const SAVE_INTERVAL_MS = 60000;
export const DEBOUNCE_MS = 50;
