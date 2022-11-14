import { types, flow } from "mobx-state-tree";
import delegateApi from "../../api/delegates";
import { timeout } from "../../utils/dev";
import { ContextModelType, EffectModelType } from "../common/effects";
import { LoaderModel } from "../common/loader";
import { DelegateModel, DelegateModelType } from "./delegate";

export const DelegateStore = types
  .model({
    boothKey: types.string,
    loader: types.optional(LoaderModel, { state: "initial" }),
    delegateLoader: types.optional(LoaderModel, { state: "initial" }),
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
    getDelegate(ship: string) {
      let ourDelegate: string = "";
      Array.from(self.delegates.values()).forEach(
        (delegate: DelegateModelType) => {
          if (delegate.sig?.voter === ship) {
            ourDelegate = delegate.delegate;
          }
        }
      );
      return ourDelegate;
    },
    getVotingPower(ship: string): number {
      let votingPower: number = 0;
      const memberDelegate = self.delegates.get(ship);

      if (memberDelegate != null) {
        votingPower = 0;
      } else {
        votingPower = Array.from(self.delegates.values()).reduce(
          (power: number, delegateRecord: any) => {
            if (delegateRecord.delegate === ship) {
              return power + 1;
            }
            return power;
          },
          1
        );
      }
      return votingPower;
    },
  }))
  .actions((self) => ({
    getDelegates: flow(function* () {
      self.loader.set("loading");
      try {
        const [response, error] = yield delegateApi.getDelegates(self.boothKey);
        if (error) throw error;
        self.loader.set("loaded");
        Object.keys(response || {}).forEach((delegatingShip: any) => {
          const newDelegate = DelegateModel.create(response[delegatingShip]);
          self.delegates.set(delegatingShip, newDelegate);
        });
      } catch (err: any) {
        self.loader.error(err);
      }
    }),
    delegate: flow(function* (delegateKey: string) {
      self.delegateLoader.clearError();
      self.delegateLoader.set("loading");
      yield timeout(1000);
      try {
        const [response, error] = yield delegateApi.addDelegate(
          self.boothKey,
          delegateKey
        );
        if (error) throw error;
        const newParticipant = DelegateModel.create({
          delegate: delegateKey,
          sig: null,
          created: 0,
        });
        self.delegateLoader.set("loaded");
        // self.delegates.set(newParticipant.key, newParticipant);
      } catch (err: any) {
        self.delegateLoader.error(err);
      }
    }),
    undelegate: flow(function* (delegateKey: string) {
      self.delegateLoader.clearError();
      self.delegateLoader.set("loading");
      yield timeout(1000);
      try {
        const [response, error] = yield delegateApi.deleteDelegate(
          self.boothKey,
          delegateKey
        );
        if (error) throw error;
        self.delegateLoader.set("loaded");
        // self.delegates.delete(delegateKey);
      } catch (err: any) {
        self.delegateLoader.error(err);
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
          this.addEffect(context, payload.data);
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

    addEffect(context: any, delegate: any) {
      console.log("delegate addEffect ", delegate);
      self.delegates.set(context.participant, DelegateModel.create(delegate));
    },
    updateEffect(delegateKey: string, data: any) {
      // console.log("delegate updateEffect ", delegateKey, data);
      const oldDelegate = self.delegates.get(delegateKey);
      oldDelegate?.updateEffect(data);
    },
    deleteEffect(context: ContextModelType) {
      console.log("delegate deleteEffect ", context.participant);
      self.delegates.delete(context.participant!);
    },
  }));
