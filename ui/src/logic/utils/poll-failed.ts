import { ResultSummaryType } from "./../stores/proposals";

export function failedReason(tally: ResultSummaryType) {
  switch (tally.reason) {
    case "support":
      return "Not enough support";
    case "tied":
      return "Tied";
    default:
      return "Not enough support"; // historically the fail reason was only not enough support
  }
}
