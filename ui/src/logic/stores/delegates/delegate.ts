import { types, Instance } from "mobx-state-tree";

export const DelegateModel: any = types
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
  .actions((self) => ({}));

export type DelegateModelType = Instance<typeof DelegateModel>;