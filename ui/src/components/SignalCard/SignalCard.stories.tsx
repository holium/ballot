import React from "react";
import { ComponentMeta, ComponentStory, Story } from "@storybook/react";
import { useState } from "@storybook/addons";
import { SignalCard, SignalCardType } from "./SignalCard";
import { Flex } from "@holium/design-system";

export default {
  title: "Components/SignalCard",
  component: SignalCard,
  parameters: {},
  argTypes: {
    onClick: { action: "voted" },
  },
} as ComponentMeta<typeof SignalCard>;

const Template: ComponentStory<typeof SignalCard> = (args: SignalCardType) => (
  <Flex style={{ width: 600 }} flexDirection="column">
    <SignalCard {...args} />
  </Flex>
);

export const Default = Template.bind({});
Default.args = {
  proposal: {
    id: "1234",
    title: "Should we do a coachella trip?",
    body: "",
    hideIndividualVote: true,
    choices: [{ label: "Yes" }, { label: "Yes" }],
    author: { patp: "~lomder-librun", metadata: { color: "#ff810a" } },
    group: {
      name: "The River",
      uri: "~lomder-librun/the-river",
    },
    status: "active",
    strategy: "single-choice",
    start: new Date(
      "Wed Dec 20 2021 08:40:33 GMT-0600 (Central Standard Time)"
    ),
    end: new Date("Wed Jan 7 2022 08:40:33 GMT-0600 (Central Standard Time)"),
    support: 0.5,
    participants: [
      { patp: "~ronseg-hacsym" },
      { patp: "~hoppub-dirtux" },
      { patp: "~lorem-ipsum" },
    ],
  },
  onClick: (proposal: SignalCardType) => {
    console.log("clicked", proposal);
  },
  status: "active",
  entity: "ship",
  statusInfoValue: "8 days remaining",
};

export const EndingSoon = Template.bind({});
EndingSoon.args = {
  ...Default.args,
  status: "ends soon",
  statusInfoValue: "3 hours left",
};

export const Cancelled = Template.bind({});
Cancelled.args = {
  ...Default.args,
  status: "cancelled",
  statusInfoValue: "Cancelled by author",
  selectable: false,
};

export const UserVoted = Template.bind({});
UserVoted.args = {
  ...Default.args,
  status: "user voted",
  statusInfoValue: "Option 1 - Do the thing bruh",
  selectable: false,
};

export const LoadingError = Template.bind({});
LoadingError.args = {
  ...Default.args,
  status: "error",
  statusInfoValue: "There was a problem loading the data",
  selectable: false,
};
