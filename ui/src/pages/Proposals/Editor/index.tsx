import React, { FC, useMemo, useState, useEffect } from "react";
import { useNavigate, useParams } from "react-router";
import { Observer, observer } from "mobx-react";
import MDEditor from "@uiw/react-md-editor";
import rehypeSanitize from "rehype-sanitize";
import {
  ListHeader,
  CenteredPane,
  FormControl,
  Input,
  Flex,
  Card,
  Grid,
  Text,
  Label,
  Button,
  InlineEdit,
  Icons,
  Select,
  DateTimeInput,
  Box,
  BreadcrumbNav,
} from "@holium/design-system";

import { useStore } from "../../../logic/store";
import { createProposalFormFields } from "./CreateForm";
import { MarkdownEditor } from "../../../components/MarkdownEditor";
import { ChoiceEditor, ChoiceType } from "./Choices";
import { ProposalType } from "../../../logic/types/proposals";
import { createPath } from "../../../logic/utils/path";
import { toJS } from "mobx";
import { emptyState } from "./empty";
import { useMst } from "../../../logic/store-tree/root";

export const ProposalEditor: FC = observer(() => {
  const saveButton = React.createRef<HTMLButtonElement>();
  const navigate = useNavigate();
  const { store, app } = useMst();
  // const { appStore, proposalStore, boothStore } = useStore();
  const urlParams = useParams();

  let body = emptyState();
  const proposalStore = store.booth?.proposalStore!;
  let proposal: any = store.booth?.proposalStore!.proposals.get(
    urlParams.proposalId!
  )!;
  let isNew = urlParams.proposalId ? false : true;

  // This loads the form data or not for the editor
  if (
    urlParams.boothName &&
    urlParams.proposalId &&
    proposal &&
    proposal.isLoaded
  ) {
    const hasAdmin = store.booth!.hasAdmin;
    if (!hasAdmin) {
      navigate(
        createPath(
          {
            name: urlParams.boothName,
            type: urlParams.type!,
          },
          "proposals"
        )
      );
    }
    proposal = proposalStore.proposals.get(urlParams.proposalId)!;
  }

  const onBack = () => {
    let newPath = createPath(
      {
        name: urlParams.boothName!,
        type: urlParams.type!,
      },
      "proposals"
    );
    navigate(newPath);
    app.setCurrentUrl(newPath);
  };

  const onSubmit = async () => {
    let responseProposal: any;
    const proposalStore = store.booth!.proposalStore;

    // If editing an existing proposal
    if (urlParams.proposalId) {
      const proposal = proposalStore.proposals.get(urlParams.proposalId)!;
      responseProposal = await proposal.update(form.actions.submit());
    } else {
      responseProposal = await proposalStore.add(form.actions.submit());
    }

    if (isNew) {
      saveButton.current!.blur();
      let newPath = createPath(
        {
          name: urlParams.boothName!,
          type: urlParams.type!,
        },
        "proposals/editor",
        responseProposal.key
      );
      navigate(newPath);
      app.setCurrentUrl(newPath);
    }
  };

  const {
    form,
    title,
    content,
    strategy,
    startTime,
    redactVotes,
    endTime,
    support,
    choices,
  } = useMemo(
    () => createProposalFormFields(proposal),
    [proposal && proposal.isLoaded]
  );

  console.log(toJS(title));

  body =
    proposalStore && proposalStore.isLoaded ? (
      <Grid gridTemplateColumns="2fr 320px" gridColumnGap={12}>
        <Flex mb={12} flexDirection="column">
          <ListHeader
            title={
              <Observer>
                {() => {
                  return (
                    <InlineEdit
                      variant="h4"
                      pb={1}
                      pt={1}
                      // autoFocus={!urlParams.proposalId}
                      tabIndex={1}
                      fontWeight={600}
                      placeholder="Enter proposal title"
                      defaultValue={title.state.value}
                      // error={title.computed.ifWasEverBlurredThenError}
                      onChange={(e: any) =>
                        title.actions.onChange(e.target.value)
                      }
                      onFocus={() => title.actions.onFocus()}
                      onBlur={() => title.actions.onBlur()}
                    />
                  );
                }}
              </Observer>
            }
          />
          <FormControl.FieldSet pl={3} pr={3}>
            <Observer>
              {() => {
                return (
                  <FormControl.Field>
                    <MarkdownEditor>
                      <MDEditor
                        style={{ fontFamily: "Inter, sans-serif" }}
                        height={500}
                        preview="edit"
                        value={content.state.value}
                        defaultTabEnable={true}
                        textareaProps={{
                          tabIndex: 2,
                          placeholder: "Explain more about your proposal",
                          onFocus: () => content.actions.onFocus(),
                          onBlur: () => content.actions.onBlur(),
                        }}
                        onChange={(value: string | undefined) =>
                          content.actions.onChange(value)
                        }
                        previewOptions={{
                          rehypePlugins: [[rehypeSanitize]],
                          style: { fontFamily: "Inter, sans-serif" },
                        }}
                      />
                    </MarkdownEditor>
                  </FormControl.Field>
                );
              }}
            </Observer>
          </FormControl.FieldSet>
          <Card
            padding={0}
            mt={4}
            style={{ borderColor: "transparent" }}
            elevation="lifted"
            height="fit-content"
          >
            <Text fontWeight="600" variant="h6" p={12} mb={2}>
              Choices
            </Text>
            <Observer>
              {() => {
                return (
                  <ChoiceEditor
                    choices={choices.state.value}
                    onUpdate={(elements: ChoiceType[]) =>
                      choices.actions.onChange(elements)
                    }
                  />
                );
              }}
            </Observer>
          </Card>
        </Flex>
        <Grid gridTemplateRows="30px 1fr" gridGap={12}>
          <Flex height={30} justifyContent="flex-end" style={{ gap: 8 }}>
            {/* <Button py={1} variant="secondary">
            Save draft
          </Button> */}
            <Observer>
              {() => {
                return (
                  <Button
                    ref={saveButton}
                    py={1}
                    type="submit"
                    variant="minimal"
                    onClick={onSubmit}
                    disabled={form.computed.isError}
                  >
                    {isNew ? "Publish" : "Save"}
                  </Button>
                );
              }}
            </Observer>
          </Flex>
          <Card
            padding={0}
            style={{ borderColor: "transparent" }}
            elevation="lifted"
            height="fit-content"
          >
            <Text fontWeight="600" variant="h6" p={12} mb={2}>
              Configuration
            </Text>
            <Grid gridGap={2} pl={12} pr={12} pb={12}>
              <Observer>
                {() => {
                  return (
                    <FormControl.Field inline>
                      <Label>Strategy</Label>
                      <Box justifyContent="flex-end">
                        <Select
                          id="strategy"
                          tabIndex={3}
                          style={{ width: 162 }}
                          placeholder="Select..."
                          selectionOption={strategy.state.value}
                          gray={false}
                          options={[
                            {
                              label: "Single choice",
                              value: "single-choice",
                            },
                            {
                              label: "Multiple choice",
                              value: "multiple-choice",
                            },
                          ]}
                          onSelected={(option: any) => {
                            strategy.actions.onChange(option.value);
                          }}
                        />
                      </Box>
                    </FormControl.Field>
                  );
                }}
              </Observer>
              {/* Start time */}
              <Observer>
                {() => {
                  return (
                    <FormControl.Field inline>
                      <Label>Start</Label>
                      <Box justifyContent="flex-end">
                        <DateTimeInput
                          timePicker
                          inputId="startTime"
                          tabIndex={4}
                          minBookingDate={new Date()}
                          maxBookingDate={
                            endTime.state.value
                              ? new Date(endTime.state.value)
                              : undefined
                          }
                          onFocusChange={() => startTime.actions.onFocus()}
                          date={
                            startTime.state.value
                              ? new Date(startTime.state.value)
                              : new Date()
                          }
                          onDateChange={(data: any) => {
                            startTime.actions.onChange(data.date);
                          }}
                        />
                      </Box>
                    </FormControl.Field>
                  );
                }}
              </Observer>
              {/* End time */}
              <Observer>
                {() => {
                  return (
                    <FormControl.Field inline>
                      <Label>End</Label>
                      <Box justifyContent="flex-end">
                        <DateTimeInput
                          timePicker
                          inputId="endTime"
                          tabIndex={4}
                          minBookingDate={
                            startTime.state.value
                              ? new Date(startTime.state.value)
                              : new Date()
                          }
                          onFocusChange={() => endTime.actions.onFocus()}
                          date={endTime.state.value}
                          onDateChange={(data: any) => {
                            endTime.actions.onChange(data.date);
                          }}
                        />
                      </Box>
                    </FormControl.Field>
                  );
                }}
              </Observer>
              {/* Support required */}
              <Observer>
                {() => {
                  return (
                    <FormControl.Field inline>
                      <Label>Support</Label>
                      <Box justifyContent="flex-end">
                        <Input
                          style={{ width: 75 }}
                          type="number"
                          placeholder="ie. 50%"
                          tabIndex={5}
                          bg="ui.tertiary"
                          rightIcon={
                            <Icons.Percentage
                              size={1}
                              style={{ opacity: 0.5 }}
                              ml={"8px"}
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
            </Grid>
          </Card>
        </Grid>
      </Grid>
    ) : (
      emptyState()
    );

  return (
    <Box flexDirection="column">
      <BreadcrumbNav
        onBack={onBack}
        crumbs={[
          { label: "Proposals", onClick: onBack },
          { label: "Create New" },
        ]}
      />
      <CenteredPane width={1216} bordered={false}>
        {body}
      </CenteredPane>
    </Box>
  );
});
