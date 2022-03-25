import {
  types,
  flow,
  Instance,
  SnapshotIn,
  getParent,
  destroy,
  SnapshotOut,
  IJsonPatch,
  applyPatch,
} from "mobx-state-tree";
import boothApi from "../api/booths";

import { LoaderModel } from "./common/loader";
import { ParticipantStore } from "./participants";
import { ProposalStore } from "./proposals";
import { Watcher } from "../watcher";
import { onChannel, rootStore } from "./root";
import { timeout } from "../utils/dev";
import { EffectModelType } from "./common/effects";

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
    loader: LoaderModel,
    proposalStore: ProposalStore,
    participantStore: ParticipantStore,
    actionLog: types.map(types.string),
  })
  .views((self) => ({
    get listProposals() {
      return Array.from(self.proposalStore.proposals.values());
    },
    get listParticipants() {
      return Array.from(self.participantStore.participants.values());
    },
    get hasAdmin(): boolean {
      // TODO use booth.permission (patrick fix)
      return self.owner === rootStore.app.ship.patp;
    },
    get isLoading() {
      return self.loader.isLoading;
    },
    get isLoaded() {
      return self.loader.isLoaded;
    },
    checkAction(action: string) {
      return self.actionLog.get(action);
    },
  }))
  .actions((self) => ({
    acceptInvite: flow(function* (boothKey: string) {
      try {
        const [response, error] = yield boothApi.acceptInvite(boothKey);
        if (error) throw error;
        self.actionLog.set(
          `${response.action}-${response.key}`,
          response.status
        );
      } catch (error) {
        self.loader.error(error.toString());
      }
    }),
    updateEffect(update: any) {
      console.log("updateEffect in booth ", update);

      const validKeys = Object.keys(update).filter((key: string) =>
        self.hasOwnProperty(key)
      );
      const patches: IJsonPatch[] = validKeys.map((key: string) => ({
        op: "replace",
        path: `/${key}`,
        value: update[key],
      }));
      applyPatch(self, patches);
    },
    remove(item: SnapshotIn<typeof self>) {
      destroy(item);
    },
  }));

export type BoothModelType = Instance<typeof BoothModel>;

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
    get isLoading() {
      return self.loader.isLoading;
    },
    get isLoaded() {
      return self.loader.isLoaded;
    },
  }))
  .actions((self) => ({
    getBooths: flow(function* () {
      self.loader.set("loading");
      yield timeout(1000); // for dev to simulate remote request
      try {
        const [response, error]: [BoothModelType[], any] =
          yield boothApi.getAll();
        if (error) throw error;
        self.loader.set("loaded");
        Object.values(response).forEach(async (booth: any) => {
          const newBooth = BoothModel.create({
            ...booth,
            meta: { ...booth.meta, color: "#000000" },
            proposalStore: ProposalStore.create({
              boothKey: booth.key,
            }),
            participantStore: ParticipantStore.create({
              boothKey: booth.key,
            }),
            loader: { state: "loaded" },
          });
          newBooth.proposalStore.getProposals();
          // Initialize booth store
          newBooth.participantStore.getParticipants();
          self.booths.set(newBooth.key, newBooth);
        });
        Watcher.initialize(Object.values(response), onChannel);
      } catch (error) {
        self.loader.error(error.toString());
      }
    }),
    setBooth(boothKey: string) {
      self.activeBooth = boothKey;
    },
    joinBooth(booth: SnapshotIn<typeof BoothModel>) {
      console.log("will join ", booth.name);
    },
    remove(item: SnapshotIn<typeof BoothModel>) {
      destroy(item);
    },
    //
    //
    //
    onEffect(payload: EffectModelType, context?: any, action?: string) {
      switch (payload.effect) {
        case "add":
          this.addEffect(payload.data);
          break;
        case "update":
          this.updateEffect(payload.key, payload.data);
          break;
        case "delete":
          this.deleteEffect(payload.key);
          break;
        case "initial":
          this.initialEffect(payload);
          break;
      }
    },
    initialEffect(payload: any) {
      // console.log("initialEffect ", payload);
      const { booth, participants, proposals, votes } = payload.data;
      self.booths.set(
        booth.key,
        BoothModel.create({
          ...booth,
          meta: { ...booth.meta, color: "#000000" },
          proposalStore: ProposalStore.create({
            boothKey: booth.key,
          }),
          participantStore: ParticipantStore.create({
            boothKey: booth.key,
          }),
          loader: { state: "loaded" },
        })
      );
      const initialBooth = self.booths.get(booth.key)!;
      initialBooth.participantStore.initialEffect(participants);
      initialBooth.proposalStore.initialEffect(proposals, votes);
    },
    addEffect(booth: any) {
      // console.log("addEffect ", booth);
      self.booths.set(
        booth.key,
        BoothModel.create({
          ...booth,
          meta: { ...booth.meta, color: "#000000" },
          proposalStore: ProposalStore.create({
            boothKey: booth.key,
          }),
          participantStore: ParticipantStore.create({
            boothKey: booth.key,
          }),
          loader: { state: "loaded" },
        })
      );
    },
    updateEffect(key: string, data: any) {
      console.log("booth updateEffect ", key, data);
      const oldBooth = self.booths.get(data.key);
      oldBooth?.updateEffect(data);
    },
    deleteEffect(boothKey: string) {
      console.log("booth deleteEffect ", boothKey);
      const deleted = self.booths.get(boothKey)!;
      destroy(deleted);
      self.booths.delete(boothKey);
    },
  }));
