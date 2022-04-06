import { rootStore } from "./../root";
import { types, Instance, IJsonPatch, applyPatch } from "mobx-state-tree";
import { ContactMetadataModel } from "../metadata";

export const ParticipantModel: any = types
  .model({
    key: types.identifier,
    name: types.string,
    created: types.number,
    role: types.optional(
      types.enumeration(["owner", "participant"]),
      "participant"
    ),
    metadata: types.optional(ContactMetadataModel, { color: "#000000" }),
    status: types.enumeration("State", [
      "pending",
      "invited",
      "error",
      "enlisted",
      "active",
    ]),
  })
  .views((self) => ({
    getParticipant(): ParticipantModelType {
      return {
        ...self,
        metadata: rootStore.metadata.contactsMap.get(self.key),
      };
    },
  }))
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
