import {
  types,
  flow,
  Instance,
  SnapshotIn,
  getParent,
  destroy,
  SnapshotOut,
  applyPatch,
  IJsonPatch,
} from "mobx-state-tree";

export const ChoiceModel = types
  .model({
    label: types.string,
    description: types.maybeNull(types.string),
    action: types.maybeNull(types.string),
  })
  .actions((self) => ({
    setLabel: (label: string) => {
      self.label = label;
    },
    setAction: (action: string) => {
      self.action = action;
    },
  }));

export type ChoiceModelType = Instance<typeof ChoiceModel>;
