import { types, Instance } from "mobx-state-tree";
const defaultUrl = import.meta.env.VITE_SHIP_URL?.toString() || "";

const ShipModel = types
  .model({
    cookie: types.maybe(types.string),
    patp: types.maybe(types.string),
    baseUrl: types.string,
    channelId: types.string,
    metadata: types.optional(
      types.model({
        color: types.string,
      }),
      { color: "#000000" }
    ),
  })
  .views((self) => ({
    get ship() {
      if (!window.ship) {
        location.href = `${self.baseUrl}/~/login?redirect=${location.href}`;
      }
      return self.patp;
    },
  }))
  .actions((self) => ({
    setShip(patp: string) {
      self.patp = patp;
    },
  }));

export type ShipModelType = Instance<typeof ShipModel>;

const shipStore = ShipModel.create({
  baseUrl: defaultUrl,
  cookie: document.cookie,
  patp: window.ship,
  channelId: [
    Date.now(),
    "",
    Math.floor(Math.random() * Number.MAX_SAFE_INTEGER),
  ]
    .toString()
    .replaceAll(",", ""),
});

export default shipStore;
