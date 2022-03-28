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
import { ChoiceModel, ResultModel, VoteModel } from ".";

import proposalsApi from "../../api/proposals";
import votesApi from "../../api/votes";
import { timeout } from "../../utils/dev";
import { BoothModelType } from "../booths";
import { ContextModelType, EffectModelType } from "../common/effects";

import { LoaderModel } from "../common/loader";
import { rootStore } from "../root";
import { VoteModelType } from "./vote";

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
    results: types.optional(ResultModel, {
      didVote: false,
      votes: {},
      resultSummary: {
        voteCount: 0,
        participantCount: 0,
        topChoice: undefined,
        tallies: [],
      },
    }),
  })
  .views((self) => ({
    get isLoaded() {
      return self.loader.isLoaded;
    },
    get isLoading() {
      return self.loader.isLoading;
    },
    get participantCount(): number {
      const parentBooth: BoothModelType = getParent(self, 3);
      return parentBooth.participantStore.count;
    },
  }))
  .actions((self) => ({
    addChoice: () => {
      const newChoice = { label: "", action: "" };
      self.choices.push(newChoice);
      return newChoice;
    },
    removeChoice: (removeIndex: number) => {
      self.choices.splice(removeIndex, 1);
    },
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
    castVote: flow(function* (chosenVote: VoteModelType) {
      try {
        const [response, error] = yield votesApi.castVote(
          self.boothKey,
          self.key,
          chosenVote
        );
        if (error) throw error;
        const voter = chosenVote.voter || rootStore.app.ship.patp;
        self.results!.votes.set(voter, {
          ...response.data,
          status: "pending",
          voter,
        });
        self.results!.didVote = true;
        self.results.generateResultSummary();
      } catch (error) {
        self.loader.error(error.toString());
      }
    }),
    getVotes: flow(function* () {
      self.loader.set("loading");
      yield timeout(3000);
      try {
        const [response, error] = yield votesApi.initialVotes(
          self.boothKey,
          self.key
        );
        if (error) throw error;
        // response could be null
        Object.values(response || []).forEach((vote: any) => {
          const newVote = VoteModel.create(vote);
          if (newVote.voter === rootStore.app.ship.patp) {
            self.results!.didVote = true;
          }
          self.results!.votes.set(vote.voter, newVote);
        });
        self.results!.generateResultSummary();
        self.loader.set("loaded");
      } catch (error) {
        self.loader.error(error.toString());
      }
    }),
    onVoteEffect(payload: EffectModelType | any, context: ContextModelType) {
      console.log("in vote effect, ", payload, context);
      const newVote = VoteModel.create(payload.data!);
      switch (payload.effect) {
        case "add":
          self.results!.votes.set(payload.key, newVote);
          self.results.generateResultSummary();
          break;
        case "update":
          const vote = self.results.votes.get(payload.key);
          vote!.status = payload.data.status;
          break;
      }
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
