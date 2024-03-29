import React, { FC, useState } from "react";
import {
  Flex,
  Box,
  Text,
  TextButton,
  MenuItem,
  Sigil,
  Spinner,
  Input,
  Icons,
} from "@holium/design-system";
import styled from "styled-components";
import { BoothType } from "../../logic/types/booths";
import { BoothModelType } from "../../logic/stores/booths";
import { Observer } from "mobx-react-lite";
import { rootStore } from "../../logic/stores/root";

export interface BoothDrowdownProps {
  booths: any[];
  onNewBooth: (...args: any) => any;
  onAccept: (boothName: string) => void;
  onJoin: (boothName: string) => void;
  onContextClick: (context: Partial<BoothModelType>) => any;
}

// const DropdownHeader = styled.div`
//   padding: 8px 8px 4px 8px;
//   display: flex;
//   flex-direction: row;
//   justify-content: space-between;
//   align-items: center;
// `;

const DropdownBody = styled.div``;

const EmptyGroup = styled.div`
  height: 32px;
  width: 32px;
  background: ${(p) => p.color || "#000"};
  border-radius: 4px;
`;

const sortOrderStatus = ["invited", "active", "enlisted", "pending"];
const sortOrderType = ["group", "ship"];
export const BoothsDropdown: FC<BoothDrowdownProps> = (
  props: BoothDrowdownProps
) => {
  const { booths, onContextClick, onJoin, onNewBooth, onAccept } = props;
  const [searchTerm, setSearchTerm] = useState("");
  const filterShipSearch = (booth: any) =>
    booth.type === "ship" &&
    ((booth.name &&
      booth.name.toLowerCase().includes(searchTerm.toLowerCase())) ||
      (booth.meta &&
        booth.meta.nickname &&
        booth.meta.nickname.toLowerCase().includes(searchTerm.toLowerCase())));

  const filterGroupSearch = (booth: any) =>
    booth.type === "group" &&
    ((booth.name &&
      booth.name.toLowerCase().includes(searchTerm.toLowerCase())) ||
      (booth.meta &&
        booth.meta.title &&
        booth.meta.title.toLowerCase().includes(searchTerm.toLowerCase())));

  const shipBooths = booths
    .filter((booth: BoothType) => booth.type === "ship")
    .filter(filterShipSearch);

  const groupBooths = booths
    .filter((booth: BoothType) => booth.type === "group")
    .filter(filterGroupSearch)
    .sort((a: BoothModelType, b: BoothModelType) => {
      if (
        // @ts-expect-error
        ((a.meta && a.meta.nickname) ||
          // @ts-expect-error
          a.name) < ((b.meta && b.meta.nickname) || b.name)
      ) {
        return -1;
      }
      if (
        // @ts-expect-error
        ((a.meta && a.meta.nickname) ||
          // @ts-expect-error
          a.name) < ((b.meta && b.meta.nickname) || b.name)
      ) {
        return 1;
      }
      return 0;
    });

  const boothsFiltered = [...shipBooths, ...groupBooths]
    .sort(
      (a: BoothModelType, b: BoothModelType) =>
        sortOrderType.indexOf(a.type) - sortOrderStatus.indexOf(b.type)
    )
    .sort(
      (a: BoothModelType, b: BoothModelType) =>
        sortOrderStatus.indexOf(a.status) - sortOrderStatus.indexOf(b.status)
    );

  return (
    <Flex
      width="300px"
      maxHeight="700px"
      style={{ position: "relative", overflowY: "scroll" }}
      flexDirection="column"
      onClick={(evt: any) => {
        evt.preventDefault();
        // evt.stopPropagation();
      }}
    >
      <Box
        style={{ position: "sticky", zIndex: 200 }}
        mt={1}
        ml={2}
        mr={2}
        mb={2}
      >
        <Input
          style={{ height: 34, borderRadius: 6 }}
          placeholder="Filter booths"
          value={searchTerm}
          leftIcon={<Icons.Search opacity={0.7} />}
          onChange={(evt: any) => setSearchTerm(evt.target.value)}
        />
      </Box>
      <DropdownBody>
        {boothsFiltered.map((booth: BoothModelType, index: number) =>
          booth.type === "group" ? (
            <GroupBooths
              key={`group-${index}`}
              group={booth}
              onContextClick={onContextClick}
              onJoin={onJoin}
            />
          ) : (
            <ShipBooths
              key={`ship-${index}`}
              ship={booth}
              onContextClick={onContextClick}
              onAccept={onAccept}
            />
          )
        )}
      </DropdownBody>
    </Flex>
  );
};

const ShipBooths = (props: {
  ship: any;
  onAccept: (boothName: string) => void;
  onContextClick: (context: any) => any;
}) => {
  const { ship, onContextClick, onAccept } = props;
  const needsAccepting = ship.status === "invited" || ship.status === "pending";
  // const [isExpanded, setIsExpanded] = useState(false);
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
            fontWeight="semiBold"
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
  onJoin: (boothName: string) => void;
  onContextClick: (...args: any) => any;
}) => {
  const { group, onContextClick, onJoin } = props;
  const [isExpanded, setIsExpanded] = useState(false);
  const needsConnecting =
    group.status !== "active" && group.status !== "pending";

  return (
    <MenuItem
      tabIndex={needsConnecting ? -1 : 0}
      style={{ padding: "8px 8px" }}
      type="neutral"
      disabled={group.status !== "active"}
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
              style={{ flex: 1, opacity: group.status !== "active" ? 0.3 : 1 }}
            >
              {group.meta.picture ? (
                <img
                  style={{ borderRadius: 4 }}
                  height="32px"
                  width="32px"
                  src={group.meta.picture}
                />
              ) : (
                <EmptyGroup color={group.meta.color} />
              )}
              <Box ml={2} flexDirection="column">
                <Text
                  style={{
                    display: "flex",
                    flexDirection: "row",
                    justifyContent: "space-between",
                  }}
                  fontSize={2}
                  fontWeight={600}
                  variant="body"
                >
                  {group.meta.title || group.name}

                  {/* TODO add notification */}
                  {/* <Icons.ExpandMore ml="6px" /> */}
                </Text>
                <Flex flexDirection="row">
                  <Text
                    fontWeight={500}
                    mt="1px"
                    mr={1}
                    opacity={0.6}
                    variant="hint"
                  >
                    Group
                  </Text>
                  <Text fontWeight={500} mt="1px" opacity={0.6} variant="hint">
                    {group.hasAdmin && "(owner)"}
                  </Text>
                </Flex>
              </Box>
            </Box>
            {group.status === "pending" && (
              <Text opacity={0.5} variant="hint">
                pending
              </Text>
            )}
            {group.status !== "active" && group.status !== "pending" && (
              <TextButton
                tabIndex={0}
                style={{ height: 24 }}
                data-prevent-menu-close
                onClick={(evt: any) => {
                  evt.preventDefault();
                  evt.stopPropagation();
                  onJoin(group.key);
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
