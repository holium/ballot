import { ObservableMap } from "mobx";

export type ChoiceType = {
  label: string;
  description?: string;
  action?: string;
};

export type ProposalType = {
  id?: any;
  key: string;
  owner: string;
  // group?: {
  //   name: string;
  //   uri: string;
  // };
  title: string;
  content: string;
  strategy: "single-choice" | "multiple-choice";
  redacted?: boolean;
  choices: ChoiceType[];
  tag?: string[];
  status: string;
  start: number;
  end: number;
  support: number;
  createdBy?: string; // potentially remove
  created?: string;
};

export type VoteType = {
  chosenVote: ChoiceType | undefined;
  proposalId?: string | undefined;
};

export type BallotType = {
  voter: string;
  choice: ChoiceType;
  signature?: string;
  createdAt: Date;
};

export type ProposalMap = ObservableMap<string, ProposalType>;
