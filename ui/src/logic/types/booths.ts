import { ResourcePermissionType } from "./common";

export type BoothType = {
  key: string;
  created: string;
  image: any;
  meta: { [key: string]: any };
  name: string;
  owner: string;
  type: "group" | "ship" | string;
  status: "invited" | "pending" | string | null;
  permission: ResourcePermissionType;
};

export type BoothActionType = {
  action: BoothActions;
  reaction?: "ack" | "nawk" | "nod";
  resource: string;
  key: string;
  data: any;
};

export type BoothActions =
  | "invite"
  | "invite-effect"
  | "join"
  | "accept"
  | "accept-effect"
  | string;
