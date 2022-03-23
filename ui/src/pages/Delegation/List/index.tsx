import React, { FC } from "react";
import {
  Card,
  CenteredPane,
  Flex,
  Header,
  Icons,
  Ship,
  Text,
  GenericRow,
} from "@holium/design-system";
import { useParams } from "react-router";

import { useStore } from "../../../logic/store";
import { pluralize } from "../../../logic/utils/text";
import { DelegationCard } from "../DelegationCard";
import { ParticipantType } from "../../../logic/types/participants";
import { mapToList } from "../../../logic/utils/map";

export const DelegationList: FC = () => {
  const { participantStore, shipStore } = useStore();
  const urlParams = useParams();
  const currentBooth = urlParams.boothName!;
  const participants = mapToList(
    participantStore.participants.get(currentBooth)!
  );
  const totalVotingPower = participants.length + 1;

  return (
    <CenteredPane
      style={{ height: "100%", marginTop: 16 }}
      width={500}
      bordered={false}
    >
      <Header
        title="Delegation"
        subtitle={{ text: currentBooth, patp: true }}
        rightContent={
          <Flex style={{ opacity: 0.7 }}>
            <Icons.Team mr={1} />
            <Text variant="body">
              {totalVotingPower} {pluralize("voter", totalVotingPower)}
            </Text>
          </Flex>
        }
      />
      <Flex flexDirection="column">
        <DelegationCard votingPower={1} ship={shipStore.ship!} />
        <Card
          style={{ borderColor: "transparent" }}
          elevation="lifted"
          padding="12px"
          mt={3}
        >
          <Text variant="h6" mb={3} fontWeight={500}>
            Top delegates
          </Text>
          {participants.length ? (
            participants
              .filter(
                (participant: ParticipantType) =>
                  participant.name !== shipStore.ship?.patp
              )
              .map((participant: ParticipantType) => {
                const participantVotingPower = 1;
                return (
                  <GenericRow key={participant.name}>
                    <Flex
                      flex={1}
                      justifyContent="space-between"
                      alignItems="center"
                    >
                      <Ship
                        patp={participant.name}
                        color={participant.metadata?.color || "#000000"}
                        textOpacity={1}
                      />
                      <Text variant="body" opacity={0.7}>
                        {participantVotingPower}{" "}
                        {pluralize("vote", participantVotingPower)}
                      </Text>
                    </Flex>
                  </GenericRow>
                );
              })
          ) : (
            <Text
              variant="body"
              style={{
                opacity: 0.6,
                height: 110,
                display: "flex",
                justifyContent: "center",
                alignItems: "center",
              }}
            >
              No delegates
            </Text>
          )}
        </Card>
      </Flex>
    </CenteredPane>
  );
};
