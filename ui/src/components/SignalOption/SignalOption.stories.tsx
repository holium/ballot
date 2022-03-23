import React from "react";
import { ComponentMeta, ComponentStory } from "@storybook/react";
import { SignalOption, SignalOptionProps } from "./SignalOption";

export default {
  title: "Components/SignalOption",
  component: SignalOption,
  parameters: {},
  argTypes: { onClick: { action: "clicked" } },
} as ComponentMeta<typeof SignalOption>;

const Template: ComponentStory<typeof SignalOption> = (args) => (
  <SignalOption {...args} />
);

export const Default = Template.bind({});
Default.args = {
  participantCount: 12,
  totalMembers: 123,
  option:
    "👍 At sed enim morbi vel purus libero ut. Id mauris placerat leo pretium. Gravida eget aliquam urna risus. Dignissim quam ipsum vulputate ut ut faucibus ut. Et varius arcu aliquet sed enim, tellus viverra vitae.",
};
