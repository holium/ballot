import { types, Instance } from "mobx-state-tree";

const ShipModel = types.model({
  patp: types.string,
  metadata: types.optional(
    types.model({
      color: types.string,
    }),
    { color: "#000000" }
  ),
});

export const AppModel = types
  .model({
    title: types.optional(types.string, ""),
    currentUrl: types.optional(types.string, ""),
    currentPage: types.optional(types.string, "proposals"),
    theme: types.optional(
      types.enumeration("Theme", ["light", "dark"]),
      "light"
    ),
    ship: ShipModel,
  })
  .actions((self) => ({
    setTitle(title: typeof self.title) {
      self.title = title;
    },
    setTheme(theme: typeof self.theme) {
      self.theme = theme;
    },
    setCurrentUrl(url: string, page?: string) {
      self.currentUrl = url;
      if (page) self.currentPage = page;
    },
  }));

export type AppModelType = Instance<typeof AppModel>;
