import {
  ContactMetadataModel,
  ContactModelType,
  GroupMetadataModel,
} from "./../metadata";
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
  clone,
} from "mobx-state-tree";
import boothApi from "../../api/booths";
import { timeout } from "../../utils/dev";
import { BoothModel, BoothModelType } from "./";
import { EffectModelType } from "../common/effects";
import { LoaderModel } from "../common/loader";
import { ParticipantStore } from "../participants";
import { ProposalStore } from "../proposals";
import { toJS } from "mobx";
import { GroupModelType } from "../metadata";
import { rootStore } from "../root";
import { DelegateStore } from "../delegates";

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
    setGroupMetadata: (boothKey: string, metadata: GroupModelType) => {
      const booth = self.booths.get(boothKey)!;
      booth &&
        metadata &&
        booth.setGroupMetadata(GroupMetadataModel.create(metadata));
    },
    setShipMetadata: (boothKey: string, metadata: ContactModelType) => {
      const booth = self.booths.get(boothKey)!;
      booth &&
        metadata &&
        booth.setShipMetadata(ContactMetadataModel.create(metadata));
    },
    getBooths: flow(function* () {
      self.loader.set("loading");
      // yield timeout(1000); // for dev to simulate remote request
      try {
        const [response, error]: [BoothModelType[], any] =
          yield boothApi.getAll();
        if (error) throw error;
        self.loader.set("loaded");
        Object.values(response).forEach(async (booth: any) => {
          // a hacky way to remove dms for now
          if (!booth.key.includes("dm--")) {
            const newBooth = BoothModel.create({
              ...booth,
              meta: {
                ...booth.meta,
                color: "#000000",
              },
              proposalStore: ProposalStore.create({
                boothKey: booth.key,
              }),
              participantStore: ParticipantStore.create({
                boothKey: booth.key,
              }),
              delegateStore: DelegateStore.create({
                boothKey: booth.key,
              }),
              loader: { state: "loaded" },
            });

            newBooth.isActive && newBooth.proposalStore.getProposals();
            // Initialize booth store
            newBooth.isActive && newBooth.participantStore.getParticipants();
            newBooth.isActive && newBooth.delegateStore.getDelegates();
            self.booths.set(newBooth.key, newBooth);
          }
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
          this.deleteEffect(context);
          break;
        case "initial":
          this.initialEffect(payload);
          break;
      }
    },
    initialEffect(payload: any) {
      const { booth, participants, proposals, votes } = payload.data;
      let metadata = { ...booth.meta, color: "#000000" };
      if (booth.type === "group") {
        const groupMetadata = rootStore.metadata.groupsMap.get(booth.key);
        if (groupMetadata) metadata = clone(groupMetadata);
      } else {
        const contactMetadata = rootStore.metadata.contactsMap.get(booth.key);
        if (contactMetadata) metadata = clone(contactMetadata);
      }
      self.booths.set(
        booth.key,
        BoothModel.create({
          ...booth,
          meta: metadata,
          proposalStore: ProposalStore.create({
            boothKey: booth.key,
            loader: { state: "loaded" },
          }),
          participantStore: ParticipantStore.create({
            boothKey: booth.key,
            loader: { state: "loaded" },
          }),
          delegateStore: DelegateStore.create({
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
      let metadata = { ...booth.meta, color: "#000000" };
      if (booth.type === "group") {
        const groupMetadata = rootStore.metadata.groupsMap.get(booth.key);
        if (groupMetadata) metadata = clone(groupMetadata);
      } else {
        const contactMetadata = rootStore.metadata.contactsMap.get(booth.key);
        if (contactMetadata) metadata = clone(contactMetadata);
      }
      self.booths.set(
        booth.key,
        BoothModel.create({
          ...booth,
          meta: metadata,
          proposalStore: ProposalStore.create({
            boothKey: booth.key,
          }),
          participantStore: ParticipantStore.create({
            boothKey: booth.key,
          }),
          delegateStore: DelegateStore.create({
            boothKey: booth.key,
          }),
          loader: { state: "loaded" },
        })
      );
      // One the add (when a group is adedd from Groups), get participants and proposals
      const addedBooth = self.booths.get(booth.key)!;
      addedBooth.participantStore.getParticipants();
      addedBooth.proposalStore.getProposals();
    },
    updateEffect(key: string, data: any) {
      // console.log("booth updateEffect ", key, data);
      // Delete the meta key
      const oldBooth = self.booths.get(key);
      // console.log(oldBooth);
      oldBooth?.updateEffect(data);
    },
    deleteEffect(context: { booth: string }) {
      // console.log("booth deleteEffect ", context);
      // TODO add you've been remove from the booth notification
      self.booths.delete(context.booth);
    },
  }));
