import React from "react";
import { ComponentMeta, ComponentStory } from "@storybook/react";
import { Author } from "./Author";

export default {
  title: "Components/Author",
  component: Author,
  parameters: {},
  argTypes: {
    size: {
      options: ["small", "medium"],
      control: { type: "select" },
    },
  },
} as ComponentMeta<typeof Author>;

const Template: ComponentStory<typeof Author> = (args) => <Author {...args} />;

export const Ship = Template.bind({});
Ship.args = {
  patp: "~lomder-librun",
  color: "#ff810a",
  size: "small",
  clickable: true,
  entity: "ship",
};

export const Group = Template.bind({});
Group.args = {
  ...Ship.args,
  entity: "group",
  size: "medium",
  participantNumber: 12,
  participantType: "holons",
  noAttachments: true,
  patp: "~lomder-librun",
  name: "Holons",
  color: "#ff810a",
  clickable: true,
};
