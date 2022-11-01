import { ParticipantModelType } from "./../participants/participant";
import {
  ContactMetadataModel,
  ContactModelType,
  GroupModelType,
} from "./../metadata";
import {
  types,
  flow,
  Instance,
  SnapshotIn,
  getParent,
  destroy,
  SnapshotOut,
  IJsonPatch,
  applyPatch,
} from "mobx-state-tree";
import boothApi from "../../api/booths";

import { LoaderModel } from "../common/loader";
import { GroupMetadataModel } from "../metadata";
import { ParticipantStore } from "../participants";
import { ProposalModelType, ProposalStore } from "../proposals";
import { rootStore } from "../root";
import { toJS } from "mobx";
import { DelegateStore } from "../delegates";
import participants from "../../api/participants";

const sortMap = {
  recent: (list: ProposalModelType[]) =>
    list.sort((a: ProposalModelType, b: ProposalModelType) => {
      return b.created! - a.created!;
    }),
  ending: (list: ProposalModelType[]) =>
    list
      .sort((a: ProposalModelType, b: ProposalModelType) => {
        return a.end - b.end;
      })
      .filter((item: ProposalModelType) => item.status !== "Ended"),
  starting: (list: ProposalModelType[]) =>
    list
      .sort((a: ProposalModelType, b: ProposalModelType) => {
        return a.start - b.start;
      })
      .filter((item: ProposalModelType) => item.status === "Upcoming"),
};

export const BoothMetadataModel = types.union(
  ContactMetadataModel,
  GroupMetadataModel
);

const ActionForm = types.model({
  label: types.string,
  description: types.maybe(types.string),
  filename: types.string,
  key: types.string,
  form: types.map(
    types.union(
      types.model({ type: types.string }),
      types.model({ type: types.enumeration(["cord", "?"]) }),
      types.model({
        type: types.enumeration(["list"]),
        options: types.array(types.string),
      })
    )
  ),
});

export const BoothModel = types
  .model({
    key: types.identifier,
    created: types.number,
    image: types.maybeNull(types.string),
    meta: BoothMetadataModel,
    name: types.string,
    owner: types.string,
    type: types.enumeration("Type", ["group", "ship"]),
    permission: types.maybeNull(
      types.enumeration("Permission", ["owner", "admin", "member", "viewer"])
    ),
    permissions: types.optional(
      types.array(types.enumeration(["owner", "admin", "member"])),
      []
    ),
    customActions: types.optional(types.array(ActionForm), []),
    defaults: types.maybeNull(
      types.model({ support: types.number, duration: types.number })
    ),
    status: types.enumeration("State", [
      "pending", // spinner
      "enlisted", // group auto invite
      "invited", // ship booth invite
      "error", //
      // "no-response", // agent didn't respond to poke?
      "active", // joined
    ]),
    loader: LoaderModel,
    settingsLoader: types.optional(LoaderModel, { state: "initial" }),
    proposalStore: ProposalStore,
    participantStore: ParticipantStore,
    delegateStore: DelegateStore,
    sortBy: types.optional(
      types.union(
        types.literal("recent"),
        types.literal("ending"),
        types.literal("starting")
      ),
      "recent"
    ),
  })
  .views((self) => ({
    get isActive() {
      return (
        self.status !== "pending" &&
        self.status !== "invited" &&
        self.status !== "enlisted"
      );
    },
    get listProposals() {
      return sortMap[self.sortBy](
        Array.from(self.proposalStore.proposals.values())
      );
    },
    get listParticipants() {
      return Array.from(self.participantStore.participants.values());
    },
    get isOwner(): boolean {
      return self.owner === rootStore.app.ship.patp;
    },
    get hasCreatePermission(): boolean {
      if (self.owner === rootStore.app.ship.patp) {
        return true;
      }

      if (self.participantStore.isLoaded) {
        const participant: ParticipantModelType =
          self.participantStore.participants.get(rootStore.app.ship.patp);

        if (self.permissions.includes(participant?.role)) {
          return true;
        } else {
          return false;
        }
      } else {
        return false;
      }
    },
    get hasAdmin(): boolean {
      if (self.owner === rootStore.app.ship.patp) {
        return true;
      }
      if (self.participantStore.isLoaded) {
        const participant: ParticipantModelType =
          self.participantStore.participants.get(rootStore.app.ship.patp);
        if (
          self.permissions.includes("admin") &&
          participant?.role === "admin"
        ) {
          return true;
        }
        return false;
      }
      return false;
    },
    get isLoading() {
      return self.loader.isLoading;
    },
    get isLoaded() {
      return self.loader.isLoaded;
    },
  }))
  .actions((self) => ({
    setShipMetadata(metadata: Instance<typeof BoothMetadataModel>) {
      self.meta = metadata;
    },
    setGroupMetadata(metadata: Instance<typeof BoothMetadataModel>) {
      self.meta = metadata;
    },
    setSortBy(sortBy: "recent" | "ending" | "starting") {
      self.sortBy = sortBy;
    },
    /**
     * Note: an action should set a loader and post to the ship. The reaction
     *       effect will update the loader to state="loaded" and perform the
     *       operation that the effect defined.
     */
    updateSettings: flow(function* (boothKey: string, updatedSettings: any) {
      try {
        self.settingsLoader.set("loading");
        const [response, error] = yield boothApi.saveBooth(
          boothKey,
          updatedSettings
        );
        if (error) throw error;
        // self.settingsLoader.set("loaded");
      } catch (err: any) {
        self.settingsLoader.error(err);
      }
    }),
    acceptInvite: flow(function* (boothKey: string) {
      try {
        const [response, error] = yield boothApi.acceptInvite(boothKey);
        if (error) throw error;
      } catch (err: any) {
        self.loader.error(err);
      }
    }),
    getCustomActions: flow(function* () {
      try {
        const [response, error] = yield boothApi.getCustomActions(self.key);
        if (error) throw error;
        // @ts-expect-error TODO look into this type issue
        self.customActions = Object.keys(response).map((actionKey: string) => ({
          label: response[actionKey].label,
          description: response[actionKey].description,
          filename: `${actionKey}.hoon`,
          key: actionKey,
          form: response[actionKey].form,
        }));
        return response;
      } catch (err: any) {
        self.loader.error(err);
      }
    }),
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
      if (self.loader.isLoading) {
        self.loader.set("loaded");
      }
      if (self.settingsLoader.isLoading) {
        self.settingsLoader.set("loaded");
      }
    },
    errorEffect(error: any) {
      console.log("error effect in booth: ", error);
    },
    remove(item: SnapshotIn<typeof self>) {
      destroy(item);
    },
  }));

export type BoothModelType = Instance<typeof BoothModel>;
