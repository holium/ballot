import {
  types,
  flow,
  Instance,
  SnapshotIn,
  getParent,
  SnapshotOut,
  IJsonPatch,
  applyPatch,
} from "mobx-state-tree";
import participantApi from "../../api/participants";
import { ContextModelType, EffectModelType } from "../common/effects";

import { LoaderModel } from "../common/loader";
import { ParticipantModel } from "../participants";

export const ParticipantStore = types
  .model({
    boothKey: types.string,
    loader: types.optional(LoaderModel, { state: "initial" }),
    participants: types.map(ParticipantModel),
  })
  .views((self) => ({
    get list() {
      return Array.from(self.participants.values());
    },
    get count() {
      return self.participants.size;
    },
    get isLoading() {
      return self.loader.isLoading;
    },
    get isLoaded() {
      return self.loader.isLoaded;
    },
  }))
  .actions((self) => ({
    getParticipants: flow(function* () {
      self.loader.set("loading");
      try {
        const [response, error] = yield participantApi.getParticipants(
          self.boothKey
        );
        if (error) throw error;
        self.loader.set("loaded");
        Object.values(response).forEach((participant: any) => {
          const newParticipant = ParticipantModel.create(participant);
          self.participants.set(newParticipant.key, newParticipant);
        });
      } catch (err: any) {
        self.loader.error(err);
      }
    }),
    add: flow(function* (participantKey: string) {
      try {
        const [response, error] = yield participantApi.addParticipant(
          self.boothKey,
          participantKey
        );
        if (error) throw error;
        const newParticipant = ParticipantModel.create({
          status: "pending",
          key: participantKey,
          name: participantKey,
          created: 0,
        });
        self.participants.set(newParticipant.key, newParticipant);
      } catch (err: any) {
        self.loader.error(err);
      }
    }),
    remove: flow(function* (participantKey: string) {
      try {
        const [response, error] = yield participantApi.deleteParticipant(
          self.boothKey,
          participantKey
        );
        if (error) throw error;
        const deleted = self.participants.get(participantKey)!;
        self.participants.delete(participantKey);
      } catch (err: any) {
        self.loader.error(err);
      }
    }),
    //
    //
    //
    onEffect(
      payload: EffectModelType,
      context: ContextModelType,
      action?: string
    ) {
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
          // this.initialEffect(payload);
          break;
      }
    },
    // data: Map<string, ParticipantModelType>
    initialEffect(participantMap: any) {
      console.log("participant initialEffect participantMap ", participantMap);
      Object.keys(participantMap).forEach((participantKey: string) => {
        self.participants.set(
          participantKey,
          ParticipantModel.create(participantMap[participantKey])
        );
      });
    },

    addEffect(participant: any) {
      console.log("participant addEffect ", participant);
      self.participants.set(
        participant.key,
        ParticipantModel.create(participant)
      );
    },
    updateEffect(participantKey: string, data: any) {
      console.log("participant updateEffect ", participantKey, data);
      const oldBooth = self.participants.get(participantKey);
      oldBooth?.updateEffect(data);
    },
    deleteEffect(participantKey: string) {
      console.log("participant deleteEffect ", participantKey);
      self.participants.delete(participantKey);
    },
  }));
