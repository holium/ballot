import React, { FC } from "react";
import { toJS } from "mobx";
import {
  Text,
  KPI,
  TlonIcon,
  Skeleton,
  Flex,
  Tooltip,
  Card,
  Icons,
} from "@holium/design-system";
import { ProposalResultSection } from "./Detail.styles";
import {
  ChoiceModelType,
  ProposalModelType,
} from "../../../logic/stores/proposals";
import { BoothModelType } from "../../../logic/stores/booths";
import { failedReason } from "../../../logic/utils/poll-failed";
import { ActionDataTable } from "../../../components/VoteCard";

type ProposalResultType = {
  hideBorderBottom?: boolean;
  booth: BoothModelType;
  proposal: ProposalModelType;
};

export const ProposalResult: FC<ProposalResultType> = (
  props: ProposalResultType
) => {
  const { hideBorderBottom, booth, proposal } = props;
  let voteCount = proposal.results.resultSummary.voteCount || 0;
  let participantCount = booth.participantStore.count || 1;
  const tally = proposal.tally;
  if (tally) {
    voteCount = tally.voteCount;
    participantCount = tally.participantCount;
  }
  const percentage = Math.round((voteCount / participantCount) * 1000) / 10;

  return (
    tally && (
      <ProposalResultSection
        {...(hideBorderBottom && { style: { borderBottom: "none" } })}
      >
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
              {failedReason(tally)}
            </Text>
          </Flex>
        ) : (
          <Flex flexDirection="column">
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
            {/* <Flex
              mt={2}
              style={{ fontSize: 14 }}
              flexDirection="row"
              alignItems="center"
            >
              {winningChoice && (
                <ActionDataTable
                  action={winningChoice.action!}
                  data={winningChoice.data}
                />
              )}
            </Flex> */}
          </Flex>
        )}

        {proposal.isVoteLoading ? (
          <Skeleton style={{ height: 16, width: 60 }} />
        ) : (
          <Flex flexDirection="row" alignItems="center">
            <KPI
              icon={<TlonIcon icon="Users" />}
              value={`${voteCount}/${participantCount} (${percentage}%)`}
            />
          </Flex>
        )}
      </ProposalResultSection>
    )
  );
};
