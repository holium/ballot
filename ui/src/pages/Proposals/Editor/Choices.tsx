import React, { FC } from "react";
import {
  Button,
  Grid,
  IconButton,
  Icons,
  Input,
  Text,
  Box,
  Select,
} from "@holium/design-system";

export type ChoiceType = {
  order: number;
  label: string;
  action: string;
};

type ChoiceEditorProps = {
  choices: ChoiceType[];
  onUpdate: (elements: ChoiceType[]) => void;
};

export const ChoiceEditor: FC<ChoiceEditorProps> = (
  props: ChoiceEditorProps
) => {
  const buttonRef = React.createRef();
  const { choices, onUpdate } = props;

  const onAddChoice = (lastIndex: number) => {
    console.log(lastIndex);
    choices.push({
      order: lastIndex,
      label: "",
      action: "",
    });
    onUpdate([...choices]);
  };

  return (
    <Grid gridGap={2} pl={12} pr={12} pb={12}>
      {choices.map((choice: ChoiceType, index: number) => (
        <Input
          key={`index-${choice.label}-${index}`}
          leftIcon={index + 1}
          rightInteractive
          rightIcon={
            <Box>
              {/* TODO style select much better */}
              {/* <Select
                id={`action-${choice.label}-${index}`}
                small
                style={{ borderColor: "transparent" }}
                selectionOption={"none"}
                options={[
                  {
                    label: "Approve member",
                    value: "approve-member",
                  },
                  {
                    label: "Kick member",
                    value: "kick-member",
                  },
                ]}
                onSelected={() => {}}
              /> */}
              {/* <Text font mr={2}>Action goes here</Text> */}

              <IconButton
                onClick={() => {
                  choices.splice(index, 1);
                  onUpdate([...choices]);
                }}
              >
                <Icons.Close />
              </IconButton>
            </Box>
          }
          bg="ui.tertiary"
          placeholder="Choice text"
          defaultValue={choice.label}
          onBlur={(evt: any) => {
            let updatedChoice = choices[index];
            choices.splice(index, 1, {
              ...updatedChoice,
              label: evt.target.value,
            });
            onUpdate(choices);
          }}
          onChange={(evt: any) => {
            let updatedChoice = choices[index];
            choices.splice(index, 1, {
              ...updatedChoice,
              label: evt.target.value,
            });
            onUpdate(choices);
          }}
        />
      ))}
      {!choices.length && (
        <Text textAlign="center" p="12px 0" opacity={0.5}>
          Please add a choice
        </Text>
      )}
      <Box height="30px" justifyContent="center">
        <Button
          pt="4px"
          pb="4px"
          // @ts-ignore
          ref={buttonRef}
          variant="minimal"
          onClick={(evt: any) => {
            // @ts-ignore
            buttonRef.current.blur();
            onAddChoice(choices.length);
          }}
        >
          Add choice
        </Button>
      </Box>
    </Grid>
  );
};
