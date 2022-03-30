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

import { pluralize } from "../../../logic/utils/text";
import { DelegationCard } from "../DelegationCard";
import { useMst } from "../../../logic/stores/root";
import { ParticipantModelType } from "../../../logic/stores/participants";
import { toJS } from "mobx";
import { observer } from "mobx-react";
import { getKeyFromUrl } from "../../../logic/utils/path";

export const DelegationList: FC = observer(() => {
  const { app, store } = useMst();
  const urlParams = useParams();
  const currentBooth = store.booths.get(getKeyFromUrl(urlParams))!;

  const participants = currentBooth.participantStore.list;
  const totalVotingPower = participants.length;

  return (
    <CenteredPane
      style={{ height: "100%", marginTop: 16 }}
      width={500}
      bordered={false}
    >
      <Header
        title="Delegation"
        subtitle={{ text: currentBooth.key, patp: true }}
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
        <DelegationCard votingPower={1} ship={app.ship!} />
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
                (participant: ParticipantModelType) =>
                  participant.name !== app.ship.patp
              )
              .map((participant: ParticipantModelType) => {
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
                        color={participant.metadata!.color || "#000000"}
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
});
