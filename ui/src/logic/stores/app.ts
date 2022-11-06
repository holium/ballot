import { ContactMetadataModel } from "./metadata";
import { types, Instance } from "mobx-state-tree";
import { matchPath } from "react-router-dom";
import { rootStore } from "./root";

const ShipModel = types.model({
  patp: types.string,
  metadata: types.optional(ContactMetadataModel, { color: "#000000" }),
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
  .views((self) => ({
    get account() {
      let ship = self.ship;
      const additionalMetadata = rootStore.metadata.contactsMap.get(
        self.ship.patp
      )!;
      if (additionalMetadata) ship = { ...ship, metadata: additionalMetadata };

      return ship;
    },
  }))
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
        "/apps/ballot/booth/:boothName/delegation",
        url
      );
      const matchesSettings = matchPath(
        "/apps/ballot/booth/:boothName/settings",
        url
      );
      if (matchesDelegation != null) {
        self.currentPage = "delegation";
      } else if (matchesSettings != null) {
        self.currentPage = "settings";
      } else {
        self.currentPage = "proposals";
      }
    },
  }));

export type AppModelType = Instance<typeof AppModel>;
