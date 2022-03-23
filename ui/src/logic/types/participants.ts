type ParticipantActions = "invited" | "waiting" | "pending" | "joined";

export type ParticipantType = {
  name: string;
  status: ParticipantActions;
  metadata?: any;
  votingPower?: number;
};

export type ParticipantMap = Object & {
  [key: string]: ParticipantType;
};
