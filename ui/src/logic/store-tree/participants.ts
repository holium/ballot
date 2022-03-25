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
import participantApi from "../api/participants";
import { ContextModelType, EffectModelType } from "./common/effects";

import { LoaderModel } from "./common/loader";

export const ParticipantModel = types
  .model({
    key: types.identifier,
    name: types.string,
    created: types.string,
    status: types.enumeration("State", [
      "pending",
      "invited",
      "error",
      "active",
    ]),
  })
  .actions((self) => ({
    setStatus(status: typeof self.status) {
      self.status = status;
    },
    updateEffect(update: any) {
      console.log("updateEffect in participant model ", update);

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
  }));

export type ParticipantModelType = Instance<typeof ParticipantModel>;

export const ParticipantStore = types
  .model({
    boothKey: types.string,
    loader: types.optional(LoaderModel, { state: "initial" }),
    participants: types.map(ParticipantModel),
  })
  .views((self) => ({
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
      } catch (error) {
        self.loader.error(error.toString());
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
          created: "",
        });
        self.participants.set(newParticipant.key, newParticipant);
      } catch (error) {
        self.loader.error(error.toString());
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
        destroy(deleted);
      } catch (error) {
        self.loader.error(error.toString());
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
// addParticipant = action(async (boothKey: string, participantKey: string) => {
//   this.loader.set(STATE.LOADING);
// const [response, error] = await this.api.addParticipant(
//   boothKey,
//   participantKey
// );
//   if (error) return null;
//   const currentMap = this.participants.get(boothKey)!;
//   currentMap[participantKey] = {
//     name: participantKey,
//     status: "pending",
//   };
//   runInAction(() => {
//     this.participants.set(boothKey, currentMap);
//     this.loader.set(STATE.LOADED);
//   });
// });
// removeParticipant = action(
//   async (boothKey: string, participantKey: string) => {
//     const [response, error] = await this.api.deleteParticipant(
//       boothKey,
//       participantKey
//     );
//     if (error) return null;
//     const currentMap = this.participants.get(boothKey)!;
//     runInAction(() => {
//       delete currentMap[participantKey];
//       this.participants.set(boothKey, currentMap);
//     });
//   }
// );
