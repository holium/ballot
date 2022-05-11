import React, { FC, useEffect, useMemo } from "react";
import { useParams } from "react-router";
import { observer, Observer } from "mobx-react";
import { createField, createForm } from "mobx-easy-form";
import * as yup from "yup";
import {
  CenteredPane,
  Header,
  Flex,
  Icons,
  Text,
  Card,
  Box,
  FormControl,
  Label,
  Input,
  Select,
  Button,
} from "@holium/design-system";
import { getKeyFromUrl, getNameFromUrl } from "../../logic/utils/path";
import { useMst } from "../../logic/stores/root";

const createSettingsForm = (defaults: any = {}) => {
  const form = createForm({
    onSubmit({ values }) {
      return values;
    },
  });
  // const redactVotes = createField({
  //   id: "redacted",
  //   form,
  //   initialValue: defaults.redacted || "false",
  // });

  const proposalPermission = createField({
    id: "proposal-permission",
    form,
    initialValue: defaults.proposalPermission || "",
  });

  const duration = createField({
    id: "duration",
    form,
    initialValue: defaults.duration.toString() || "7",
    validationSchema: yup.number().required("Duration is required."),
  });

  const support = createField({
    id: "support",
    form,
    initialValue: defaults.support.toString() || "50",
    validationSchema: yup.number().required("Support is required."),
  });

  return { form, support, duration, proposalPermission };
};

const permissionMap: any = {
  owner: [],
  admin: ["admin"],
  "member-admin": ["member", "admin"],
};

const getSelectValueFromPermissions = (permissions: string[]) => {
  if (permissions.length === 0) {
    return "owner";
  } else if (permissions.length === 1) {
    return "admin";
  } else {
    return "member-admin";
  }
};

