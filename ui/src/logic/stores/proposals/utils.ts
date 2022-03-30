import { SnapshotOrInstance } from "mobx-state-tree";
import { ProposalModel, ProposalModelType } from "./proposal";

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

export function determineStatus(
  proposal: SnapshotOrInstance<typeof ProposalModel>
) {
  const now = new Date().getTime();
  const startTime = new Date(proposal.start).getTime();
  const endTime = new Date(proposal.end).getTime();

  let status: string = "Draft";
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
