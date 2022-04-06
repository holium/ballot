import React, { FC, useState } from "react";
import {
  Flex,
  Box,
  Text,
  TextButton,
  MenuItem,
  Sigil,
  Spinner,
} from "@holium/design-system";
import styled from "styled-components";
import { BoothType } from "../../logic/types/booths";
import { toJS } from "mobx";
import { BoothModelType } from "../../logic/stores/booths";
import { Observer } from "mobx-react-lite";
import { rootStore } from "../../logic/stores/root";

export type BoothDrowdownProps = {
  booths: any[];
  onNewBooth: (...args: any) => any;
  onAccept: (boothName: string) => void;
  onContextClick: (context: Partial<BoothModelType>) => any;
};

const DropdownHeader = styled.div`
  padding: 8px 8px 4px 8px;
  display: flex;
  flex-direction: row;
  justify-content: space-between;
  align-items: center;
`;

const DropdownBody = styled.div``;

const EmptyGroup = styled.div`
  height: 24px;
  width: 24px;
  background: ${(p) => p.color || "#000"};
  border-radius: 4px;
`;

export const BoothsDropdown: FC<BoothDrowdownProps> = (
  props: BoothDrowdownProps
) => {
  const { booths, onContextClick, onNewBooth, onAccept } = props;
  const shipBooths = booths
    .filter((booth: BoothType) => booth.type === "ship")
    .map(
      (booth: BoothType): BoothType => ({
        ...booth,
        meta: {
          color: "#000000",
        },
      })
    );
  const groupBooths = booths.filter(
    (booth: BoothType) => booth.type === "group"
  );
  return (
    <Flex
      flexDirection="column"
      onClick={(evt: any) => {
        evt.preventDefault();
        evt.stopPropagation();
      }}
    >
      <DropdownHeader>
        <Text
          fontSize="14px"
          color="text.primary"
          style={{ textTransform: "uppercase", fontWeight: 600, opacity: 0.6 }}
        >
          Groups
        </Text>
      </DropdownHeader>
      <DropdownBody>
        {groupBooths.length ? (
          groupBooths.map((group: any, index: number) => {
            return (
              <GroupBooths
                key={`group-${index}`}
                group={group}
                onContextClick={onContextClick}
                onAccept={onAccept}
              />
            );
          })
        ) : (
          <Text
            style={{ height: 40, opacity: 0.4 }}
            display="flex"
            justifyContent="center"
            alignItems="center"
            textAlign="center"
            variant="caption"
          >
            No booths
          </Text>
        )}
      </DropdownBody>
      <DropdownHeader>
        <Text
          fontSize="14px"
          color="text.primary"
          style={{ textTransform: "uppercase", fontWeight: 600, opacity: 0.6 }}
        >
          Booths
        </Text>
      </DropdownHeader>
      <DropdownBody>
        {shipBooths.length ? (
          shipBooths.map((ship: any, index: number) => {
            return (
              <ShipBooths
                key={`ship-${index}`}
                ship={ship}
                onContextClick={onContextClick}
                onAccept={onAccept}
              />
            );
          })
        ) : (
          <Text
            style={{ height: 40, opacity: 0.4 }}
            display="flex"
            justifyContent="center"
            alignItems="center"
            textAlign="center"
            variant="caption"
          >
            No groups
          </Text>
        )}
      </DropdownBody>
      {/* NOTE: this was for open group joining or manual booth joining, removing for now */}
      {/* <Box ml={2} mt={2}>
        <TextButton
          style={{ fontSize: "14px", fontWeight: 500 }}
          onClick={onNewBooth}
        >
          Join new booth
        </TextButton>
      </Box> */}
    </Flex>
  );
};

