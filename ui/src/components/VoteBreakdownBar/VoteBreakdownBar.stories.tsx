import { Flex } from "@holium/design-system";
import React from "react";
import { VoteBreakdownBar } from ".";

export default {
  title: "Components/VoteBreakdownBar",
  component: VoteBreakdownBar,
};

// @ts-ignore
const Template: Story = (args: VoteBreakdownBarProps) => (
  <Flex style={{ gap: 4 }} flexDirection="column" width="860px">
    <VoteBreakdownBar
      win={true}
      percentage={80}
      label="Yes"
      overlay={args.overlay}
      width={"860px"}
    />
    <VoteBreakdownBar
      win={false}
      percentage={12}
      label="No"
      overlay={args.overlay}
      width={"860px"}
    />
    <VoteBreakdownBar
      win={false}
      percentage={8}
      label="Maybe"
      overlay={args.overlay}
      width={"860px"}
    />
  </Flex>
);

export const Default = Template.bind({});
Default.args = {
  overlay: false,
};

export const Overlay = Template.bind({});
Overlay.args = {
  overlay: true,
};
