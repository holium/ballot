import React, { FC, useState } from "react";
import { useParams } from "react-router-dom";
import { Observer } from "mobx-react";
import {
  Card,
  Flex,
  Grid,
  Grid2,
  IconButton,
  Icons,
  Text,
  Dialog,
  useDialog,
  Box,
} from "@holium/design-system";
import styled from "styled-components";
import { useMst } from "../../logic/stores/root";
import { getKeyFromUrl } from "../../logic/utils/path";
import { ParticipantModal } from "./Modal/ParticipantModal";
import { ParticipantRow } from "./ParticipantRow";
import { ParticipantModelType } from "../../logic/stores/participants";
import { toJS } from "mobx";

export const Container = styled(Card);

export type ParticipantsProps = {
  loading: boolean;
  participants: any[];
  onAdd: (patp: string) => any;
  onRemove: (patp: string) => any;
  onClick?: () => any;
};

const sortOrderType = ["active", "enlisted", "invited", "pending"];
const sortRole = ["owner", "participant"];

export const Participants: FC<ParticipantsProps> = (
  props: ParticipantsProps
) => {
  const { loading, participants, onAdd, onRemove } = props;
  const { isShowing, toggle } = useDialog();
  const urlParams = useParams();
  const { store, metadata } = useMst();
  const [page, setPage] = useState(0);
  let sortedParticipants = participants
    .sort((a: ParticipantModelType, b: ParticipantModelType) => {
      return sortOrderType.indexOf(b.type) - sortOrderType.indexOf(a.type);
    })
    .sort(
      (a: ParticipantModelType, b: ParticipantModelType) =>
        sortRole.indexOf(a.role) - sortRole.indexOf(b.role)
    );

  const pages =
    sortedParticipants.length / 10 === 1
      ? 0
      : Math.floor(sortedParticipants.length / 10);

  const booth = store.booth!;
  const isGroup = store.booth?.type === "group";
  const hasAdmin = booth.hasAdmin;
  // console.log("rendering participants"); // todo prevent unnecessary render
  return (
    <Card
      elevation="lifted"
      p="0px"
      minHeight={pages > 0 ? 480 : "initial"}
      width={"inherit"}
      style={{
        borderColor: "transparent",
      }}
    >
      <Dialog
        variant="simple"
        hasCloseButton
        closeOnBackdropClick
        title="Add participants"
        backdropOpacity={0.05}
        isShowing={isShowing}
        onHide={toggle}
      >
        <ParticipantModal
          onAdd={(patp: string) => {
            onAdd(patp);
            toggle();
          }}
        />
      </Dialog>
      <Flex
        width="100%"
        flexDirection="row"
        alignItems="center"
        justifyContent="space-between"
        height="40px"
        p="8px"
      >
        <Text variant="h6" fontWeight={500}>
          Participants
        </Text>
        {hasAdmin && !isGroup && (
          <IconButton color="brand.primary" size={24} onClick={() => toggle()}>
            <Icons.AddUser />
          </IconButton>
        )}
      </Flex>
      <Flex flex={1} justifyContent="space-between" flexDirection="column">
        {sortedParticipants && (
          <Grid2.Box pl="2px" pr="2px">
            <Grid2.Column noGutter>
              <Observer>
                {() => {
                  const startIndex = page * 10;
                  const endIndex = startIndex + 10;
                  return (
                    <>
                      {sortedParticipants
                        .slice(startIndex, endIndex)
                        .map((ship: ParticipantModelType) => {
                          const participantMetadata: any =
                            metadata.contactsMap.get(ship.name) || {
                              color: "#000",
                            };
                          const isOwner = ship.role === "owner";
                          return (
                            <ParticipantRow
                              loading={ship.status === "pending"}
                              status={isOwner ? "owner" : ship.status}
                              canAdmin={hasAdmin && !isGroup && !isOwner}
                              key={`${ship.name}-${getKeyFromUrl(urlParams)!}`}
                              patp={ship.name}
                              avatar={participantMetadata.avatar}
                              nickname={participantMetadata.nickname}
                              color={participantMetadata.color}
                              onRemove={onRemove}
                            />
                          );
                        })}
                    </>
                  );
                }}
              </Observer>
            </Grid2.Column>
          </Grid2.Box>
        )}
        {pages > 0 && (
          <Flex
            mt={2}
            ml={1}
            mr={1}
            position="relative"
            justifyContent="space-between"
            alignItems="center"
            justifySelf="flex-end"
          >
            <Box top="4px" left="8px" right="unset" bottom="unset">
              <IconButton
                disabled={page <= 0}
                onClick={() => page > 0 && setPage(page - 1)}
              >
                <Icons.AngleLeft />
              </IconButton>
            </Box>
            <Box>
              <Text opacity={0.7} variant="hint">
                {" "}
                {`${page + 1} of ${pages + 1}`}
              </Text>
            </Box>
            <Box top="4px" left="unset" right="8px" bottom="unset">
              <IconButton
                disabled={page >= pages}
                onClick={() => page < pages && setPage(page + 1)}
              >
                <Icons.AngleRight />
              </IconButton>
            </Box>
          </Flex>
        )}
      </Flex>
      {!participants?.length && !loading && (
        <Grid style={{ placeItems: "center", height: "80%", opacity: 0.6 }}>
          <Text variant="body">No participants</Text>
        </Grid>
      )}
    </Card>
  );
};
