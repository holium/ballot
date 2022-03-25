import { Instance, onSnapshot, types } from "mobx-state-tree";
import { createContext, useContext } from "react";
import { AppModel } from "./app";
import { BoothStore } from "./booths";
import urbitApi from "../api";
import { ChannelResponseModelType, EffectModelType } from "./common/effects";

const RootModel = types.model("RootStore", {
  // boothsTree: types.optional(BoothStore, { loader: { state: "initial" } }),
  store: BoothStore,
  app: AppModel,
});

let initialState = RootModel.create({
  store: {},
  app: {
    ship: {
      patp: `~${urbitApi.ship!}`,
    },
  },
});

// if (process.browser) {
//   const data = localStorage.getItem("rootState");
//   if (data) {
//     const json = JSON.parse(data);
//     if (RootModel.is(json)) {
//       initialState = RootModel.create(json);
//     }
//   }
// }

export const rootStore = initialState;

onSnapshot(rootStore, (snapshot) => {
  console.log("Snapshot: ", snapshot);
  localStorage.setItem("rootState", JSON.stringify(snapshot));
});

export type RootInstance = Instance<typeof RootModel>;
const RootStoreContext = createContext<null | RootInstance>(rootStore);

export const Provider = RootStoreContext.Provider;
export function useMst() {
  const store = useContext(RootStoreContext);
  if (store === null) {
    throw new Error("Store cannot be null, please add a context provider");
  }
  return store;
}

export function onChannel(data: ChannelResponseModelType) {
  console.log("data => ", data);
  if (data.response === "diff") {
    const responseJson = data.json;
    responseJson.effects.forEach((effect: EffectModelType) => {
      switch (effect.resource) {
        case "booth":
          rootStore.store.onEffect(
            effect,
            responseJson.context,
            responseJson.action
          );
          break;
        case "participant":
          const participantBooth = rootStore.store.booths.get(
            responseJson.context.booth!
          )!;
          participantBooth.participantStore.onEffect(
            effect,
            responseJson.context,
            responseJson.action
          );
          break;
        case "proposal":
          const proposalBooth = rootStore.store.booths.get(
            responseJson.context.booth!
          )!;
          proposalBooth.proposalStore.onEffect(
            effect,
            responseJson.context,
            responseJson.action
          );
          break;
        case "vote":
          const voteBooth = rootStore.store.booths.get(
            responseJson.context.booth!
          )!;
          const voteStore = voteBooth.proposalStore.proposals?.get(
            responseJson.context.proposal!
          );
          // voteStore.onEffect(effect, responseJson.context, responseJson.action);
          break;
        default:
          console.log("unknown effect", effect);
          break;
      }
    });
  }
}
