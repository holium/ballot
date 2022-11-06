import React from "react";
import { ComponentMeta, ComponentStory } from "@storybook/react";
import { ProposalCard, ProposalCardType } from "./ProposalCard";
import { Flex } from "@holium/design-system";

export default {
  title: "Components/ProposalCard",
  component: ProposalCard,
  parameters: {},
} as ComponentMeta<typeof ProposalCard>;

const Template: ComponentStory<typeof ProposalCard> = (
  args: ProposalCardType
) => (
  <Flex style={{ width: 600 }} flexDirection="column">
    <ProposalCard {...args} />
  </Flex>
);

export const Default = Template.bind({});
Default.args = {
  proposal: {
    id: "1234",
    title:
      "At sed enim morbi vel purus libero ut. Id mauris placerat leo pretium. Gravida eget aliquam urna risus. Dignissim quam ipsum vulputate ut ut faucibus ut. Et varius arcu aliquet sed enim, tellus viverra vitae.",
    body: "",
    hideIndividualVote: true,
    // @ts-expect-error
    choices: [],
    author: { patp: "~lomder-librun", metadata: { color: "#ff810a" } },
    group: {
      name: "The River",
      uri: "~lomder-librun/the-river",
    },
    status: "active",
    strategy: "single-choice",
    start: new Date(
      "Wed Dec 20 2021 08:40:33 GMT-0600 (Central Standard Time)"
    ).getUTCHours(),
    end: new Date(
      "Wed Jan 7 2022 08:40:33 GMT-0600 (Central Standard Time)"
    ).getUTCHours(),
    support: 0.5,
    participants: [
      { patp: "~ronseg-hacsym" },
      { patp: "~hoppub-dirtux" },
      { patp: "~lorem-ipsum" },
    ],
  },
  onClick: (proposal: ProposalCardType) => {
    console.log("clicked", proposal);
  },
  status: "active",
  entity: "ship",
};

export const Succeeded = Template.bind({});
Succeeded.args = {
  ...Default.args,
  status: "succeeded",
  statusInfoValue: "Option 1 - Do the thing bruh",
};

export const EndsSoon = Template.bind({});
EndsSoon.args = {
  ...Default.args,
  status: "ends soon",
};

export const Defeated = Template.bind({});
Defeated.args = {
  ...Default.args,
  status: "defeated",
  statusInfoValue: "Minimum Quorum not reached",
};

export const Queued = Template.bind({});
Queued.args = {
  ...Default.args,
  status: "queued",
  statusInfoValue: "Executing in 2 days",
};

export const Cancelled = Template.bind({});
Cancelled.args = {
  ...Default.args,
  status: "cancelled",
  statusInfoValue: "Cancelled by author",
};

export const Executed = Template.bind({});
Executed.args = {
  ...Default.args,
  status: "executed",
  statusInfoValue: "Executed on February 1, 2022 08:00 CET",
};

export const Disputed = Template.bind({});
Disputed.args = {
  ...Default.args,
  status: "disputed",
  statusInfoValue: "Disputed on January 31, 2022 08:00 CET",
};

export const UserVoted = Template.bind({});
UserVoted.args = {
  ...Default.args,
  status: "user voted",
  statusInfoValue: "Option 1 - Do the thing bruh",
};

export const LoadingError = Template.bind({});
LoadingError.args = {
  ...Default.args,
  status: "error",
  statusInfoValue: "There was a problem loading the data",
};
