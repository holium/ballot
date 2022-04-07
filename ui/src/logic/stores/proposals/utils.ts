import { ProposalModelType } from "./proposal";

export const getProposalFilters = (proposals: ProposalModelType[]) => {
  if (!proposals) return {};
  const countedStatuses = proposals.reduce<{ [key: string]: number }>(
    (counted, currentProposal, currentIndex) => {
      const status = currentProposal.status;
      // @ts-ignore
      counted[status] = counted[status] || 0;
      // @ts-ignore
      counted[status] += 1;
      return counted;
    },
    {}
  );
  return countedStatuses;
};

export function determineStatus(proposal: ProposalModelType) {
  let status: string = "Draft";
  if (proposal.status === "started") {
    status = "Active";
  }
  if (proposal.status === "counted") {
    status = "Ended";
  }
  if (proposal.status === "failed") {
    status = "Failed";
  }
  // if it doesnt have a status on the proposal, use the start and end time
  const now = new Date().getTime();
  const startTime = new Date(proposal.start * 1000).getTime();
  const endTime = new Date(proposal.end * 1000).getTime();
  if (startTime > now) {
    status = "Upcoming";
  }
  if (endTime < now) {
    status = "Ended";
  }

  if (startTime < now && now < endTime) {
    status = "Active";
  }
  return status;
}
