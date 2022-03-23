import { ObservableMap } from "mobx";
import { ShipType } from "../stores/ship";
import { ChoiceType } from "./proposals";

export type VoteType = {
  status: "pending" | "recorded" | "counted";
  voter: string; // patp (~bus)
  choice: ChoiceType;
  signature?: string; //
  createdAt?: Date;
};

export type VoteMap = ObservableMap<
  string,
  {
    [voter: string]: VoteType;
  }
>;
