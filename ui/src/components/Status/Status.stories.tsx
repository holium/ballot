import React from "react";
import { ComponentMeta, ComponentStory } from "@storybook/react";
import { Status, StatusProps } from "./Status";

export default {
  title: "Components/Status",
  component: Status,
  parameters: {},
  argTypes: {
    status: {
      options: [
        "active",
        "succeeded",
        "ends soon",
        "defeated",
        "queued",
        "cancelled",
        "executed",
        "disputed",
        "user voted",
        "error",
      ],
      control: { type: "select" },
    },
  },
} as ComponentMeta<typeof Status>;

const Template: ComponentStory<typeof Status> = (args) => <Status {...args} />;

export const Active = Template.bind({});
Active.args = {
  status: "active",
};

export const Succeeded = Template.bind({});
Succeeded.args = {
  status: "succeeded",
};

export const EndingSoon = Template.bind({});
EndingSoon.args = {
  status: "ends soon",
};

export const Defeated = Template.bind({});
Defeated.args = {
  status: "defeated",
};

export const Queued = Template.bind({});
Queued.args = {
  status: "queued",
};

export const Cancelled = Template.bind({});
Cancelled.args = {
  status: "cancelled",
};

export const Executed = Template.bind({});
Executed.args = {
  status: "executed",
};

export const Disputed = Template.bind({});
Disputed.args = {
  status: "disputed",
};

export const UserVoted = Template.bind({});
UserVoted.args = {
  status: "user voted",
};
export const LoadingError = Template.bind({});
LoadingError.args = {
  status: "error",
};
