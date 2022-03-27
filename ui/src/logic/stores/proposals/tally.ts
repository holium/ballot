import { types, Instance } from "mobx-state-tree";

export const TallyModel = types
  .model({
    label: types.string,
    count: types.optional(types.number, 0),
    percentage: types.optional(types.number, 0),
  })
  .named("TallyModel");

export type TallyType = Instance<typeof TallyModel>;
