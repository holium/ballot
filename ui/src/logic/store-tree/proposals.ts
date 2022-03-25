import {
  types,
  flow,
  Instance,
  SnapshotIn,
  getParent,
  destroy,
  SnapshotOut,
  applyPatch,
  IJsonPatch,
} from "mobx-state-tree";

import proposalsApi from "../api/proposals";
import votesApi from "../api/votes";
import { BoothModelType } from "./booths";
import { ContextModelType, EffectModelType } from "./common/effects";

import { LoaderModel } from "./common/loader";

export const ChoiceModel = types.model({
  label: types.string,
  description: types.maybeNull(types.string),
  action: types.maybeNull(types.string),
});
export type ChoiceModelType = Instance<typeof ChoiceModel>;

export const VoteResultModel = types.model({
  voter: types.string,
  status: types.enumeration("VoteStatus", ["pending", "recorded", "counted"]),
  choice: ChoiceModel,
  signature: types.maybeNull(types.string),
  created: types.maybeNull(types.string),
});
export type VoteResultModelType = Instance<typeof VoteResultModel>;

export const ProposalModel = types
  .model({
    boothKey: types.string,
    key: types.identifier,
    owner: types.string,
    title: types.string,
    content: types.string,
    start: types.number,
    end: types.number,
    status: types.optional(types.string, "Draft"),
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
    results: types.map(VoteResultModel),
  })
  .views((self) => ({
    // surfaces isLoaded for convenience
    get isLoaded() {
      return self.loader.isLoaded;
    },
    get voteCount() {
      return self.results.size;
    },
    get participantCount(): number {
      const parentBooth: BoothModelType = getParent(self, 3);
      return parentBooth.participantStore.count;
    },
  }))
  .actions((self) => ({
    update: flow(function* (proposalForm: Instance<typeof self>) {
      try {
        const [response, error] = yield proposalsApi.update(
          self.boothKey,
          self.key,
          proposalForm
        );
        if (error) throw error;
        const validKeys = Object.keys(response.data).filter((key: string) =>
          self.hasOwnProperty(key)
        );
        const patches: IJsonPatch[] = validKeys.map((key: string) => ({
          op: "replace",
          path: `/${key}`,
          value: response.data[key],
        }));
        applyPatch(self, patches);
        return self;
      } catch (error) {
        self.loader.error(error.toString());
        return;
      }
    }),
    castVote: flow(function* (chosenVote: Instance<typeof VoteResultModel>) {
      try {
        const [response, error] = yield votesApi.castVote(
          self.boothKey,
          self.key,
          chosenVote
        );
        if (error) throw error;
        self.results.set(chosenVote.voter, {
          ...response.data,
          status: "pending",
          voter: chosenVote.voter,
        });
      } catch (error) {
        self.loader.error(error.toString());
      }
    }),
    getVotes: flow(function* () {
      try {
        const [response, error] = yield votesApi.initialVotes(
          self.boothKey,
          self.key
        );
        if (error) throw error;
        // response could be null
        Object.values(response || []).forEach((vote: any) => {
          const newVoteResult = VoteResultModel.create(vote);
          self.results.set(vote.voter, vote);
        });
      } catch (error) {
        self.loader.error(error.toString());
      }
    }),
    initialEffect(voteMap: any) {
      //
    },
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
      return self;
    },
  }));

export type ProposalModelType = Instance<typeof ProposalModel>;

