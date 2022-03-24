import {
  types,
  flow,
  Instance,
  SnapshotIn,
  getParent,
  destroy,
  SnapshotOut,
} from "mobx-state-tree";
import proposalsApi from "../api/proposals";

import { LoaderModel } from "./common/loader";

export const ChoiceModel = types.model({
  label: types.string,
  description: types.maybeNull(types.string),
  action: types.maybeNull(types.string),
});

export const ProposalModel = types
  .model({
    key: types.identifier,
    owner: types.string,
    title: types.string,
    content: types.string,
    start: types.number,
    end: types.number,
    redacted: types.optional(types.boolean, false),
    strategy: types.enumeration("Strategy", [
      "single-choice",
      "multiple-choice",
    ]),
    support: types.number,
    choices: types.optional(types.array(ChoiceModel), [
      { label: "Approve" },
      { label: "Reject" },
    ]),
    loader: types.optional(LoaderModel, { state: "initial" }),
  })
  .actions((self) => ({
    remove(item: SnapshotIn<typeof self>) {
      destroy(item);
    },
  }));

type ProposalType = typeof ProposalModel.properties;
