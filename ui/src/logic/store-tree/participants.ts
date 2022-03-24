import {
  types,
  flow,
  Instance,
  SnapshotIn,
  getParent,
  destroy,
  SnapshotOut,
} from "mobx-state-tree";

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
    add() {},
    remove(item: SnapshotIn<typeof self>) {
      destroy(item);
    },
  }));

type ParticipantType = typeof ParticipantModel.properties;
