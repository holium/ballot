type ParticipantActions =
  | "invited"
  | "waiting"
  | "pending"
  | "joined"
  | "owner";

export interface ParticipantType {
  name: string;
  status: ParticipantActions;
  metadata?: any;
  votingPower?: number;
}

export type ParticipantMap = Object & {
  [key: string]: ParticipantType;
};
