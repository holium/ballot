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
import { ProposalStore } from "../proposals";
import { rootStore } from "../root";

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
      return Array.from(self.proposalStore.proposals.values());
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
    acceptInvite: flow(function* (boothKey: string) {
      try {
        const [response, error] = yield boothApi.acceptInvite(boothKey);
        if (error) throw error;
        self.actionLog.set(
          `${response.action}-${response.key}`,
          response.status
        );
      } catch (err: any) {
        self.loader.error(err.toString());
      }
    }),
    updateEffect(update: any) {
      console.log("updateEffect in booth ", update);

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
    remove(item: SnapshotIn<typeof self>) {
      destroy(item);
    },
  }));

export type BoothModelType = Instance<typeof BoothModel>;
