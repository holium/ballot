import { Instance, onSnapshot, types } from "mobx-state-tree";
import { createContext, useContext } from "react";
import { AppModel } from "./app";
import { BoothStore } from "./booths";
import { MetadataModel } from "./metadata";
import { ChannelResponseModelType, EffectModelType } from "./common/effects";
import { BaseWatcher } from "../watcher";

import ShipModel from "./ship";

const BallotWatcher = new BaseWatcher();
BallotWatcher.initialize("ballot", "/booths", onChannel);

const RootModel = types.model("RootStore", {
  store: BoothStore,
  app: AppModel,
  metadata: MetadataModel,
});

const initialState = RootModel.create({
  store: {}, // todo a smooth way to handle data persisting and getting new data without a bunch of loading
  app: loadRootSnapshot("app"),
  metadata: {},
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

function loadRootSnapshot(storeName: string) {
  const rootState = localStorage.getItem("rootState");
  if (rootState) {
    return JSON.parse(rootState)[storeName];
  }
  return {
    title: "Ballot",
    theme: "light",
    ship: {
      patp: `~${ShipModel.patp!}`,
    },
  };
}

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
        if (participantBooth) {
          participantBooth.participantStore.onEffect(effect, context);
        }
        break;
      case "delegate":
        const delegateBooth = rootStore.store.booths.get(context.booth!)!;
        if (delegateBooth) {
          delegateBooth.delegateStore.onEffect(effect, context);
        }
        break;
      case "proposal":
        const proposalBooth = rootStore.store.booths.get(
          responseJson.context.booth!
        )!;
        if (proposalBooth) {
          proposalBooth.proposalStore.onEffect(effect, context, action);
        }
        break;
      // case "poll":
      //   const proposalPollBooth = rootStore.store.booths.get(
      //     responseJson.context.booth!
      //   )!;
      //   if (proposalPollBooth)
      //     proposalPollBooth.proposalStore.onPollEffect(
      //       effect,
      //       context.proposal!
      //     );
      //   break;
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
