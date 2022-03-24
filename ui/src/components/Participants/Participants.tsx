import {
  Card,
  Flex,
  Grid,
  IconButton,
  Icons,
  Text,
  Dialog,
  useDialog,
} from "@holium/design-system";
import { toJS } from "mobx";
import { Observer } from "mobx-react";
import React, { FC } from "react";
import { useParams } from "react-router-dom";
import styled from "styled-components";
import { useStore } from "../../logic/store";
import { useMst } from "../../logic/store-tree/root";
import { ParticipantType } from "../../logic/types/participants";
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
  const booth = store.booth!;
  const hasAdmin = booth.hasAdmin;
  // console.log("rendering participants"); // todo prevent unnecessary render
  return (
    <Card
      elevation="lifted"
      p={0}
      minHeight={250}
      width={300}
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
        {hasAdmin && (
          <IconButton color="brand.primary" size={24} onClick={() => toggle()}>
            <Icons.AddUser />
          </IconButton>
        )}
      </Flex>
      {participants && (
        <Grid
          style={{
            gridTemplateColumns: "repeat(auto-fill, minmax(160px, 1fr))",
            width: "100%",
            gridGap: "8px",
          }}
        >
          <Observer>
            {() => {
              return (
                <>
                  {participants
                    .sort((a: ParticipantType, b: ParticipantType) =>
                      a.status === b.status ? 0 : a.status == "owner" ? -1 : 1
                    )
                    .map((ship: ParticipantType) => (
                      <ParticipantRow
                        loading={
                          booth.checkAction(`invite-${ship.name}`) !== "success"
                        }
                        status={ship.status}
                        canAdmin={hasAdmin && ship.status !== "owner"}
                        key={`${ship.name}-${urlParams.boothName!}`}
                        patp={ship.name}
                        color={ship?.metadata?.color}
                        onRemove={onRemove}
                      />
                    ))}
                </>
              );
            }}
          </Observer>
        </Grid>
      )}
      {!participants?.length && !loading && (
        <Grid style={{ placeItems: "center", height: "80%", opacity: 0.6 }}>
          <Text variant="body">No participants</Text>
        </Grid>
      )}
    </Card>
  );
};
