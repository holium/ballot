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
import { ParticipantStore } from "../participants";
import { ProposalModelType, ProposalStore } from "../proposals";
import { rootStore } from "../root";

const sortMap = {
  recent: (list: ProposalModelType[]) =>
    list.sort((a: ProposalModelType, b: ProposalModelType) => {
      return parseInt(b.created!) - parseInt(a.created!);
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

const SortType = types.union(
  types.literal("recent"),
  types.literal("ending"),
  types.literal("starting")
);

export const BoothModel = types
  .model({
    key: types.identifier,
    created: types.string,
    image: types.maybeNull(types.string),
    meta: types.map(types.maybeNull(types.string)),
    name: types.string,
    owner: types.string,
    type: types.enumeration("Type", ["group", "ship"]),
    permission: types.maybeNull(
      types.enumeration("Permission", ["owner", "admin", "member", "viewer"])
    ),
    status: types.enumeration("State", [
      "pending",
      "enlisted",
      "invited",
      "error",
      "active",
    ]),
    loader: LoaderModel,
    proposalStore: ProposalStore,
    participantStore: ParticipantStore,
    actionLog: types.map(types.string),
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
    get hasAdmin(): boolean {
      // TODO use booth.permission (patrick fix)
      return self.owner === rootStore.app.ship.patp;
    },
    get isLoading() {
      return self.loader.isLoading;
    },
    get isLoaded() {
      return self.loader.isLoaded;
    },
    checkAction(action: string) {
      return self.actionLog.get(action);
    },
  }))
  .actions((self) => ({
    setSortBy(sortBy: "recent" | "ending" | "starting") {
      self.sortBy = sortBy;
    },
    acceptInvite: flow(function* (boothKey: string) {
      try {
        const [response, error] = yield boothApi.acceptInvite(boothKey);
        if (error) throw error;
        self.actionLog.set(
          `${response.action}-${response.key}`,
          response.status
        );
      } catch (err: any) {
        self.loader.error(err);
      }
    }),
    updateEffect(update: any) {
      console.log("updateEffect in booth ", update);

      const validKeys = Object.keys(update).filter((key: string) =>
        self.hasOwnProperty(key)
      );
      console.log(validKeys);
      const patches: IJsonPatch[] = validKeys.map((key: string) => ({
        op: "replace",
        path: `/${key}`,
        value: update[key],
      }));
      console.log(patches);
      applyPatch(self, patches);
    },
    remove(item: SnapshotIn<typeof self>) {
      destroy(item);
    },
  }));

export type BoothModelType = Instance<typeof BoothModel>;
