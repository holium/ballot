import { appName } from "../../app";
import { BoothType2 } from "../store-tree/booths";
import { BoothType } from "../types/booths";

export const createPath = (
  booth: any,
  page: "proposals" | "delegate" | string = "proposals",
  proposalId: string = "",
  subPath: string = ""
) => {
  if (subPath) {
    subPath = `/${subPath}`;
  }
  if (proposalId) {
    proposalId = `/${proposalId}${subPath}`;
  }
  switch (booth.type) {
    case "ship":
      return `/apps/${appName}/booth/ship/${booth.name}/${page}${proposalId}`;
    case "group":
      return `/apps/${appName}/booth/group/${booth.name}/${page}${proposalId}`;
    default:
      return "`/apps/${appName}/booth/";
  }
};
