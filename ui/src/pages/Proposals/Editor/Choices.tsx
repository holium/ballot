import React, { FC, useState } from "react";
import {
  Button,
  Grid,
  IconButton,
  Icons,
  Input,
  Text,
  Box,
  Select,
  Flex,
  FormControl,
  Tag,
} from "@holium/design-system";
import { runInAction } from "mobx";
import { getSnapshot } from "mobx-state-tree";
import { useMobile } from "../../../logic/utils/useMobile";

export interface ChoiceType {
  label: string;
  action: string;
  data: any;
}

interface ChoiceEditorProps {
  actions: any[];
  choices: ChoiceType[];
  onActionUpdate: (actions: any[]) => void;
  onUpdate: (elements: ChoiceType[]) => void;
}

export const ChoiceEditor: FC<ChoiceEditorProps> = (
  props: ChoiceEditorProps
) => {
  const isMobile = useMobile();
  const { actions, choices, onUpdate } = props;

  const buttonRef = React.createRef();
  const [actionMap, setAction] = useState(
    choices.reduce((map: any, choice: ChoiceType, index: number) => {
      map[index] = choice.action;
      return map;
    }, {})
  );
  const [actionConfigs, setActionConfigs] = useState<any>({});

  const onAddChoice = () => {
    runInAction(() => {
      choices.push({
        label: "",
        action: "",
        data: null,
      });
    });
    setAction({ ...actionMap, [choices.length]: "" });
    onUpdate([...choices]);
  };

  const onActionFormChange = (evt: any, index: number) => {
    // setActionConfigs({
    //   ...actionConfigs,
    //   form: actionConfigs[index].form,
    //   formValue: {
    //     ...actionConfigs[index].formValue,
    //     [evt.target.id]: evt.target.value,
    //   },
    // });
    const choiceData = choices[index];
    choiceData.data = {
      ...choiceData.data,
      [evt.target.id]: evt.target.value,
    };
    choices[index] = choiceData;
    onUpdate([...choices]);
  };

  const handleActionUpdate = (newActionMap: any, index: number) => {
    setAction(newActionMap);
    const actionConfig = actions.find(
      (customAction: any) => customAction.key === newActionMap[index]
    );
    if (actionConfig) {
      setActionConfigs({
        ...actionConfigs,
        [index]: {
          ...actionConfig,
          form: getSnapshot(actionConfig.form),
          // formValue: {},
        },
      });
      const choiceData = choices[index];
      choiceData.action = newActionMap[index];
      choices[index] = choiceData;
      onUpdate([...choices]);
    } else {
      const deleted = actionConfigs;
      delete deleted[index];
      setActionConfigs(deleted);
      const choiceData = choices[index];
      choiceData.action = "";
      choices[index] = choiceData;
      onUpdate([...choices]);
    }
    // onActionUpdate(activeActions);
  };

  const customActionOptions = [
    {
      label: "No action",
      value: "",
    },
    ...actions.map((action: any) => ({
      label: action.label,
      value: action.key,
    })),
  ];

  return (
    <Grid gridGap={2} pl={12} pr={12} pb={12}>
      {choices.map((choice: ChoiceType, index: number) => {
        const RemoveButton = (
          <IconButton
            onClick={() => {
              runInAction(() => {
                choices.splice(index, 1);
                delete actionMap[index];
              });
              onUpdate([...choices]);
              handleActionUpdate(actionMap, index);
            }}
          >
            <Icons.Close />
          </IconButton>
        );
        const ActionDropdown = (
          <Box alignItems="center">
            {/* TODO style select much better */}
            <Select
              id={`action-${choice.label}-${index}`}
              small
              style={{
                marginLeft: isMobile && 6,
                marginRight: 12,
              }}
              menuWidth={200}
              minWidth={120}
              pt={isMobile ? 2 : 1}
              pb={isMobile ? 2 : 1}
              bg="transparent"
              borderColor={!isMobile && "transparent"}
              placeholder="Set an action"
              flex={1}
              leftInteractive={false}
              leftIcon={
                <Text variant="body" opacity={0.7} mr={2} fontWeight="bold">
                  Action
                </Text>
              }
              selectionOption={actionMap[index]}
              options={customActionOptions}
              onSelected={(selected: any) => {
                const newActionMap = {
                  ...actionMap,
                  [index]: selected.value,
                };
                handleActionUpdate(newActionMap, index);
              }}
            />
            {/* <Text font mr={2}>Action goes here</Text> */}

            {!isMobile && RemoveButton}
          </Box>
        );
        return (
          <Flex
            mt={isMobile && 2}
            flexDirection="column"
            key={`index-${choice.label}-${index}`}
          >
            <Input
              tabIndex={index + 7} // 6 was the support % input tabIndex
              leftIcon={
                <Text variant="body" opacity={0.7} mr={2} fontWeight="bold">
                  {index + 1}
                </Text>
              }
              rightInteractive
              rightIcon={!isMobile ? ActionDropdown : RemoveButton}
              bg="ui.tertiary"
              placeholder="Choice text"
              defaultValue={choice.label}
              onBlur={(evt: any) => {
                const updatedChoice = choices[index];
                runInAction(() => {
                  choices.splice(index, 1, {
                    ...updatedChoice,
                    label: evt.target.value,
                  });
                });
                onUpdate(choices);
              }}
              onChange={(evt: any) => {
                const updatedChoice = choices[index];
                runInAction(() => {
                  choices.splice(index, 1, {
                    ...updatedChoice,
                    label: evt.target.value,
                  });
                });
                onUpdate(choices);
              }}
            />

            {isMobile && (
              <Flex width={"100%"} style={{ marginTop: 8 }} position="relative">
                {ActionDropdown}
              </Flex>
            )}
            {actionConfigs[index] && (
              <ActionConfigRow
                index={index}
                isMobile={isMobile}
                actionConfig={actionConfigs[index]}
                onChange={(evt: any) => onActionFormChange(evt, index)}
              />
            )}
          </Flex>
        );
      })}
      {choices.length === 0 && (
        <Text textAlign="center" p="12px 0" opacity={0.5}>
          Please add a choice
        </Text>
      )}
      <Box height="30px" justifyContent="center">
        <Button
          pt="4px"
          pb="4px"
          tabIndex={choices.length + 7}
          // @ts-expect-error
          ref={buttonRef}
          variant="minimal"
          onClick={(evt: any) => {
            // @ts-expect-error
            buttonRef.current.blur();
            onAddChoice();
          }}
        >
          Add choice
        </Button>
      </Box>
    </Grid>
  );
};

