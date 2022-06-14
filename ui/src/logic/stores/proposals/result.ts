import { types, Instance, getParent } from "mobx-state-tree";
import {
  ChoiceModelType,
  ProposalModelType,
  TallyModel,
  TallyType,
  VoteModel,
  VoteModelType,
} from ".";
import votes from "../../api/votes";
import { BoothModelType } from "../booths";
import { rootStore } from "../root";

export const ResultSummaryModel = types.model({
  voteCount: types.optional(types.number, 0),
  participantCount: types.optional(types.number, 1),
  reason: types.maybeNull(types.string),
  status: types.optional(
    types.enumeration("ResultStatus", ["counted", "failed", "preliminary"]),
    "preliminary"
  ),
  topChoice: types.maybe(types.string),
  tallies: types.array(TallyModel),
});

export type ResultSummaryType = Instance<typeof ResultSummaryModel>;

export const ResultModel = types
  .model({
    didVote: types.optional(types.boolean, false),
    resultSummary: ResultSummaryModel,
    votes: types.map(VoteModel),
  })
  .views((self) => ({
    get voteCount() {
      const parent: ProposalModelType = getParent(self, 1);
      return Array.from(self.votes.values()).reduce(
        (count: number, voteRecord: any) => {
          const votingPower = rootStore.store.booths
            .get(parent.boothKey)!
            .delegateStore.getVotingPower(voteRecord.voter);
          count = count + votingPower;
          return count;
        },
        0
      );
    },
    get participantCount(): number {
      const parentBooth: BoothModelType = getParent(self, 4);
      return parentBooth.participantStore.count;
    },
    get getMyVote(): VoteModelType {
      // TODO clean this up
      let ourVote: any = null;
      Object.values(Object.fromEntries(self.votes.entries())).forEach(
        (vote: VoteModelType) => {
          if (
            Object.keys(Object.fromEntries(vote.delegators.entries())).includes(
              rootStore.app.ship.patp
            )
          ) {
            ourVote = vote;
          }
        }
      );
      if (ourVote) {
        return ourVote;
      }

      return self.votes.get(rootStore.app.ship.patp)!;
    },
  }))
  .actions((self) => ({
    setNewVote(vote: VoteModelType) {
      self.votes.set(vote.voter, vote);
    },
    generateResultSummary() {
      const parent: ProposalModelType = getParent(self, 1);
      const initialTally = parent.choices!.reduce(
        (initial: any, choice: ChoiceModelType) => {
          initial[choice.label] = 0;
          return initial;
        },
        {}
      );
      const voteArray = Array.from(self.votes.values());
      const tallyMap: any = voteArray.reduce(
        (tallyObj: any, vote: VoteModelType) => {
          const choiceLabel = vote.choice.label;
          const votingPower = rootStore.store.booths
            .get(parent.boothKey)!
            .delegateStore.getVotingPower(vote.voter);
          tallyObj[choiceLabel] = tallyObj[choiceLabel] + votingPower;
          return tallyObj;
        },
        initialTally
      );
      const participantCount = self.participantCount;

      const tallies: TallyType[] = Object.entries<number>(tallyMap)
        .map(([label, count]: [string, number]): TallyType => {
          return TallyModel.create({
            label,
            count,
            percentage: Math.round((count / participantCount) * 1000) / 10,
          });
        })
        .sort((a: TallyType, b: TallyType) => b!.count - a!.count);
      self.resultSummary = ResultSummaryModel.create({
        voteCount: self.voteCount,
        participantCount,
        topChoice: self.voteCount > 0 ? tallies[0].label : "None",
        tallies,
      });
      // return self.resultSummary;
    },
  }));

export type ResultModelType = Instance<typeof ResultModel>;
