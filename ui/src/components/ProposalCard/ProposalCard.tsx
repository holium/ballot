import React, { FC, useEffect, useMemo, useState } from "react";
import styled from "styled-components";
import {
  Flex,
  Card,
  Text,
  KPI,
  TlonIcon,
  ContextMenu,
  MenuItemProps,
  Ship,
  Box,
} from "@holium/design-system";
import { toJS } from "mobx";
import { Observer } from "mobx-react";

import { Status } from "../Status";
import { descriptiveTimeString } from "../../logic/utils/time";
import { useMst } from "../../logic/stores/root";
import { ProposalModelType } from "../../logic/stores/proposals";
import { ContactModelType } from "../../logic/stores/metadata";

export type ProposalCardType = {
  proposal: ProposalModelType;
  onClick: (proposalId: any) => any;
  contextMenu: MenuItemProps[];
  status: string;
  clickable?: boolean;
  authorMetadata?: ContactModelType;
  entity: "group" | "ship" | string;
  statusInfoValue?: string;
};

const ProposalTitle = styled(Text)`
  white-space: nowrap;
  width: 100%; /* IE6 needs any width */
  display: flex;
  flex-direction: row;
  align-items: center;
  /* font-weight: 500; */
  overflow: hidden; /* "overflow" value must be different from  visible"*/
  -o-text-overflow: ellipsis; /* Opera < 11*/
  text-overflow: ellipsis; /* IE, Safari (WebKit), Opera >= 11, FF > 6 */
`;
const Skeleton = styled.div`
  width: 100%;
  /* height: 15px; */
  display: block;
  border-radius: 3px;
  background: linear-gradient(
      to right,
      rgba(197, 199, 204, 0),
      rgba(197, 199, 204, 0.3) 30%,
      rgba(197, 199, 204, 0) 50%
    ),
    lightgray;
  background-repeat: repeat-y;
  background-size: 50px 500px;
  background-position: 0 0;
  animation: shine 1s infinite;

  @keyframes shine {
    to {
      background-position: 100% 0;
    }
  }
`;

export const ProposalCard: FC<ProposalCardType> = (props: ProposalCardType) => {
  const { proposal, onClick, clickable, status, authorMetadata, contextMenu } =
    props;
  const parentRef = React.useRef();
  const { store } = useMst();
  //
  // Set the timer and get timeString
  //
  const { timeString } = descriptiveTimeString(proposal.start, proposal.end);
  const [time, setTime] = useState(timeString);
  let timerId: any = null;
  function timerUpdate() {
    const { timeString, timerInterval } = descriptiveTimeString(
      proposal.start,
      proposal.end
    );
    setTime(timeString);

    if (timerInterval !== null) {
      timerId = setTimeout(() => timerUpdate(), timerInterval);
    }
  }
  useEffect(() => {
    // initial timer
    timerUpdate();
    return function cleanup() {
      // Cleanup the timer on unmount
      clearTimeout(timerId);
    };
  }, []);

  // console.log(proposal.tally && proposal.tally.status);

  return (
    <Flex flexDirection="column" mb="12px">
      <Card
        id={proposal.key}
        ref={parentRef}
        borderThickness={1}
        padding="8px"
        selectable
        elevation="none"
        onClick={() => onClick(proposal)}
      >
        <ContextMenu
          menuItemtype="neutral"
          menu={contextMenu}
          containerId={proposal.key}
          parentRef={parentRef}
        />
        <Flex style={{ pointerEvents: "none" }} gap={4} flexDirection="column">
          <Flex
            flexDirection={["column", "row", "row"]}
            justifyContent={["flex-start", "space-between", "space-between"]}
            mb={["4px", "4px", "4px"]}
          >
            <Observer>
              {() => (
                <>
                  <ProposalTitle fontWeight="semiBold" variant="h6">
                    {proposal.title}
                  </ProposalTitle>
                  <Status status={status} />
                </>
              )}
            </Observer>
          </Flex>
          <Flex
            flexDirection={["column", "row", "row"]}
            justifyContent="space-between"
          >
            <Observer>
              {() => {
                const booth = store.booths!.get(store.activeBooth!)!;
                const proposalModel = booth?.proposalStore.proposals.get(
                  proposal.key
                )!;

                let voteCount =
                  proposalModel.results.resultSummary!.voteCount || 0;
                let participantCount = booth.participantStore.count || 1;

                if (proposalModel.isVoteLoading) {
                  return <Skeleton style={{ height: 16, width: 60 }} />;
                }
                if (proposal.tally) {
                  voteCount = proposal.tally.voteCount;
                  participantCount = proposal.tally.participantCount;
                }
                const percentage = useMemo(
                  () => Math.round((voteCount / participantCount) * 1000) / 10,
                  [voteCount, participantCount]
                );
                // setTime();

                return (
                  <>
                    {status !== "Ended" ? (
                      <KPI icon={<TlonIcon icon="Clock" />} value={time} />
                    ) : (
                      <TallyStatus proposal={proposalModel} />
                    )}

                    <KPI
                      icon={<TlonIcon icon="Users" />}
                      value={`${voteCount}/${participantCount} (${percentage}%)`}
                    />
                  </>
                );
              }}
            </Observer>
          </Flex>
        </Flex>
      </Card>
      <Box mt="6px">
        <Ship
          textOpacity={0.7}
          patp={proposal.owner}
          avatar={authorMetadata?.avatar}
          nickname={authorMetadata?.nickname}
          color={authorMetadata?.color || "#000000"}
          size="small"
          clickable={false}
        />
      </Box>
    </Flex>
  );
};

type TallyProps = {
  proposal: ProposalModelType;
};

const TallyStatus: FC<TallyProps> = (props: TallyProps) => {
  const { proposal } = props;
  proposal.tally?.status === "failed";
  const tally = proposal.tally!;

  return tally.status === "failed" ? (
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
        {/* TODO backend errors */}
        Not enough support
      </Text>
      {/* <Text ml={1} fontSize={2} fontWeight="500" color="ui.intent.alert">
        Not enough support (
        {`${
          Math.round((tally.voteCount / tally.participantCount) * 1000) / 10
        }% `}
        of
        {` ${proposal.support}%`})
      </Text> */}
    </Flex>
  ) : (
    <Flex flexDirection="row" alignItems="center">
      <Text
        fontSize={2}
        opacity={0.7}
        variant="body"
        display="flex"
        flexDirection="row"
        alignItems="center"
      >
        Winning option:
      </Text>
      <Text ml={1} fontSize={2} fontWeight="500" color="brand.primary">
        {tally.topChoice}
      </Text>
    </Flex>
  );
};
