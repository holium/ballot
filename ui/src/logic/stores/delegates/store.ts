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
import delegateApi from "../../api/delegates";
import { ContextModelType, EffectModelType } from "../common/effects";
import { LoaderModel } from "../common/loader";
import { DelegateModel } from "./delegate";

export const DelegateStore = types
  .model({
    boothKey: types.string,
    loader: types.optional(LoaderModel, { state: "initial" }),
    delegates: types.map(DelegateModel),
  })
  .views((self) => ({
    get list() {
      return Array.from(self.delegates.values());
    },
    get count() {
      return self.delegates.size;
    },
    get isLoading() {
      return self.loader.isLoading;
    },
    get isLoaded() {
      return self.loader.isLoaded;
    },
  }))
  .actions((self) => ({
    getDelegates: flow(function* () {
      self.loader.set("loading");
      try {
        const [response, error] = yield delegateApi.getDelegates(self.boothKey);
        if (error) throw error;
        self.loader.set("loaded");
        Object.values(response || {}).forEach((delegate: any) => {
          const newDelegate = DelegateModel.create(delegate);
          self.delegates.set(newDelegate.key, newDelegate);
        });
      } catch (err: any) {
        self.loader.error(err);
      }
    }),
    delegate: flow(function* (delegateKey: string) {
      try {
        const [response, error] = yield delegateApi.addDelegate(
          self.boothKey,
          delegateKey
        );
        if (error) throw error;
        const newParticipant = DelegateModel.create({
          status: "pending",
          key: delegateKey,
          name: delegateKey,
          created: 0,
        });
        self.delegates.set(newParticipant.key, newParticipant);
      } catch (err: any) {
        self.loader.error(err);
      }
    }),
    remove: flow(function* (delegateKey: string) {
      try {
        const [response, error] = yield delegateApi.deleteDelegate(
          self.boothKey,
          delegateKey
        );
        if (error) throw error;
        const deleted = self.delegates.get(delegateKey)!;
        self.delegates.delete(delegateKey);
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
          this.deleteEffect(context);
          break;
        case "initial":
          // this.initialEffect(payload);
          break;
      }
    },
    // data: Map<string, ParticipantModelType>
    initialEffect(delegateMap: any) {
      // console.log("delegate initialEffect delegateMap ", delegateMap);
      Object.keys(delegateMap).forEach((delegateKey: string) => {
        self.delegates.set(
          delegateKey,
          DelegateModel.create(delegateMap[delegateKey])
        );
      });
    },

    addEffect(delegate: any) {
      // console.log("delegate addEffect ", delegate);
      self.delegates.set(delegate.key, DelegateModel.create(delegate));
    },
    updateEffect(delegateKey: string, data: any) {
      // console.log("delegate updateEffect ", delegateKey, data);
      const oldBooth = self.delegates.get(delegateKey);
      oldBooth?.updateEffect(data);
    },
    deleteEffect(context: ContextModelType) {
      console.log("delegate deleteEffect ", context.delegate);
      self.delegates.delete(context.delegate!);
    },
  }));
