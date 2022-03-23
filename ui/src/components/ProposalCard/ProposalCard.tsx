import React, { FC } from "react";
import styled from "styled-components";
import { formatDistance } from "date-fns";
import {
  Flex,
  Card,
  Text,
  KPI,
  TlonIcon,
  ContextMenu,
  MenuItemProps,
} from "@holium/design-system";
import { Status } from "../Status";
import { ProposalType } from "../../logic/types/proposals";
import { descriptiveTimeString } from "../../logic/utils/time";
import { Author } from "../Author";
import { useStore } from "../../logic/store";

export type ProposalCardType = {
  proposal: ProposalType;
  onClick: (proposalId: any) => any;
  contextMenu: MenuItemProps[];
  status: string;
  clickable?: boolean;
  entity: "group" | "ship" | string;
  statusInfoValue?: string;
};

const ProposalTitle = styled(Text)`
  white-space: nowrap;
  width: 100%; /* IE6 needs any width */
  display: flex;
  flex-direction: row;
  align-items: center;
  font-weight: 500;
  overflow: hidden; /* "overflow" value must be different from  visible"*/
  -o-text-overflow: ellipsis; /* Opera < 11*/
  text-overflow: ellipsis; /* IE, Safari (WebKit), Opera >= 11, FF > 6 */
`;

export const ProposalCard: FC<ProposalCardType> = (props: ProposalCardType) => {
  const { proposal, onClick, clickable, status, entity, contextMenu } = props;
  const parentRef = React.useRef();
  const { participantStore, proposalStore } = useStore();
  const participantCount = participantStore.getParticipantCount(
    proposalStore.boothName!
  );
  const voteCount = 0; // TODO when vote is functioning
  // const timeRemaining = formatDistance(new Date(proposal.start), new Date(), {
  //   addSuffix: true,
  // });

  return (
    <Flex flexDirection="column" mb="12px">
      <Card
        id={proposal.key}
        ref={parentRef}
        padding="8px"
        selectable
        onClick={() => onClick(proposal)}
      >
        <ContextMenu
          menuItemtype="neutral"
          menu={contextMenu}
          containerId={proposal.key}
          parentRef={parentRef}
        />
        <Flex style={{ pointerEvents: "none" }} gap={8} flexDirection="column">
          <Flex
            flexDirection={["column", "row", "row"]}
            justifyContent="space-between"
            mb={["4px", "8px", "8px"]}
            style={{ gap: 8 }}
          >
            <ProposalTitle variant="h6">
              {proposal.title ? proposal.title : "Loading..."}
            </ProposalTitle>
            <Status status={status} />
          </Flex>
          <Flex
            flexDirection={["column", "row", "row"]}
            justifyContent="space-between"
          >
            {/* TODO robust status handling */}
            {status !== "Ended" ? (
              <KPI
                icon={<TlonIcon icon="Clock" />}
                value={descriptiveTimeString(proposal.start, proposal.end)}
              />
            ) : (
              <KPI value="Not enough support" />
            )}
            {/* {!statusInfoValue ? (
              <StatusInfo status={status} value={timeRemaining} />
            ) : (
              <StatusInfo status={status} value={statusInfoValue} />
            )} */}
            <KPI
              icon={<TlonIcon icon="Users" />}
              value={`${voteCount}/${participantCount} (0%)`}
            />
          </Flex>
        </Flex>
      </Card>
      <Author
        // @ts-ignore
        patp={proposal.owner}
        // color={proposal.author.metadata?.color}
        size="small"
        clickable={clickable}
        entity={"ship"}
        noAttachments={true}
      />
    </Flex>
  );
};
