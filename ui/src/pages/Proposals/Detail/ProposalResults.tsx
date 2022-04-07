import React, { FC } from "react";
import { Text, KPI, TlonIcon, Skeleton, Flex } from "@holium/design-system";
import { ProposalResultSection } from "./Detail.styles";
import { ProposalModelType } from "../../../logic/stores/proposals";

type ProposalResultType = {
  proposal: ProposalModelType;
};

export const ProposalResult: FC<ProposalResultType> = (
  props: ProposalResultType
) => {
  const { proposal } = props;
  const voteCount = proposal.results.resultSummary.voteCount || 0;
  const participantCount = proposal.results.resultSummary.participantCount || 1;
  const percentage = Math.round((voteCount / participantCount) * 1000) / 10;
  const tally = proposal.tally;

  return (
    tally && (
      <ProposalResultSection>
        {tally.status === "failed" ? (
          <Flex flexDirection="row" alignItems="center">
            <Text
              fontSize={2}
              opacity={0.7}
              variant="body"
              display="flex"
              flexDirection="row"
              alignItems="center"
            >
              Failed to pass:
            </Text>
            <Text ml={1} fontSize={2} fontWeight="500" color="ui.intent.alert">
              Not enough support
            </Text>
          </Flex>
        ) : (
          <Flex flexDirection="row" alignItems="center">
            <Text
              opacity={0.7}
              fontSize={2}
              variant="body"
              display="flex"
              flexDirection="row"
              alignItems="center"
            >
              Winning option:
            </Text>
            <Text
              ml={1}
              fontSize={2}
              variant="body"
              fontWeight="500"
              color="brand.primary"
            >
              {tally.topChoice}
            </Text>
          </Flex>
        )}

        {proposal.isVoteLoading ? (
          <Skeleton style={{ height: 16, width: 60 }} />
        ) : (
          <KPI
            icon={<TlonIcon icon="Users" />}
            value={`${voteCount}/${participantCount} (${percentage}%)`}
          />
        )}
      </ProposalResultSection>
    )
  );
};
