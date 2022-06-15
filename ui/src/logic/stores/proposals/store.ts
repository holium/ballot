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
import { date } from "yup";
import {
  ChoiceModel,
  determineStatus,
  ProposalModel,
  ProposalModelType,
  VoteModel,
} from ".";
import proposalsApi from "../../api/proposals";
import voteApi from "../../api/votes";
import { BoothModelType } from "../booths";
import { ContextModelType, EffectModelType } from "../common/effects";

import { LoaderModel } from "../common/loader";
import { rootStore } from "../root";

export const ProposalStore = types
  .model({
    boothKey: types.string,
    loader: types.optional(LoaderModel, { state: "initial" }),
    addLoader: types.optional(LoaderModel, { state: "initial" }),
    proposals: types.map(ProposalModel),
    selectedProposal: types.maybe(types.reference(ProposalModel)),
  })
  .views((self) => ({
    get list() {
      // return Array.from(self.proposals.values()).sort(
      //   (a: ProposalModelType, b: ProposalModelType) =>
      //     a.status === "Active" || b.status === ? 0 : -1
      // );
      return Array.from(self.proposals.values());
    },
    get proposal() {
      return self.selectedProposal;
    },
    get isLoaded() {
      return self.loader.isLoaded;
    },
    get isAdding() {
      return self.addLoader.isLoading;
    },
  }))
  .actions((self) => ({
    // list call
    getProposals: flow(function* () {
      self.loader.set("loading");
      try {
        const [response, error] = yield proposalsApi.getAll(self.boothKey);
        const [voteResponse, voteError] = yield voteApi.getAll(self.boothKey);
        if (error) throw error;
        if (voteError) throw voteError;
        // response could be null
        Object.values(response || []).forEach((proposal: any) => {
          const newProposal = ProposalModel.create({
            ...proposal,
            status: determineStatus(proposal),
            boothKey: self.boothKey,
          });
          self.proposals.set(newProposal.key, newProposal);
          // if there is a vote map, and there is a map for our proposal, set the votes
          voteResponse &&
            voteResponse[proposal.key] &&
            newProposal.setVotes(voteResponse[proposal.key]);
        });
        self.loader.set("loaded");
      } catch (err: any) {
        self.loader.error(err);
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
        // response could be null
        // const parentBooth: BoothModelType = getParent(self, 1);
        // const newProposal = ProposalModel.create({
        //   ...response.data,
        //   status: determineStatus(response.data),
        //   owner: rootStore.app.ship.patp,
        //   boothKey: self.boothKey,
        //   // we need to set the appropriate participant count by default
        //   results: {
        //     didVote: false,
        //     votes: {},
        //     resultSummary: {
        //       voteCount: 0,
        //       participantCount: parentBooth.participantStore.count,
        //       topChoice: undefined,
        //       tallies: [],
        //     },
        //   },
        // });
        // self.proposals.set(newProposal.key, newProposal);
        // self.addLoader.set("loaded");
        // return newProposal;
      } catch (err: any) {
        self.loader.error(err);
        return;
      }
    }),
    //
    // setActive
    //
    setActive(proposal: Instance<typeof ProposalModel>) {
      self.selectedProposal = proposal;
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
        // self.proposals.delete(proposalKey);
      } catch (err: any) {
        self.loader.error(err);
      }
    }),
    //
    //
    //
    onEffect(
      payload: EffectModelType,
      context: ContextModelType,
      action: string
    ) {
      switch (payload.effect) {
        case "add":
          this.addEffect(action, context, payload.data);
          break;
        case "update":
          this.updateEffect(payload.key!, payload.data, action);
          break;
        case "delete":
          this.deleteEffect(payload.key!);
          break;
        case "error":
          this.errorEffect(action, payload);
          break;
        case "initial":
          // this.initialEffect(payload);
          break;
      }
    },
    onPollEffect(effect: EffectModelType, proposalKey: string) {
      const data: any = effect.data;
      const oldProposal = self.proposals.get(proposalKey)!;
      const updated: any = oldProposal.onPollEffect(data)!;
      self.proposals.set(proposalKey, updated);
    },
    initialEffect(proposalMap: any, voteMap: any) {
      // console.log("proposal initialEffect proposalMap ", proposalMap);
      Object.keys(proposalMap).forEach((proposalKey: any) => {
        const proposal = proposalMap[proposalKey];
        const newProposal = ProposalModel.create({
          ...proposal,
          status: determineStatus(proposal),
          boothKey: self.boothKey,
        });
        voteMap[proposalKey] &&
          Object.keys(voteMap[proposalKey]).forEach((voterKey: string) => {
            const voteResult = voteMap[proposalKey][voterKey];
            if (voteResult)
              newProposal.results!.setNewVote(
                VoteModel.create({
                  ...voteResult,
                  choice: ChoiceModel.create(voteResult.choice),
                })
              );
          });
        self.proposals.set(proposal.key, newProposal);
        newProposal.results.generateResultSummary();
      });
    },

    addEffect(action: string, context: any, proposal: any) {
      // console.log("proposal addEffect ", proposal);
      const parentBooth: BoothModelType = getParent(self, 1);
      const key = context.proposal;
      if (action === "save-proposal-reaction" && self.loader.isLoading) {
        self.loader.set("loaded");
      }
      self.proposals.set(
        key,
        ProposalModel.create({
          ...proposal,
          key,
          status: determineStatus(proposal),
          boothKey: self.boothKey,
          results: {
            didVote: false,
            votes: {},
            resultSummary: {
              voteCount: 0,
              participantCount: parentBooth.participantStore.count,
              topChoice: undefined,
              tallies: [],
            },
          },
        })
      );
    },
    updateEffect(proposalKey: string, data: any, action: string) {
      // console.log("proposal updateEffect ", action, proposalKey, data);
      const oldProposal = self.proposals.get(proposalKey);
      if (oldProposal) {
        const updated: any = oldProposal.updateEffect(data)!;
        self.proposals.set(proposalKey, updated);
      }
    },
    deleteEffect(proposalKey: string) {
      // console.log("proposal deleteEffect ", proposalKey);
      self.proposals.delete(proposalKey);
    },
    errorEffect(action: string, effect: any) {
      console.error(
        `${effect.data.error} on ${action.replace("-reaction", "")}`
      );
    },
  }));
