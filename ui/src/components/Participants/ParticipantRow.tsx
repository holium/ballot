import React from "react";
import {
  Ship,
  IconButton,
  Flex,
  Box,
  Icons,
  useMenu,
  Menu,
  Text,
  MenuItem,
  Spinner,
  GenericRow,
} from "@holium/design-system";

export type ParticipantRowProps = {
  loading?: boolean;
  patp: string;
  avatar?: string;
  nickname?: string;
  color: string;
  status: string;
  canAdmin?: boolean;
  onRemove: (patp: string) => any;
};

export const ParticipantRow = (props: ParticipantRowProps) => {
  const { avatar, nickname, loading, canAdmin, patp, color, status, onRemove } =
    props;

  const moreButtonRef = React.useRef();
  let anchorPoint: any,
    show: boolean = false,
    setShow: any;
  const menuWidth = 180;

  // if a user has the ability to edit participants
  if (canAdmin) {
    let config = useMenu(moreButtonRef, {
      orientation: "bottom-left",
      padding: 2,
      menuWidth,
    });
    anchorPoint = config.anchorPoint;
    show = config.show;
    setShow = config.setShow;
  }

  return (
    <GenericRow>
      <Flex style={{ flex: 1 }}>
        <Ship
          patp={patp}
          avatar={avatar}
          nickname={nickname}
          color={color || "#000000"}
          size="small"
          clickable={false}
        />
      </Flex>
      <Box alignItems="center">
        {status === "pending" ? (
          loading && (
            <Text opacity={0.5} variant="hint">
              pending
            </Text>
          )
        ) : (
          <Text mr={1} opacity={0.5} variant="hint">
            {status}
          </Text>
        )}
      </Box>

      {canAdmin && (
        <>
          <IconButton
            // @ts-ignore
            ref={moreButtonRef}
            id={`${patp}-more`}
            tabIndex={-1}
            size={24}
            onClick={(evt: any) => {
              !show && setShow && setShow(true);
            }}
          >
            <Icons.MoreLine />
          </IconButton>

          <Menu
            id="more-menu"
            style={{
              top: anchorPoint.y,
              left: anchorPoint.x,
              visibility: show ? "visible" : "hidden",
              width: menuWidth,
            }}
            isOpen={show}
            onClose={() => {
              setShow(false);
            }}
          >
            <MenuItem
              type="neutral"
              intent="alert"
              icon={<Icons.Close size={24} />}
              label="Kick"
              onClick={() => onRemove(patp)}
            />
          </Menu>
        </>
      )}
    </GenericRow>
  );
};
