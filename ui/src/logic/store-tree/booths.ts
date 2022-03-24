import {
  types,
  flow,
  Instance,
  SnapshotIn,
  getParent,
  destroy,
  SnapshotOut,
} from "mobx-state-tree";
import boothApi from "../api/booths";
import proposalsApi from "../api/proposals";
import participantApi from "../api/participants";

import { LoaderModel } from "./common/loader";
import { ParticipantModel } from "./participants";
import { ProposalModel } from "./proposals";
import { ChannelResponseType, EffectType, Watcher } from "../watcher";

export const BoothModel = types
  .model({
    key: types.identifier,
    created: types.string,
    image: types.maybeNull(types.string),
    meta: types.map(types.maybeNull(types.string)),
    name: types.string,
    owner: types.string,
    type: types.enumeration("Type", ["group", "ship"]),
    permission: types.maybeNull(
      types.enumeration("Permission", ["owner", "admin", "member", "viewer"])
    ),
    status: types.enumeration("State", [
      "pending",
      "invited",
      "error",
      "active",
    ]),
    loader: types.optional(LoaderModel, { state: "initial" }),
    participantLoader: types.optional(LoaderModel, { state: "initial" }),
    proposals: types.map(ProposalModel),
    participants: types.map(ParticipantModel),
  })
  .views((self) => ({
    get listProposals() {
      return Array.from(self.proposals.values());
    },
    get listParticipants() {
      return Array.from(self.participants.values());
    },
    get hasAdmin() {
      return self.permission === "owner";
    },
  }))
  .actions((self) => ({
    acceptInvite: flow(function* (boothKey: string) {
      try {
        const [response, error] = yield boothApi.acceptInvite(boothKey);
        if (error) throw error;
        self.status = "pending";
        // this.actions[`${response.action}-${response.key}`] = response.status;
      } catch (error) {
        self.loader.error(error.toString());
      }
    }),
    getProposals: flow(function* () {
      self.loader.set("loading");
      try {
        const [response, error] = yield proposalsApi.getAll(self.key);
        if (error) throw error;
        self.loader.set("loaded");
        response.forEach((proposal: any) => {
          proposal.redacted = false; // todo fix this on backend
          const newProposal = ProposalModel.create(proposal);
          self.proposals.set(newProposal.key, newProposal);
        });
      } catch (error) {
        self.loader.error(error.toString());
      }
    }),
    getParticipants: flow(function* () {
      self.participantLoader.set("loading");
      try {
        const [response, error] = yield participantApi.getParticipants(
          self.key
        );
        if (error) throw error;
        self.participantLoader.set("loaded");
        response.forEach((participant: any) => {
          const newParticipant = ParticipantModel.create(participant);
          self.participants.set(newParticipant.key, newParticipant);
        });
      } catch (error) {
        self.participantLoader.error(error.toString());
      }
    }),
    remove(item: SnapshotIn<typeof self>) {
      destroy(item);
    },
  }));

export type BoothType2 = typeof BoothModel.properties;

export const BoothStore = types
  .model({
    loader: types.optional(LoaderModel, { state: "initial" }),
    booths: types.map(BoothModel),
    activeBooth: types.optional(types.string, ""),
  })
  .views((self) => ({
    get list() {
      return Array.from(self.booths.values());
    },
    get booth() {
      return self.booths.get(self.activeBooth);
    },
  }))
  .actions((self) => ({
    getBooths: flow(function* () {
      console.log("getting booths");
      try {
        const [response, error]: [BoothType2[], any] = yield boothApi.getAll();
        if (error) throw error;
        self.loader.set("loaded");
        response.forEach((booth: any) => {
          const newBooth = BoothModel.create(booth);
          newBooth.getProposals();
          newBooth.getParticipants();
          self.booths.set(newBooth.key, newBooth);
        });
        Watcher.initialize(response, onChannel);
      } catch (error) {
        self.loader.error(error.toString());
      }
    }),
    setBooth(booth: Instance<typeof BoothModel>) {
      self.activeBooth = booth.key;
    },
    joinBooth(booth: SnapshotIn<typeof BoothModel>) {
      console.log("will join ", booth.name);
    },
    remove(item: SnapshotIn<typeof BoothModel>) {
      destroy(item);
    },
  }));

interface IBooth extends Instance<typeof BoothModel> {}
interface IBoothSnapshotIn extends SnapshotIn<typeof BoothModel> {}
interface IBoothSnapshotOut extends SnapshotOut<typeof BoothModel> {}

function onChannel(data: ChannelResponseType) {
  console.log("data => ", data);
  if (data.response === "diff") {
    const responseJson = data.json;
    responseJson.effects.forEach((effect: EffectType) => {
      switch (effect.resource) {
        case "booth":
          // store.boothStore.onEffect(
          //   effect,
          //   responseJson.context,
          //   responseJson.action
          // );
          break;
        case "participant":
          // store.participantStore.onEffect(
          //   effect,
          //   responseJson.context,
          //   responseJson.action
          // );
          break;
        case "proposal":
          // store.proposalStore.onEffect(
          //   effect,
          //   responseJson.context,
          //   responseJson.action
          // );
          break;
        case "vote":
          // store.voteStore.onEffect(
          //   effect,
          //   responseJson.context,
          //   responseJson.action
          // );
          break;

        default:
          console.log("unknown effect", effect);
          break;
      }
    });
  }
}
