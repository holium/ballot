import {
  types,
  flow,
  Instance,
  SnapshotIn,
  getParent,
  destroy,
  SnapshotOut,
} from "mobx-state-tree";
import proposalsApi from "../api/proposals";

import { LoaderModel } from "./common/loader";

export const ChoiceModel = types.model({
  label: types.string,
  description: types.maybeNull(types.string),
  action: types.maybeNull(types.string),
});

export const ProposalModel = types
  .model({
    booth: types.string,
    key: types.identifier,
    owner: types.string,
    title: types.string,
    content: types.string,
    start: types.number,
    end: types.number,
    redacted: types.optional(types.boolean, false),
    strategy: types.enumeration("Strategy", [
      "single-choice",
      "multiple-choice",
    ]),
    support: types.number,
    choices: types.optional(types.array(ChoiceModel), [
      { label: "Approve" },
      { label: "Reject" },
    ]),
    loader: types.optional(LoaderModel, { state: "initial" }),
  })
  .views((self) => ({
    // surfaces isLoaded for convenience
    get isLoaded() {
      return self.loader.isLoaded;
      // return Array.from(self.booths.values());
    },
  }))
  .actions((self) => ({
    update: flow(function* (proposalForm: Instance<typeof self>) {
      try {
        const [response, error] = yield proposalsApi.update(
          self.booth,
          self.key,
          proposalForm
        );
        if (error) throw error;
        // self.loader.set("loaded");
      } catch (error) {
        self.loader.error(error.toString());
      }
    }),
  }));

type ProposalType = typeof ProposalModel.properties;

export const ProposalStore = types
  .model({
    boothKey: types.string,
    loader: types.optional(LoaderModel, { state: "initial" }),
    proposals: types.map(ProposalModel),
    activeProposal: types.optional(types.string, ""),
  })
  .views((self) => ({
    get list() {
      return Array.from(self.proposals.values());
    },
    get proposal() {
      return self.proposals.get(self.activeProposal);
    },
  }))
  .actions((self) => ({
    getProposals: flow(function* () {
      self.loader.set("loading");
      try {
        const [response, error] = yield proposalsApi.getAll(self.boothKey);
        if (error) throw error;
        self.loader.set("loaded");
        // response could be null
        Object.values(response || []).forEach((proposal: any) => {
          proposal.redacted = false; // todo fix this on backend
          const newProposal = ProposalModel.create(proposal);
          newProposal.booth = self.boothKey;
          self.proposals.set(newProposal.key, newProposal);
        });
      } catch (error) {
        self.loader.error(error.toString());
      }
    }),
    add: flow(function* (proposalForm: Instance<typeof self>) {
      // self.loader.set("loading");
      try {
        const [response, error] = yield proposalsApi.create(
          self.boothKey,
          proposalForm
        );
        if (error) throw error;
        // self.loader.set("loaded");
        // response could be null
        console.log("creating proposal ", proposalForm);
        // Object.values(response || []).forEach((proposal: any) => {
        //   proposal.redacted = false; // todo fix this on backend
        //   const newProposal = ProposalModel.create(proposal);
        //   newProposal.booth = self.boothKey;
        //   self.proposals.set(newProposal.key, newProposal);
        // });
      } catch (error) {
        self.loader.error(error.toString());
      }
    }),
    setActive(proposal: Instance<typeof ProposalModel>) {
      self.activeProposal = proposal.key;
    },
    remove(proposal: Instance<typeof ProposalModel>) {
      // TODO
      destroy(proposal);
    },
  }));
