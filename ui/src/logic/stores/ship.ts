import api from "../api";
import { makeAutoObservable, action } from "mobx";
import { makePersistable } from "mobx-persist-store";

export type ShipType = {
  patp: string;
  metadata?: {
    color: string;
  };
};

class ShipStore {
  public ship?: ShipType = {
    patp: `~${api.ship}`,
    metadata: {
      color: "#000000", // TODO get from metadata store
    },
  };

  constructor() {
    makeAutoObservable(this);
    makePersistable(this, {
      name: "ShipStore",
      properties: ["ship"],
      storage: window.localStorage,
    });
  }

  setShip = action((ship: ShipType) => {
    this.ship = ship;
  });
}

export default ShipStore;
