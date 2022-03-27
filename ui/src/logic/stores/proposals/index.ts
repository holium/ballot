export * from "./choice";
export * from "./vote";
export * from "./tally";
export * from "./result";
export * from "./proposal";
export * from "./store";
export * from "./utils";
// import {
//   types,
//   flow,
//   Instance,
//   SnapshotIn,
//   getParent,
//   destroy,
//   SnapshotOut,
//   applyPatch,
//   IJsonPatch,
// } from "mobx-state-tree";

// import proposalsApi from "../../api/proposals";
// import votesApi from "../../api/votes";
// import { BoothModelType } from "../booths";
// import { ContextModelType, EffectModelType } from "../common/effects";

// import { LoaderModel } from "../common/loader";
// import { rootStore } from "../root";

// export const ChoiceModel = types
//   .model({
//     label: types.string,
//     description: types.maybeNull(types.string),
//     action: types.maybeNull(types.string),
//   })
//   .actions((self) => ({
//     setLabel: (label: string) => {
//       self.label = label;
//     },
//     setAction: (action: string) => {
//       self.action = action;
//     },
//   }));
// export type ChoiceModelType = Instance<typeof ChoiceModel>;

// export const VoteModel = types.model({
//   voter: types.string,
//   status: types.enumeration("VoteStatus", ["pending", "recorded", "counted"]),
//   choice: ChoiceModel,
//   signature: types.optional(types.string, ""),
//   created: types.maybeNull(types.string),
// });

// export type VoteModelType = Instance<typeof VoteModel>;

// export const TallyModel = types
//   .model({
//     label: types.string,
//     count: types.optional(types.number, 0),
//     percentage: types.optional(types.number, 0),
//   })
//   .named("TallyModel");

// export type TallyType = Instance<typeof TallyModel>;

// export const ResultSummaryModel = types.model({
//   voteCount: types.optional(types.number, 0),
//   participantCount: types.optional(types.number, 0),
//   topChoice: types.maybe(types.string),
//   tallies: types.array(TallyModel),
// });
// export type ResultSummaryType = Instance<typeof ResultSummaryModel>;

// export const ResultModel = types
//   .model({
//     didVote: types.optional(types.boolean, false),
//     resultSummary: ResultSummaryModel,
//     votes: types.map(VoteModel),
//   })
//   .views((self) => ({
//     get voteCount() {
//       return self.votes.size;
//     },
//     get participantCount(): number {
//       const parentBooth: BoothModelType = getParent(self, 4);
//       return parentBooth.participantStore.count;
//     },
//     get getMyVote(): VoteModelType {
//       return self.votes.get(rootStore.app.ship.patp)!;
//     },
//   }))
//   .actions((self) => ({
//     generateResultSummary() {
//       const parent: ProposalModelType = getParent(self, 1);
//       const initialTally = parent.choices!.reduce(
//         (initial: any, choice: ChoiceModelType) => {
//           initial[choice.label] = 0;
//           return initial;
//         },
//         {}
//       );
//       const voteArray = Array.from(self.votes.values());
//       const tallyMap: any = voteArray.reduce(
//         (tallyObj: any, vote: VoteModelType) => {
//           const choiceLabel = vote.choice.label;
//           tallyObj[choiceLabel] = tallyObj[choiceLabel] + 1;
//           return tallyObj;
//         },
//         initialTally
//       );
//       const participantCount = self.participantCount;

//       const tallies: TallyType[] = Object.entries<number>(tallyMap)
//         .map(([label, count]: [string, number]): TallyType => {
//           return TallyModel.create({
//             label,
//             count,
//             percentage:
//               Math.round((count / participantCount) * 1000 * 10) / 100,
//           });
//         })
//         .sort((a: TallyType, b: TallyType) => b!.count - a!.count);
//       self.resultSummary = ResultSummaryModel.create({
//         voteCount: self.voteCount,
//         participantCount,
//         topChoice: tallies[0].label,
//         tallies,
//       });
//       // return self.resultSummary;
//     },
//   }));

// export type ResultModelType = Instance<typeof ResultModel>;

