import { Instance, types } from "mobx-state-tree";

export const EffectModel = types.model("EffectModel", {
  resource: types.string, // "booth", "participant", "proposal", "vote"
  effect: types.string,
  key: types.string,
  data: types.model(),
});
export type EffectModelType = Instance<typeof EffectModel>;

export const ContextModel = types.model({
  booth: types.maybeNull(types.string),
  participant: types.maybeNull(types.string),
  proposal: types.maybeNull(types.string),
  delegate: types.maybeNull(types.string),
});

export type ContextModelType = Instance<typeof ContextModel>;

export const ActionModel = types.model("ActionModel", {
  action: types.string,
  context: ContextModel,
  effects: types.array(EffectModel),
});
export type ActionModelType = Instance<typeof ActionModel>;

export const ChannelResponseModel = types.model("ChannelResponseModel", {
  id: types.number,
  json: ActionModel,
  response: types.enumeration("responseType", ["diff"]),
});
export type ChannelResponseModelType = Instance<typeof ChannelResponseModel>;

export const EffectsBase = types.model("EffectsBase").actions(() => ({
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
    console.log("initialEffect ", payload);
  },
  addEffect(data: any) {
    console.log("addEffect ", data);
  },
  updateEffect(key: string, data: any) {
    console.log("updateEffect ", key, data);
  },
  deleteEffect(key: string) {
    console.log("deleteEffect ", key);
  },
}));
