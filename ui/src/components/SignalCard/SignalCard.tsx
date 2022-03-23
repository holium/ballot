import React, { FC } from "react";
import { formatDistance } from "date-fns";
import { Flex, Card, Text, Button } from "@holium/design-system";
import { Status } from "../Status";
import { ProposalType } from "../../logic/types/proposals";
import { Author } from "../Author";
import { StatusInfo } from "../StatusInfo";
import { SignalOption } from "../SignalOption";
import { alignSelf } from "styled-system";

export type SignalCardType = {
  proposal: ProposalType;
  onClick: (proposalId: any) => any;
  status:
    | "active"
    | "succeeded"
    | "ends soon"
    | "defeated"
    | "queued"
    | "cancelled"
    | "executed"
    | "disputed"
    | "user voted"
    | "error";
  clickable?: boolean;
  entity: "group" | "ship";
  participantCount: number;
  totalMembers: number;
  options: Array<{
    choice: string;
  }>;
  selectable: boolean;
};

export const SignalCard: FC<SignalCardType> = (props: SignalCardType) => {
  const { proposal, onClick, clickable, status, entity, selectable } = props;
  const statusInfoValue = formatDistance(new Date(proposal.start), new Date(), {
    addSuffix: true,
  });

  return (
    <Flex flexDirection="column">
      <Card padding="8px" onClick={() => onClick(proposal)}>
        <Flex style={{ gap: 8 }} flexDirection="column">
          <Flex
            flexDirection={["column", "row", "row"]}
            justifyContent="space-between"
          >
            <Text variant="h6">
              {proposal.title ? proposal.title : "Loading..."}
            </Text>
            <Status status={status} />
          </Flex>
          {proposal.choices.map((choice, index) => (
            <SignalOption
              participantCount={0}
              totalMembers={123}
              option={Object.values(choice)}
              key={`choice-${index}`}
              SignalOption={"active"}
              selectable={selectable}
            />
          ))}

          <Flex
            flexDirection={["column", "row", "row"]}
            justifyContent="space-between"
            alignItems="center"
          >
            <StatusInfo status={status} value={statusInfoValue} />
            <Button variant="primary" css={undefined} mt={2}>
              Submit vote
            </Button>
          </Flex>
        </Flex>
      </Card>
      {/* <Author
        // patp={proposal.author.patp}
        // color={proposal.author.metadata?.color}
        size="small"
        clickable={clickable}
        entity={entity}
        noAttachments={true}
      /> */}
    </Flex>
  );
};