// export const ProposalModel = types
//   .model({
//     boothKey: types.string,
//     key: types.identifier,
//     owner: types.string,
//     title: types.string,
//     content: types.string,
//     start: types.number,
//     end: types.number,
//     status: types.optional(types.string, "Draft"),
//     redacted: types.optional(types.boolean, false),
//     strategy: types.enumeration("Strategy", [
//       "single-choice",
//       "multiple-choice",
//     ]),
//     support: types.number,
//     choices: types.optional(types.array(ChoiceModel), [
//       { label: "Approve" },
//       { label: "Reject" },
//     ]),
//     loader: types.optional(LoaderModel, { state: "initial" }),
//     results: types.optional(ResultModel, {
//       didVote: false,
//       votes: {},
//       resultSummary: {
//         voteCount: 0,
//         participantCount: 0,
//         topChoice: undefined,
//         tallies: [],
//       },
//     }),
//   })
//   .views((self) => ({
//     get isLoaded() {
//       return self.loader.isLoaded;
//     },
//     get isLoading() {
//       return self.loader.isLoading;
//     },
//     get participantCount(): number {
//       const parentBooth: BoothModelType = getParent(self, 3);
//       return parentBooth.participantStore.count;
//     },
//   }))
//   .actions((self) => ({
//     addChoice: () => {
//       const newChoice = { label: "", action: "" };
//       self.choices.push(newChoice);
//       return newChoice;
//     },
//     removeChoice: (removeIndex: number) => {
//       self.choices.splice(removeIndex, 1);
//     },
//     update: flow(function* (proposalForm: Instance<typeof self>) {
//       try {
//         const [response, error] = yield proposalsApi.update(
//           self.boothKey,
//           self.key,
//           proposalForm
//         );
//         if (error) throw error;
//         const validKeys = Object.keys(response.data).filter((key: string) =>
//           self.hasOwnProperty(key)
//         );
//         const patches: IJsonPatch[] = validKeys.map((key: string) => ({
//           op: "replace",
//           path: `/${key}`,
//           value: response.data[key],
//         }));
//         applyPatch(self, patches);
//         return self;
//       } catch (error) {
//         self.loader.error(error.toString());
//         return;
//       }
//     }),
//     castVote: flow(function* (chosenVote: Instance<typeof VoteModel>) {
//       try {
//         const [response, error] = yield votesApi.castVote(
//           self.boothKey,
//           self.key,
//           chosenVote
//         );
//         if (error) throw error;
//         const voter = chosenVote.voter || rootStore.app.ship.patp;
//         self.results!.votes.set(voter, {
//           ...response.data,
//           status: "pending",
//           voter,
//         });
//         self.results!.didVote = true;
//         self.results.generateResultSummary();
//       } catch (error) {
//         self.loader.error(error.toString());
//       }
//     }),
//     getVotes: flow(function* () {
//       self.loader.set("loading");
//       try {
//         const [response, error] = yield votesApi.initialVotes(
//           self.boothKey,
//           self.key
//         );
//         if (error) throw error;
//         // response could be null
//         Object.values(response || []).forEach((vote: any) => {
//           const newVote = VoteModel.create(vote);
//           if (newVote.voter === rootStore.app.ship.patp) {
//             self.results!.didVote = true;
//           }
//           self.results!.votes.set(vote.voter, newVote);
//         });
//         self.results!.generateResultSummary();
//         self.loader.set("loaded");
//       } catch (error) {
//         self.loader.error(error.toString());
//       }
//     }),
//     onVoteEffect(payload: EffectModelType | any, context: ContextModelType) {
//       console.log("in vote effect, ", payload, context);
//       const newVote = VoteModel.create(payload.data!);
//       switch (payload.effect) {
//         case "add":
//           self.results!.votes.set(payload.key, newVote);
//           self.results.generateResultSummary();
//           break;
//         case "update":
//           const vote = self.results.votes.get(payload.key);
//           vote!.status = payload.data.status;
//           break;
//       }
//     },
//     updateEffect(update: any) {
//       const validKeys = Object.keys(update).filter((key: string) =>
//         self.hasOwnProperty(key)
//       );
//       const patches: IJsonPatch[] = validKeys.map((key: string) => ({
//         op: "replace",
//         path: `/${key}`,
//         value: update[key],
//       }));

//       applyPatch(self, patches);
//       return self;
//     },
//   }));

// export type ProposalModelType = Instance<typeof ProposalModel>;

