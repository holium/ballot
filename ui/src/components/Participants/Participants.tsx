import React, { FC, useState } from "react";
import { useParams } from "react-router-dom";
import { toJS } from "mobx";
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
import { ParticipantType } from "../../logic/types/participants";
import { getKeyFromUrl } from "../../logic/utils/path";
import { ParticipantModal } from "./Modal/ParticipantModal";
import { ParticipantRow } from "./ParticipantRow";

export const Container = styled(Card);

export type ParticipantsProps = {
  loading: boolean;
  participants: any[];
  onAdd: (patp: string) => any;
  onRemove: (patp: string) => any;
  onClick?: () => any;
};

export const Participants: FC<ParticipantsProps> = (
  props: ParticipantsProps
) => {
  const { loading, participants, onAdd, onRemove } = props;
  const { isShowing, toggle } = useDialog();
  const urlParams = useParams();
  const { store } = useMst();
  const [page, setPage] = useState(0);
  const pages =
    participants.length / 10 === 1 ? 0 : Math.floor(participants.length / 10);

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
        {participants && (
          <Grid2.Box pl="2px" pr="2px">
            <Grid2.Column noGutter>
              <Observer>
                {() => {
                  const startIndex = page * 10;
                  const endIndex = startIndex + 10;
                  return (
                    <>
                      {participants
                        .slice(startIndex, endIndex)
                        .sort((a: ParticipantType, b: ParticipantType) =>
                          a.status === b.status
                            ? 0
                            : a.status == "owner"
                            ? -1
                            : 1
                        )
                        .map((ship: ParticipantType) => (
                          <ParticipantRow
                            loading={
                              booth.checkAction(`invite-${ship.name}`) !==
                              "success"
                            }
                            status={ship.status}
                            canAdmin={
                              hasAdmin && !isGroup && ship.status !== "owner"
                            }
                            key={`${ship.name}-${getKeyFromUrl(urlParams)!}`}
                            patp={ship.name}
                            color={ship?.metadata?.color}
                            onRemove={onRemove}
                          />
                        ))}
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