interface ActionConfigRowProps {
  index: number;
  isMobile?: boolean;
  actionConfig: any;
  onChange: (form: any) => void;
}

const ActionConfigRow: FC<ActionConfigRowProps> = (
  props: ActionConfigRowProps
) => {
  const { actionConfig, index, isMobile, onChange } = props;
  return (
    <Flex
      mt={2}
      mb={3}
      borderRadius={9}
      borderStyle="solid"
      borderWidth="1px"
      borderColor="ui.borderColor"
      flexDirection="column"
      // backgroundColor="ui.tertiary"
      ml={isMobile ? 4 : 8}
      p={12}
    >
      <Flex
        flexDirection="row"
        alignItems="center"
        justifyContent="space-between"
      >
        <Flex flexDirection="row" alignItems="center">
          <Tag label="Action" />
          <Text ml={3} fontSize={2} fontWeight="600">
            {actionConfig.label}
          </Text>
        </Flex>
        <Flex flexDirection="row" alignItems="center">
          <Text ml={2} mr={2} fontSize={2} opacity={0.7}>
            {actionConfig.key}.hoon
          </Text>
          {/* <IconButton icon="Code"></IconButton> */}
        </Flex>
      </Flex>
      <form
        id={`option-${index}-action-${actionConfig.key}`}
        onChange={(evt: any) => onChange(evt)}
      >
        {Object.keys(actionConfig.form).map((label) =>
          actionConfig.form[label].type === "cord" ? (
            <FormControl.Field mt={2} key={label}>
              <FormControl.Hint mt={1} mb={3}>
                {actionConfig.description || "Executes if winning choice."}
              </FormControl.Hint>
              <Input id={label} placeholder={label} />
            </FormControl.Field>
          ) : null
        )}
      </form>
    </Flex>
  );
};
