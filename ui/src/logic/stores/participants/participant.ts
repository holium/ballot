import { types, Instance, IJsonPatch, applyPatch } from "mobx-state-tree";

export const ParticipantModel = types
  .model({
    key: types.identifier,
    name: types.string,
    created: types.number,
    metadata: types.optional(types.frozen(), { color: "#000000" }),
    status: types.enumeration("State", [
      "pending",
      "invited",
      "error",
      "enlisted",
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
