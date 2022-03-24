import { createContext, useContext } from "react";
import { action, configure } from "mobx";
import { PersistStoreMap } from "mobx-persist-store";

import { enableLogging } from "mobx-logger";
import api from "./api";

// configure({
//   enforceActions: "always",
//   computedRequiresReaction: true,
//   reactionRequiresObservable: true,
//   observableRequiresReaction: true,
//   disableErrorBoundaries: true,
// });

import AppStore from "./stores/app";
import BoothStore from "./stores/booths";
import ShipStore from "./stores/ship";
import LogStore from "./stores/logs";
import ProposalStore from "./stores/proposals";
import ParticipantStore from "./stores/participants";
import VoteStore from "./stores/votes";
import BoothsApi from "./api/booths";
import ProposalsApi from "./api/proposals";
import ParticipantApi from "./api/participants";
import VotesAPI from "./api/votes";

import { ChannelResponseType, EffectType } from "./watcher";

const config = { compute: true, action: true, predicate: () => true };

// enableLogging(config);

export interface IStore {
  appStore: AppStore;
  boothStore: BoothStore;
  proposalStore: ProposalStore;
  participantStore: ParticipantStore;
  shipStore: ShipStore;
  logStore: LogStore;
  voteStore: VoteStore;
  onChannel: (data: any) => void;
}

export const store: IStore = {
  appStore: new AppStore(),
  shipStore: new ShipStore(),
  logStore: new LogStore(),
  participantStore: new ParticipantStore(ParticipantApi),
  boothStore: new BoothStore(BoothsApi),
  proposalStore: new ProposalStore(ProposalsApi),
  voteStore: new VoteStore(VotesAPI),
  onChannel: action((data: ChannelResponseType) => {
    console.log("data => ", data);
    if (data.response === "diff") {
      const responseJson = data.json;
      responseJson.effects.forEach((effect: EffectType) => {
        switch (effect.resource) {
          case "booth":
            store.boothStore.onEffect(
              effect,
              responseJson.context,
              responseJson.action
            );
            break;
          case "participant":
            store.participantStore.onEffect(
              effect,
              responseJson.context,
              responseJson.action
            );
            break;
          case "proposal":
            store.proposalStore.onEffect(
              effect,
              responseJson.context,
              responseJson.action
            );
            break;
          case "vote":
            store.voteStore.onEffect(
              effect,
              responseJson.context,
              responseJson.action
            );
            break;

          default:
            console.log("unknown effect", effect);
            break;
        }
      });
    }
  }),
};
export const StoreContext = createContext(store);

export const useStore = () => {
  return useContext(StoreContext);
};

// booth: {
//   boothKey: {
//     booth1: {
//     }
//   }
// }
// participants: {
//   boothKey: {
//     booth1: {
//     }
//   }
// proposal: {
//   boothKey: {
//     booth1: {
//     }
//   }
// }

// const response = {
//   action: "invite-effect",
//   resource: "booth",
//   key: "~zod",
//   effects: [
//     {
//       data: {
//         status: "pending",
//         name: "~bus",
//         key: "~bus",
//         created: "1647545311612",
//       },
//       effect: "add",
//       key: "~bus",
//       resource: "participant",
//     },
//   ],
// };

// const responseProposal = {
//   action: "add-proposal-effect",
//   resource: "proposal",
//   key: "~zod",
//   effects: [
//     {
//       data: {
//         status: "pending",
//         name: "~bus",
//         key: "~bus",
//         created: "1647545311612",
//       },
//       effect: "add",
//       key: "~bus",
//       resource: "participant",
//     },
//   ],
// };

// const responseParticipant = {
//   action: "invite-effect",
//   context: {
//     resource: "booth",
//     key: '~zod',
//   },
//   effects: [
//     {
//       data: {
//           status: "active",
//       },
//       effect: "update",
//       key: "~zod",
//       resource: "booth",
//     },
//     {
//       data: {
//           status: "pending",
//           name: "~bus",
//           key: "~bus",
//           created: "1647545311612",
//       },
//       effect: "add",
//       key: "~bus",
//       resource: "participant",
//     },
//   ],
// };

//   const settings = {
//     action: "-effect",
//     resource: "settings",
//     effect: [
//       {
//         effect: 'update',
//         resource: "settings",
//         key: 'muted',
//         data: { true}
//       }
//     ]
// }

//   {
//     settings: {
//       'do-not-disturb': false
//     }
//   }
