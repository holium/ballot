import { ObservableMap } from "mobx";
import { ChoiceType } from "./proposals";

export type VoteType = {
  status: "pending" | "recorded" | "counted";
  voter: string; // patp (~bus)
  choice: ChoiceType;
  signature?: string; //
  createdAt?: Date;
};
// export type VoteBoothMap = ObservableMap<string, VoteProposalMap>;
// export type VoteProposalMap = ObservableMap<string, VoteMap>;
// export type VoteMap = ObservableMap<string, VoteType>;

export type VoteMap = { [key: string]: VoteType } & Object;

// ObservableMap<string, ObservableMap<string, ObservableMap<string, VoteType>>>;
