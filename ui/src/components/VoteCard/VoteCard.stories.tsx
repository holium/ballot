import { Flex } from "@holium/design-system";
import React from "react";
import { VoteType } from "../../logic/types/proposals";

import { VoteCard, VoteCardProps } from "./VoteCard";

export default {
  title: "Components/VoteCard",
  component: VoteCard,

  argTypes: {
    onClick: {
      handleClick: {
        action: "clicked",
      },
    },
  },
};

// @ts-expect-error
const Template: Story = (args: VoteCardProps) => (
  <Flex style={{ gap: 4 }} flexDirection="row">
    <VoteCard
      choices={[
        {
          label: "Yes",
          description: "",
          action: "",
        },
        {
          label: "No",
          description: "",
          action: "",
        },
        {
          label: "Maybe",
          description: "",
          action: "",
        },
      ]}
      loading={args.loading}
      currentUser={args.currentUser}
      strategy={args.strategy}
      chosenOption={args.chosenOption}
      voteResults={args.voteResults}
      voteSubmitted={args.voteSubmitted}
    />
  </Flex>
);

export const Default = Template.bind({});
Default.args = {
  currentUser: {
    patp: "~lomder-librun",
    metadata: {
      color: "#F08735",
    },
  },
  strategy: "Single Choice",
  voteSubmitted: false,
  onVote: (chosenVote: VoteType) => console.log(chosenVote),
};

export const OptionChosen = Template.bind({});
OptionChosen.args = {
  currentUser: {
    patp: "~lomder-librun",
    metadata: {
      color: "#F08735",
    },
  },
  loading: true,
  voteSubmitted: false,
  strategy: "Single Choice",
  chosenOption: {
    chosenVote: {
      label: "Yes",
    },
    proposalId: "1",
  },
  onVote: (chosenVote: VoteType) => console.log(chosenVote),
};

export const VoteResults = Template.bind({});
VoteResults.args = {
  currentUser: {
    patp: "~lomder-librun",
    metadata: {
      color: "#F08735",
    },
  },
  strategy: "Single Choice",
  voteSubmitted: true,
  chosenOption: {
    chosenVote: {
      label: "Yes",
    },
    proposalId: "1",
  },
  voteResults: [
    {
      label: "Yes",
      results: 72,
    },
    {
      label: "No",
      results: 18,
    },
    {
      label: "Maybe",
      results: 10,
    },
  ],
};
