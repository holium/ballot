import React, { FC, useMemo } from "react";
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
import { toJS } from "mobx";
import { Observer } from "mobx-react";

import { Status } from "../Status";
import { descriptiveTimeString } from "../../logic/utils/time";
import { Author } from "../Author";
import { useMst } from "../../logic/stores/root";
import { ProposalModelType } from "../../logic/stores/proposals";

export type ProposalCardType = {
  proposal: ProposalModelType;
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
  const { proposal, onClick, clickable, status, entity, contextMenu } = props;
  const parentRef = React.useRef();
  const { store } = useMst();

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
        <Flex style={{ pointerEvents: "none" }} gap={4} flexDirection="column">
          <Flex
            flexDirection={["column", "row", "row"]}
            justifyContent={["flex-start", "space-between", "space-between"]}
            mb={["4px", "4px", "4px"]}
          >
            <Observer>
              {() => (
                <>
                  <ProposalTitle variant="h6">{proposal.title}</ProposalTitle>

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
                const voteCount =
                  proposalModel.results.resultSummary.voteCount || 0;
                const participantCount =
                  proposalModel.results.resultSummary.participantCount || 1;
                const percentage = useMemo(
                  () => Math.round((voteCount / participantCount) * 1000) / 10,
                  [voteCount, participantCount]
                );
                if (proposalModel.isVoteLoading) {
                  return <Skeleton style={{ height: 16, width: 60 }} />;
                }
                return (
                  <>
                    {status !== "Ended" ? (
                      <KPI
                        icon={<TlonIcon icon="Clock" />}
                        value={descriptiveTimeString(
                          proposal.start,
                          proposal.end
                        )}
                      />
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
                        <Text
                          ml={1}
                          fontSize={2}
                          fontWeight="500"
                          color="brand.primary"
                        >
                          {proposalModel.results.resultSummary.topChoice}
                        </Text>
                      </Flex>
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
      <Author
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
