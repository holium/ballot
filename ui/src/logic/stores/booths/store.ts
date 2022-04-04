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
import boothApi from "../../api/booths";
import { timeout } from "../../utils/dev";
import { BoothModel, BoothModelType } from "./";
import { EffectModelType } from "../common/effects";
import { LoaderModel } from "../common/loader";
import { ParticipantStore } from "../participants";
import { ProposalStore } from "../proposals";

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
    get ships() {
      return Array.from(self.booths.values()).filter(
        (booth: BoothModelType) => booth.type === "ship"
      );
    },
    get groups() {
      return Array.from(self.booths.values()).filter(
        (booth: BoothModelType) => booth.type === "group"
      );
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

          newBooth.isActive && newBooth.proposalStore.getProposals();
          // Initialize booth store
          newBooth.isActive && newBooth.participantStore.getParticipants();
          self.booths.set(newBooth.key, newBooth);
        });
      } catch (err: any) {
        self.loader.error(err);
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
    onEffect(payload: EffectModelType, context?: any) {
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
      const { booth, participants, proposals, votes } = payload.data;
      self.booths.set(
        booth.key,
        BoothModel.create({
          ...booth,
          meta: { ...booth.meta, color: "#000000" },
          proposalStore: ProposalStore.create({
            boothKey: booth.key,
            loader: { state: "loaded" },
          }),
          participantStore: ParticipantStore.create({
            boothKey: booth.key,
            loader: { state: "loaded" },
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
      const oldBooth = self.booths.get(key);
      console.log(oldBooth);
      oldBooth?.updateEffect(data);
    },
    deleteEffect(boothKey: string) {
      console.log("booth deleteEffect ", boothKey);

      self.booths.delete(boothKey);
    },
  }));
