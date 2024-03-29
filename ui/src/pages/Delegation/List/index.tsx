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
import { observer } from "mobx-react";
import { getKeyFromUrl, getNameFromUrl } from "../../../logic/utils/path";
import { useMobile } from "../../../logic/utils/useMobile";

export const DelegationList: FC = observer(() => {
  const { app, metadata, store } = useMst();
  const isMobile = useMobile();
  const urlParams = useParams();
  const currentBooth = store.booths.get(getKeyFromUrl(urlParams))!;
  const delegateStore = currentBooth.delegateStore;

  const participants = currentBooth.participantStore.list;
  const totalVotingPower = participants.length;

  return (
    <CenteredPane
      style={{
        height: "100%",
        paddingTop: 16,
        overflowY: "scroll",
      }}
      width={isMobile ? "calc(100% - 24px)" : 500}
      bordered={false}
    >
      <Header
        title="Delegation"
        subtitle={{ text: getNameFromUrl(urlParams), patp: true }}
        rightContent={
          <Flex style={{ opacity: 0.7 }}>
            <Icons.Team mr={1} />
            <Text variant="body">
              {totalVotingPower} {pluralize("voter", totalVotingPower)}
            </Text>
          </Flex>
        }
      />
      <Flex flexDirection="column" pb={16}>
        <DelegationCard ship={app.account} />
        <Card
          style={{ borderColor: "transparent" }}
          elevation="lifted"
          padding="12px"
          mt={3}
        >
          <Text variant="h6" mb={3} fontWeight={500}>
            Top delegates
          </Text>
          {/* TODO make a standard participants list component */}
          {participants.length > 0 ? (
            participants
              .filter(
                (participant: ParticipantModelType) =>
                  participant.name !== app.ship.patp
              )
              .map((participant: ParticipantModelType) => {
                const participantVotingPower = delegateStore.getVotingPower(
                  participant.key
                ); // todo implement when delegaton backend is built
                const participantMetadata: any = metadata.contactsMap.get(
                  participant.name
                ) != null || {
                  color: "#000",
                };
                return (
                  <GenericRow key={participant.name}>
                    <Flex
                      flex={1}
                      justifyContent="space-between"
                      alignItems="center"
                    >
                      <Ship
                        patp={participant.name}
                        avatar={participantMetadata.avatar}
                        nickname={participantMetadata.nickname}
                        color={participantMetadata.color}
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
