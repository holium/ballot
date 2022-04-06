import { types, Instance } from "mobx-state-tree";
import { ChoiceModel } from ".";

export const VoteModel = types.model({
  voter: types.string,
  status: types.enumeration("VoteStatus", ["pending", "recorded", "counted"]),
  choice: ChoiceModel,
  signature: types.optional(types.string, ""),
  created: types.maybeNull(types.number),
});

export type VoteModelType = Instance<typeof VoteModel>;