// export const ProposalStore = types
//   .model({
//     boothKey: types.string,
//     loader: types.optional(LoaderModel, { state: "initial" }),
//     addLoader: types.optional(LoaderModel, { state: "initial" }),
//     proposals: types.map(ProposalModel),
//     activeProposal: types.optional(types.string, ""),
//   })
//   .views((self) => ({
//     get list() {
//       return Array.from(self.proposals.values());
//     },
//     get proposal() {
//       return self.proposals.get(self.activeProposal);
//     },
//     get isLoaded() {
//       return self.loader.isLoaded;
//     },
//   }))
//   .actions((self) => ({
//     // list call
//     getProposals: flow(function* () {
//       self.loader.set("loading");
//       try {
//         const [response, error] = yield proposalsApi.getAll(self.boothKey);
//         if (error) throw error;
//         // response could be null
//         Object.values(response || []).forEach((proposal: any) => {
//           const newProposal = ProposalModel.create({
//             ...proposal,
//             status: determineStatus(proposal),
//             boothKey: self.boothKey,
//           });
//           newProposal.getVotes();
//           self.proposals.set(newProposal.key, newProposal);
//           self.loader.set("loaded");
//         });
//       } catch (error) {
//         self.loader.error(error.toString());
//       }
//     }),
//     //
//     // add new resource
//     //
//     add: flow(function* (proposalForm: ProposalModelType) {
//       self.addLoader.set("loading");
//       try {
//         const [response, error] = yield proposalsApi.create(
//           self.boothKey,
//           proposalForm
//         );
//         if (error) throw error;
//         self.addLoader.set("loaded");
//         // response could be null
//         console.log("creating proposal ", response);
//         const newProposal = ProposalModel.create({
//           ...response.data,
//           status: determineStatus(response.data),
//           owner: rootStore.app.ship.patp,
//           boothKey: self.boothKey,
//         });
//         self.proposals.set(newProposal.key, newProposal);
//         return newProposal;
//       } catch (error) {
//         self.loader.error(error.toString());
//         return;
//       }
//     }),
//     //
//     // setActive
//     //
//     setActive(proposal: Instance<typeof ProposalModel>) {
//       self.activeProposal = proposal.key;
//     },
//     //
//     // remove
//     //
//     remove: flow(function* (proposalKey: string) {
//       try {
//         const [response, error] = yield proposalsApi.delete(
//           self.boothKey,
//           proposalKey
//         );
//         if (error) throw error;
//         const deleted = self.proposals.get(proposalKey)!;
//         self.proposals.delete(proposalKey);
//         destroy(deleted);
//       } catch (error) {
//         self.loader.error(error.toString());
//       }
//     }),
//     //
//     //
//     //
//     onEffect(payload: EffectModelType, context: ContextModelType) {
//       switch (payload.effect) {
//         case "add":
//           this.addEffect(payload.data);
//           break;
//         case "update":
//           this.updateEffect(payload.key!, payload.data);
//           break;
//         case "delete":
//           this.deleteEffect(payload.key!);
//           break;
//         case "initial":
//           // this.initialEffect(payload);
//           break;
//       }
//     },
//     initialEffect(proposalMap: any, voteMap: any) {
//       console.log("proposal initialEffect proposalMap ", proposalMap);
//       Object.keys(proposalMap).forEach((proposalKey: any) => {
//         const proposal = proposalMap[proposalKey];
//         const newProposal = ProposalModel.create({
//           ...proposal,
//           status: determineStatus(proposal),
//           boothKey: self.boothKey,
//         });
//         Object.keys(voteMap).forEach((voterKey: string) => {
//           const voteResult = voteMap[voterKey];
//           if (voteResult)
//             newProposal.results!.votes.set(
//               voteResult.voter,
//               VoteModel.create({
//                 ...voteResult,
//                 choice: ChoiceModel.create(voteResult.choice),
//               })
//             );
//         });
//         self.proposals.set(proposal.key, newProposal);
//       });
//     },

//     addEffect(proposal: any) {
//       console.log("proposal addEffect ", proposal);
//       self.proposals.set(
//         proposal.key,
//         ProposalModel.create({
//           ...proposal,
//           status: determineStatus(proposal),
//           boothKey: self.boothKey,
//         })
//       );
//     },
//     updateEffect(proposalKey: string, data: any) {
//       console.log("proposal updateEffect ", proposalKey, data);
//       const oldProposal = self.proposals.get(proposalKey)!;
//       const updated: any = oldProposal.updateEffect(data)!;
//       self.proposals.set(proposalKey, updated);
//     },
//     deleteEffect(proposalKey: string) {
//       console.log("proposal deleteEffect ", proposalKey);
//       self.proposals.delete(proposalKey);
//     },
//   }));

// function determineStatus(proposal: ProposalModelType) {
//   const now = new Date().getTime();
//   const startTime = new Date(proposal.start).getTime();
//   const endTime = new Date(proposal.end).getTime();

//   let status = "Draft";
//   if (startTime > now) {
//     status = "Upcoming";
//   }
//   if (endTime < now) {
//     status = "Ended";
//   }

//   if (startTime < now && now < endTime) {
//     status = "Active";
//   }
//   return status;
// }
