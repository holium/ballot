import { Flex } from "@holium/design-system";
import React from "react";
import { Participants } from ".";

export default {
  title: "Components/Participants",
  component: Participants,
  argTypes: { onClick: { action: "clicked" } },
};

// @ts-expect-error
const Template: Story = (args: ParticipantsProps) => {
  return (
    <Flex width="300px" height="364px">
      <Participants
        loading={args.loading}
        participants={args.data}
        onAdd={() => {}}
        onRemove={() => {}}
      />
    </Flex>
  );
};

export const Default = Template.bind({});
Default.args = {
  onClick: () => console.log("clicked"),
};

export const WithParticipants = Template.bind({});
WithParticipants.args = {
  onClick: () => console.log("clicked"),
  data: [
    {
      patp: "~lomder-librun",
      metadata: {
        color: "#4e9efd",
      },
    },
    {
      patp: "~lodlev-migdev",
      metadata: {
        color: "#6631FB",
      },
    },
    {
      patp: "~lomder-librun",
      metadata: {
        color: "#4e9efd",
      },
    },
    {
      patp: "~lodlev-migdev",
      metadata: {
        color: "#6631FB",
      },
    },
    {
      patp: "~lomder-librun",
      metadata: {
        color: "#4e9efd",
      },
    },
    {
      patp: "~lodlev-migdev",
      metadata: {
        color: "#6631FB",
      },
    },
  ],
};