export const Settings: FC = observer(() => {
  const { store } = useMst();
  const urlParams = useParams();
  const saveButton = React.createRef<HTMLButtonElement>();

  const booth = store.booths.get(getKeyFromUrl(urlParams))!;

  useEffect(() => {
    booth.getCustomActions();
  }, []);

  const { form, support, duration, proposalPermission } = useMemo(
    () =>
      createSettingsForm({
        duration: booth.defaults!.duration,
        support: booth.defaults!.support,
        proposalPermission: getSelectValueFromPermissions(booth.permissions),
      }),
    []
  );

  const onSubmit = () => {
    const formData = form.actions.submit();
    const newSettings = {
      defaults: {
        duration: formData.duration,
        support: formData.support,
      },
      permissions: permissionMap[formData["proposal-permission"]],
    };
    booth.updateSettings(booth.key, newSettings);
  };

  const customActions = [];

  return (
    <CenteredPane
      style={{ height: "100%", marginTop: 16 }}
      width={500}
      bordered={false}
    >
      <Header
        title="Settings"
        subtitle={{ text: getNameFromUrl(urlParams), patp: true }}
      />
      <Card
        style={{ borderColor: "transparent" }}
        elevation="lifted"
        padding="16px"
        mt={3}
      >
        <Flex flexDirection="column" gap={2}>
          <Text fontWeight="600" variant="h6" mb={2}>
            Permissions
          </Text>
          {/* <Text variant="body" opacity={0.7} mb={2}>
            Sets different permissions for proposal actions.
          </Text> */}
          <FormControl.FieldSet pl={3} pr={3} mb={4}>
            <Observer>
              {() => {
                return (
                  <>
                    <FormControl.Field inline>
                      <Label>Create proposals</Label>
                      <Box flexDirection="column" alignItems="flex-end">
                        <Select
                          id="strategy"
                          tabIndex={5}
                          style={{ width: 175 }}
                          placeholder="Select..."
                          selectionOption={proposalPermission.state.value}
                          gray={false}
                          options={[
                            {
                              label: "Owner only",
                              value: "owner",
                            },
                            {
                              label: "Admins",
                              value: "admin",
                            },
                            {
                              label: "Members, Admins",
                              value: "member-admin",
                            },
                            // {
                            //   label: "Quadratic voting",
                            //   disabled: true,
                            //   value: "quadratic-voting",
                            // },
                          ]}
                          onSelected={(option: any) => {
                            proposalPermission.actions.onChange(option.value);
                          }}
                        />
                      </Box>
                    </FormControl.Field>
                  </>
                );
              }}
            </Observer>
          </FormControl.FieldSet>
          <Text fontWeight="600" variant="h6" mb={2}>
            Proposal defaults
          </Text>
          <Text variant="body" opacity={0.7} mb={2}>
            These set the defaults for a new proposal form.
          </Text>
          <FormControl.FieldSet pl={3} pr={3}>
            <Observer>
              {() => {
                return (
                  <FormControl.Field inline>
                    <Label>Quorum</Label>
                    <Box justifyContent="flex-end">
                      <Input
                        style={{ width: 75 }}
                        type="number"
                        placeholder="ie. 50%"
                        tabIndex={6}
                        bg="ui.tertiary"
                        rightIcon={
                          <Icons.Percentage
                            size={1}
                            style={{ opacity: 0.5 }}
                            color="text.primary"
                            aria-hidden
                          />
                        }
                        defaultValue={support.state.value}
                        // error={title.computed.ifWasEverBlurredThenError}
                        onChange={(e: any) =>
                          support.actions.onChange(e.target.value)
                        }
                        onFocus={() => support.actions.onFocus()}
                        onBlur={() => support.actions.onBlur()}
                      />
                    </Box>
                  </FormControl.Field>
                );
              }}
            </Observer>
            <Observer>
              {() => {
                return (
                  <FormControl.Field inline>
                    <Label>Duration</Label>
                    <Box justifyContent="flex-end">
                      <Input
                        style={{ width: 95 }}
                        type="number"
                        placeholder="ie. 7"
                        tabIndex={6}
                        bg="ui.tertiary"
                        rightIcon={
                          <Text fontSize={2} opacity={0.5}>
                            days
                          </Text>
                        }
                        defaultValue={duration.state.value}
                        // error={title.computed.ifWasEverBlurredThenError}
                        onChange={(e: any) =>
                          duration.actions.onChange(e.target.value)
                        }
                        onFocus={() => duration.actions.onFocus()}
                        onBlur={() => duration.actions.onBlur()}
                      />
                    </Box>
                  </FormControl.Field>
                );
              }}
            </Observer>
            <Observer>
              {() => {
                return (
                  <Button
                    ref={saveButton}
                    // isLoading={
                    //   (isNew && proposalStore.isAdding) ||
                    //   (!isNew && proposal.isLoading)
                    // }
                    mt={4}
                    type="submit"
                    variant="minimal"
                    onClick={onSubmit}
                    disabled={form.computed.isError}
                  >
                    Save
                  </Button>
                );
              }}
            </Observer>
          </FormControl.FieldSet>
        </Flex>
      </Card>
      <Card
        style={{ borderColor: "transparent" }}
        elevation="lifted"
        padding="16px"
        mt={3}
      >
        <Flex flexDirection="column" gap={2}>
          <Text fontWeight="600" variant="h6" mb={2}>
            Custom actions
          </Text>
          <Text variant="body" opacity={0.7} mb={2}>
            Hoon code that can be configured to execute via a proposal choice.
            You can add additional actions by following the guide{" "}
            <a target="_blank" href="https://www.holium.com">
              here
            </a>
            .
          </Text>
          {customActions.length === 0 && (
            <Text
              variant="body"
              style={{
                opacity: 0.6,
                height: 110,
                display: "flex",
                justifyContent: "center",
                alignItems: "center",
              }}
            >
              No custom actions
            </Text>
          )}
        </Flex>
      </Card>
    </CenteredPane>
  );
});
