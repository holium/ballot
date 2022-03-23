import React, { FC } from "react";
import { Ship, Flex, Group } from "@holium/design-system";

export type AuthorType = {
  patp: string;
  color?: string;
  menuOptions?: Array<{
    label: string;
    value: string;
  }>;
  clickable?: boolean;
  size: string;
  entity: "ship" | "group";
  participantNumber?: number;
  participantType?: string;
  noAttachments?: boolean;
  name?: string;
};

export const Author: FC<AuthorType> = (props: AuthorType) => {
  const {
    patp,
    color,
    size,
    clickable,
    entity,
    participantNumber,
    participantType,
    noAttachments,
    name,
  } = props;

  const shipMenuOptions = [
    { label: "View profile info", value: "viewProfileInfo" },
    { label: "View all proposals", value: "viewAllProposals" },
  ];
  const groupMenuOptions = [
    { label: "View group info", value: "viewGroupInfo" },
    { label: "View all proposals", value: "viewAllProposals" },
  ];
  return (
    <Flex mt="2">
      {entity === "ship" ? (
        <Ship
          patp={patp}
          color={color}
          size="small"
          textOpacity={0.7}
          menuOptions={shipMenuOptions}
          clickable={clickable}
        />
      ) : (
        <Group
          patp={patp}
          name={name}
          color={color}
          menuOptions={groupMenuOptions}
          clickable={clickable}
          noAttachments={noAttachments}
          size={size}
          participantNumber={participantNumber}
          participantType={participantType}
          sigil={true}
        />
      )}
    </Flex>
  );
};
