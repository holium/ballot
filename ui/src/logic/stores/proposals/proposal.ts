import {
  types,
  flow,
  Instance,
  SnapshotIn,
  getParent,
  getSnapshot,
  destroy,
  SnapshotOut,
  applyPatch,
  IJsonPatch,
  castToSnapshot,
  SnapshotOrInstance,
} from "mobx-state-tree";
import { type } from "os";
import { ChoiceModel, determineStatus, ResultModel, VoteModel } from ".";

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
    created: types.maybe(types.string),
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
    voteLoader: types.optional(LoaderModel, { state: "initial" }),
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
    get isVoteLoading() {
      return self.voteLoader.isLoading;
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
        self.loader.set("loading");
        const [response, error] = yield proposalsApi.update(
          self.boothKey,
          self.key,
          proposalForm
        );
        if (error) throw error;
        const validKeys = Object.keys(response.data).filter((key: string) =>
          self.hasOwnProperty(key)
        );
        const patches: IJsonPatch[] = validKeys.map((key: string) => {
          return {
            op: "replace",
            path: `/${key}`,
            value: response.data[key],
          };
        });

        // Add additional status patch
        patches.push({
          op: "replace",
          path: "/status",
          value: determineStatus(response.data),
        });
        applyPatch(self, patches);
        self.loader.set("loaded");
        return self;
      } catch (err: any) {
        self.loader.error(err);
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
      } catch (err: any) {
        self.loader.error(err);
      }
    }),

    getVotes: flow(function* () {
      self.voteLoader.set("loading");
      yield timeout(500);
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
        self.voteLoader.set("loaded");
      } catch (err: any) {
        self.voteLoader.error(err);
      }
    }),
    /**
     *
     * setVotes: sets the entire vote map
     *
     * @param {[voter: string]: VoteModelType} voteMap
     */
    setVotes(voteMap: any) {
      Object.values(voteMap || []).forEach((vote: any) => {
        const newVote = VoteModel.create(vote);
        if (newVote.voter === rootStore.app.ship.patp) {
          self.results!.didVote = true;
        }
        self.results!.votes.set(vote.voter, newVote);
      });
      self.results!.generateResultSummary();
      self.voteLoader.set("loaded");
    },
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

      const patches: IJsonPatch[] = validKeys.map((key: string) => {
        return {
          op: "replace",
          path: `/${key}`,
          value: update[key],
        };
      });

      // Add additional status patch
      patches.push({
        op: "replace",
        path: "/status",
        value: determineStatus(update),
      });

      applyPatch(self, patches);
      return self;
    },
  }));

export type ProposalModelType = Instance<typeof ProposalModel>;
