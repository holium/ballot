import { types, Instance } from "mobx-state-tree";
import { matchPath } from "react-router-dom";

const ShipModel = types.model({
  patp: types.string,
  metadata: types.optional(
    types.model({
      color: types.string,
    }),
    { color: "#000000" }
  ),
});

export type ShipModelType = Instance<typeof ShipModel>;

export const AppModel = types
  .model({
    title: types.optional(types.string, "Ballot"),
    currentUrl: types.optional(types.string, ""),
    currentPage: types.optional(types.string, "proposals"),
    theme: types.enumeration("Theme", ["light", "dark"]),
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
      if (page) {
        self.currentPage = page;
        return;
      }
      // Checks if delegation is selected
      // TODO better routing mst
      const matchesDelegation = matchPath(
        `/apps/ballot/booth/:type/:boothName/delegation`,
        url
      );
      if (matchesDelegation) {
        self.currentPage = "delegation";
      } else {
        self.currentPage = "proposals";
      }
    },
  }));

export type AppModelType = Instance<typeof AppModel>;
