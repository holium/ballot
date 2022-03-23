import React from "react";
import { ComponentMeta, ComponentStory } from "@storybook/react";
import { StatusInfo } from "./StatusInfo";
import { TlonIcon } from "@holium/design-system";

export default {
  title: "Components/StatusInfo",
  component: StatusInfo,
  parameters: {},
  argTypes: {},
} as ComponentMeta<typeof StatusInfo>;

const Template: ComponentStory<typeof StatusInfo> = (args) => (
  <StatusInfo value={args.value} status={args.status} label={args.label} />
);

export const Succeeded = Template.bind({});
Succeeded.args = {
  label: "Successful voting option",
  value: "Option 1 - Do the thing bruh",
  status: "succeeded",
};

export const Voted = Template.bind({});
Voted.args = {
  label: "Vote chosen",
  value: "Option 1 - Do the thing bruh",
  status: "user voted",
};

export const Defeated = Template.bind({});
Defeated.args = {
  value: "Minimum Quorum not reached",
  status: "defeated",
  label: "Proposal failed",
};

export const Cancelled = Template.bind({});
Cancelled.args = {
  label: "Reason for cancelling",
  value: "Cancelled by author",
  status: "cancelled",
};

export const LoadingError = Template.bind({});
LoadingError.args = {
  label: "Error",
  value: "There was a problem loading the data",
  status: "error",
};

export const Disputed = Template.bind({});
Disputed.args = {
  value: "Disputed on January 31, 2022 08:00 CET",
  status: "disputed",
  label: "Dispute Initialised",
};

export const Active = Template.bind({});
Active.args = {
  value: "8 days left",
  status: "active",
  label: "Time remaining",
};

export const EndsSoon = Template.bind({});
EndsSoon.args = {
  value: "3 hours left",
  status: "ends soon",
  label: "Time remaining",
};

export const Queued = Template.bind({});
Queued.args = {
  value: "Executing in 2 days",
  status: "queued",
  label: "Time remaining",
};

export const Executed = Template.bind({});
Executed.args = {
  value: "Executed on February 1, 2022 08:00 CET",
  status: "executed",
  label: "Action execution date",
};
