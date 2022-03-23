import { ObservableMap } from "mobx";
import { ShipType } from "../stores/ship";

export type ChoiceType = {
  label: string;
  description?: string;
  action?: string;
};

export type ProposalType = {
  id?: any;
  key: string;
  owner: ShipType;
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
  createdBy?: ShipType; // potentially remove
  created?: string;
};

export type VoteType = {
  chosenVote: ChoiceType | undefined;
  proposalId?: string | undefined;
};

export type BallotType = {
  voter: ShipType;
  choice: ChoiceType;
  signature?: string;
  createdAt: Date;
};

export type ProposalMap = ObservableMap<string, ProposalType>;
