import { types, Instance, IJsonPatch, applyPatch } from "mobx-state-tree";

export const DelegateModel = types
  .model({
    delegate: types.string,
    sig: types.maybeNull(
      types.model({
        voter: types.string,
        life: types.number,
        hash: types.string,
      })
    ),
    created: types.number,
  })
  .views((self) => ({}))
  .actions((self) => ({
    updateEffect(update: any) {
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

export type DelegateModelType = Instance<typeof DelegateModel>;
