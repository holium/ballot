import ShipAPI from "../api";
import { Instance, onSnapshot, types } from "mobx-state-tree";
import { createContext, useContext } from "react";
import { AppModel } from "./app";
import { BoothStore } from "./booths";
import { ChannelResponseModelType, EffectModelType } from "./common/effects";
import { toJS } from "mobx";
import { Watcher } from "../watcher";

import ShipModel from "./ship";

Watcher.initialize("ballot", "/booths", onChannel);

const RootModel = types.model("RootStore", {
  store: BoothStore,
  app: AppModel,
});

let initialState = RootModel.create({
  store: {},
  app: {
    ship: {
      patp: `~${ShipModel.patp!}`,
    },
  },
});

// // @ts-ignore
// if (process.browser) {
// const data = localStorage.getItem("rootState");
// if (data) {
//   const json = JSON.parse(data);
//   if (RootModel.is(json)) {
//     // @ts-ignore
//     initialState = RootModel.create(json);
//   }
// }
// }

export const rootStore = initialState;

onSnapshot(rootStore, (snapshot) => {
  // console.log("Snapshot: ", snapshot);
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
      const { context, action } = responseJson;
      console.log(`action ${action} is processing effect`);
      switch (effect.resource) {
        case "booth":
          rootStore.store.onEffect(effect, context);
          break;
        case "participant":
          const participantBooth = rootStore.store.booths.get(context.booth!)!;
          if (participantBooth)
            participantBooth.participantStore.onEffect(effect, context);
          break;
        case "proposal":
          const proposalBooth = rootStore.store.booths.get(
            responseJson.context.booth!
          )!;
          if (proposalBooth)
            proposalBooth.proposalStore.onEffect(effect, context);
          break;
        case "vote":
          const voteBooth = rootStore.store.booths.get(context.booth!)!;
          const voteProposal = voteBooth.proposalStore.proposals?.get(
            context.proposal!
          )!;

          voteProposal?.onVoteEffect(effect, context);
          break;
        default:
          console.log("unknown effect", effect);
          break;
      }
    });
  }
}
