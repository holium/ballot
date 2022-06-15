import { DelegateModel } from "./../delegates/delegate";
import { types, Instance } from "mobx-state-tree";
import { ChoiceModel } from ".";

export const VoteModel = types.model({
  voter: types.string,
  status: types.enumeration("VoteStatus", ["pending", "recorded", "counted"]),
  choice: ChoiceModel,
  delegators: types.map(DelegateModel),
  sig: types.maybeNull(
    types.model({
      voter: types.string,
      life: types.number,
      hash: types.string,
    })
  ),
  created: types.maybeNull(types.number),
});

export type VoteModelType = Instance<typeof VoteModel>;
