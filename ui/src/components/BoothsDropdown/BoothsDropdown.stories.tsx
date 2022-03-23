import React from "react";
import { ComponentMeta, ComponentStory } from "@storybook/react";
import { BoothsDropdown, BoothDrowdownProps } from "./BoothsDropdown";

export default {
  title: "Components/BoothsDropdown",
  component: BoothsDropdown,
  parameters: {},
  argTypes: {
    // size: {
    //   options: ["small", "medium"],
    //   control: { type: "select" },
    // },
  },
} as ComponentMeta<typeof BoothsDropdown>;

const Template: ComponentStory<typeof BoothsDropdown> = (
  args: BoothDrowdownProps
) => (
  <div style={{ width: 250, height: 300 }}>
    <BoothsDropdown {...args} />
  </div>
);

export const Empty = Template.bind({});
Empty.args = {
  booths: [],
};

export const WithContexts = Template.bind({});
WithContexts.args = {
  booths: [
    {
      created: "d",
      image: null,
      meta: {},
      name: "~zod",
      owner: "~zod",
      type: "group",
      status: "invited",
    },
  ],
};