const ShipBooths = (props: {
  ship: BoothType;
  onAccept: (boothName: string) => void;
  onContextClick: (context: any) => any;
}) => {
  const { ship, onContextClick, onAccept } = props;
  const needsAccepting = ship.status === "invited" || ship.status === "pending";
  const [isExpanded, setIsExpanded] = useState(false);
  const additionalMetadata = rootStore.metadata.contactsMap.get(ship.key)!;
  let meta = ship.meta;
  if (additionalMetadata) {
    meta = additionalMetadata;
  }
  return (
    <MenuItem
      tabIndex={needsAccepting ? -1 : 0}
      style={{ padding: "8px 8px" }}
      type="neutral"
      disabled={needsAccepting}
      onClick={(evt: any) => {
        onContextClick(ship);
        evt.preventDefault();
      }}
    >
      <Flex justifyContent="space-between" alignItems="center">
        <Box
          alignItems="center"
          style={{ flex: 1, opacity: needsAccepting ? 0.3 : 1 }}
        >
          <Sigil
            patp={ship.name}
            avatar={meta.avatar}
            clickable={false}
            size={24}
            color={[meta.color || "black", "white"]}
          />
          <Text
            style={{
              display: "flex",
              flexDirection: "row",
              justifyContent: "space-between",
            }}
            ml="8px"
            fontSize={2}
            fontWeight="medium"
            variant="body"
          >
            {meta.nickname || ship.name}
            {/* TODO add notification */}
            {/* <Icons.ExpandMore ml="6px" /> */}
          </Text>
        </Box>
        {needsAccepting &&
          (ship.status === "pending" ? (
            <Spinner ml={2} mr={2} size={0} />
          ) : (
            <TextButton
              style={{ height: 26 }}
              data-prevent-menu-close
              onClick={(evt: any) => {
                evt.preventDefault();
                evt.stopPropagation();
                onAccept(ship.name);
              }}
            >
              Accept
            </TextButton>
          ))}
      </Flex>
    </MenuItem>
  );
};

const GroupBooths = (props: {
  group: any;
  onAccept: (boothName: string) => void;
  onContextClick: (...args: any) => any;
}) => {
  const { group, onContextClick, onAccept } = props;
  const [isExpanded, setIsExpanded] = useState(false);
  const needsConnecting = group.status === "enlisted";

  return (
    <MenuItem
      tabIndex={needsConnecting ? -1 : 0}
      style={{ padding: "8px 8px" }}
      type="neutral"
      disabled={needsConnecting}
      onClick={(evt: any) => {
        onContextClick(group);
        evt.preventDefault();
      }}
    >
      <Observer>
        {() => (
          <Flex justifyContent="space-between" alignItems="center">
            <Box
              alignItems="center"
              style={{ flex: 1, opacity: needsConnecting ? 0.3 : 1 }}
            >
              {group.meta.picture ? (
                <img
                  style={{ borderRadius: 4 }}
                  height="24px"
                  width="24px"
                  src={group.meta.picture}
                />
              ) : (
                <EmptyGroup color={group.meta.color} />
              )}
              <Text
                style={{
                  display: "flex",
                  flexDirection: "row",
                  justifyContent: "space-between",
                }}
                ml="8px"
                fontSize={2}
                fontWeight="medium"
                variant="body"
              >
                {group.meta.title || group.name}
                {/* TODO add notification */}
                {/* <Icons.ExpandMore ml="6px" /> */}
              </Text>
            </Box>
            {needsConnecting && (
              <TextButton
                tabIndex={0}
                data-prevent-menu-close
                onClick={(evt: any) => {
                  evt.preventDefault();
                  evt.stopPropagation();
                  onAccept(group.key);
                }}
              >
                Join
              </TextButton>
            )}
          </Flex>
        )}
      </Observer>
    </MenuItem>
    // <div>
    //   <div onClick={() => setIsExpanded(!isExpanded)}>{ship.name}</div>
    //   {isExpanded && <div>Has booths</div>}
    // </div>
  );
};

// {
//   context.type === "ship" ? (
//     <Flex style={{ width: "100%", flex: 1 }}>
//       <Sigil
//         patp={context.ship.patp}
//         clickable
//         size={16}
//         borderRadiusOverride="2px"
//         color={[context.ship.color, "white"]}
//       />
//       <Text
//         style={{
//           display: "flex",
//           width: "100%",
//           flexDirection: "row",
//           justifyContent: "space-between",
//         }}
//         ml="8px"
//         variant="inherit"
//       >
//         {context.name}
//         {/* TODO add notification */}
//         {/* <Icons.ExpandMore ml="6px" /> */}
//       </Text>
//     </Flex>
//   ) : (
//     <Flex style={{ width: "100%", flex: 1 }}>
//       <img
//         style={{ borderRadius: 2 }}
//         height="16px"
//         width="16px"
//         src={ship.avatar}
//       />

//       <Text
//         style={{
//           display: "flex",
//           width: "100%",
//           flexDirection: "row",
//           justifyContent: "space-between",
//         }}
//         ml="8px"
//         variant="inherit"
//       >
//         {context.name}
//         {/* TODO add notification */}
//         {/* <Icons.ExpandMore ml="6px" /> */}
//       </Text>
//     </Flex>
//   );
// }
