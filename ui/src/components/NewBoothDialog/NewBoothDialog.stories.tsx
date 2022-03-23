import React from "react";
import { ComponentMeta, ComponentStory } from "@storybook/react";
import { NewBoothDialog, NewBoothDailogProps } from "./NewBoothDialog";
import { Card } from "@holium/design-system";

export default {
  title: "Components/BoothsDropdown",
  component: NewBoothDialog,
  parameters: {},
  argTypes: {
    // size: {
    //   options: ["small", "medium"],
    //   control: { type: "select" },
    // },
  },
} as ComponentMeta<typeof NewBoothDialog>;

const Template: ComponentStory<typeof NewBoothDialog> = (
  args: NewBoothDailogProps
) => (
  <Card style={{ width: 500 }}>
    <NewBoothDialog {...args} />
  </Card>
);

export const Empty = Template.bind({});
Empty.args = {
  ships: [],
  groups: [],
};