export const ProposalStore = types
  .model({
    boothKey: types.string,
    loader: types.optional(LoaderModel, { state: "initial" }),
    addLoader: types.optional(LoaderModel, { state: "initial" }),
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
    get isLoaded() {
      return self.loader.isLoaded;
    },
  }))
  .actions((self) => ({
    // list call
    getProposals: flow(function* () {
      self.loader.set("loading");
      try {
        const [response, error] = yield proposalsApi.getAll(self.boothKey);
        if (error) throw error;
        self.loader.set("loaded");
        // response could be null
        Object.values(response || []).forEach((proposal: any) => {
          proposal.redacted = false; // todo fix this on backend
          const newProposal = ProposalModel.create({
            ...proposal,
            status: determineStatus(proposal),
            boothKey: self.boothKey,
          });
          newProposal.getVotes();
          self.proposals.set(newProposal.key, newProposal);
        });
      } catch (error) {
        self.loader.error(error.toString());
      }
    }),
    //
    // add new resource
    //
    add: flow(function* (proposalForm: ProposalModelType) {
      self.addLoader.set("loading");
      try {
        const [response, error] = yield proposalsApi.create(
          self.boothKey,
          proposalForm
        );
        if (error) throw error;
        self.addLoader.set("loaded");
        // response could be null
        console.log("creating proposal ", response);
        // Object.values(response || []).forEach((proposal: any) => {
        const newProposal = ProposalModel.create({
          ...response.data,
          status: determineStatus(response.data),
          owner: "",
          boothKey: self.boothKey,
        });
        // newProposal.redacted = false; // todo fix this on backend
        self.proposals.set(newProposal.key, newProposal);
        return newProposal;
        // });
      } catch (error) {
        self.loader.error(error.toString());
        return;
      }
    }),
    //
    // setActive
    //
    setActive(proposal: Instance<typeof ProposalModel>) {
      self.activeProposal = proposal.key;
    },
    //
    // remove
    //
    remove: flow(function* (proposalKey: string) {
      try {
        const [response, error] = yield proposalsApi.delete(
          self.boothKey,
          proposalKey
        );
        if (error) throw error;
        const deleted = self.proposals.get(proposalKey)!;
        self.proposals.delete(proposalKey);
        destroy(deleted);
      } catch (error) {
        self.loader.error(error.toString());
      }
    }),
    //
    //
    //
    onEffect(
      payload: EffectModelType,
      context: ContextModelType,
      action?: string
    ) {
      switch (payload.effect) {
        case "add":
          this.addEffect(payload.data);
          break;
        case "update":
          this.updateEffect(payload.key!, payload.data);
          break;
        case "delete":
          this.deleteEffect(payload.key!);
          break;
        case "initial":
          // this.initialEffect(payload);
          break;
      }
    },
    initialEffect(proposalMap: any, voteMap: any) {
      console.log("proposal initialEffect proposalMap ", proposalMap);
      Object.keys(proposalMap).forEach((proposalKey: any) => {
        const proposal = proposalMap[proposalKey];
        const newProposal = ProposalModel.create({
          ...proposal,
          status: determineStatus(proposal),
          boothKey: self.boothKey,
        });
        Object.keys(voteMap).forEach((voterKey: string) => {
          const voteResult = voteMap[voterKey];
          newProposal.results.set(
            voteResult.voter,
            VoteResultModel.create({
              ...voteResult,
              choice: ChoiceModel.create(voteResult.choice),
            })
          );
        });
        self.proposals.set(proposal.key, newProposal);
      });
    },

    addEffect(proposal: any) {
      console.log("proposal addEffect ", proposal);
      self.proposals.set(
        proposal.key,
        ProposalModel.create({
          ...proposal,
          status: determineStatus(proposal),
          boothKey: self.boothKey,
        })
      );
    },
    updateEffect(proposalKey: string, data: any) {
      console.log("proposal updateEffect ", proposalKey, data);
      const oldProposal = self.proposals.get(proposalKey)!;
      const updated: any = oldProposal.updateEffect(data)!;
      self.proposals.set(proposalKey, updated);
    },
    deleteEffect(proposalKey: string) {
      console.log("proposal deleteEffect ", proposalKey);
      self.proposals.delete(proposalKey);
    },
  }));

function determineStatus(proposal: ProposalModelType) {
  const now = new Date().getTime();
  const startTime = new Date(proposal.start).getTime();
  const endTime = new Date(proposal.end).getTime();

  let status = "Draft";
  if (startTime > now) {
    status = "Upcoming";
  }
  if (endTime < now) {
    status = "Ended";
  }

  if (startTime < now && now < endTime) {
    status = "Active";
  }
  return status;
}
