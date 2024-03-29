import React, { FC, useCallback, useEffect, useMemo } from "react";
import { useNavigate, useParams } from "react-router";
import { Observer, observer } from "mobx-react";
import MDEditor, { ICommand } from "@uiw/react-md-editor";
import rehypeSanitize from "rehype-sanitize";
import {
  ListHeader,
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
  Grid2,
} from "@holium/design-system";

import { createProposalFormFields } from "./CreateForm";
import { MarkdownEditor } from "../../../components/MarkdownEditor";
import { ChoiceEditor, ChoiceType } from "./Choices";
import { createPath, getKeyFromUrl } from "../../../logic/utils/path";
import { emptyState } from "./empty";
import { useMst } from "../../../logic/stores/root";
import { useMobile } from "../../../logic/utils/useMobile";

export const ProposalEditor: FC = observer(() => {
  const saveButton = React.createRef<HTMLButtonElement>();
  const navigate = useNavigate();
  const isMobile = useMobile();
  const { store, app } = useMst();
  const urlParams = useParams();
  // const [actionConfigs, setActionConfigs] = useState([]);

  let body = emptyState();
  const booth = store.booth!;
  useEffect(() => {
    booth.getCustomActions();
  }, []);
  const proposalStore = store.booth?.proposalStore!;
  let proposal: any = store.booth?.proposalStore!.proposals.get(
    urlParams.proposalId!
  )!;
  const isNew = !urlParams.proposalId;

  // This loads the form data or not for the editor
  if (
    urlParams.boothName &&
    urlParams.proposalId &&
    proposal &&
    proposal.isLoaded
  ) {
    const hasAdmin = store.booth!.hasAdmin;
    if (!hasAdmin) {
      navigate(createPath(getKeyFromUrl(urlParams), "proposals"));
    }
    proposal = proposalStore.proposals.get(urlParams.proposalId)!;
  }

  const onBack = () => {
    const newPath = createPath(getKeyFromUrl(urlParams), "proposals");
    navigate(newPath);
    app.setCurrentUrl(newPath);
  };

  let initialForm = proposal;

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
    saveButton.current != null && saveButton.current.blur();
    if (isNew) {
      saveButton.current != null && saveButton.current.blur();
      const newPath = createPath(getKeyFromUrl(urlParams), "proposals");
      navigate(newPath);
      app.setCurrentUrl(newPath);
    }
  };

  // Filters commands out of the toolbar when in mobile
  const filterCommands = useCallback(
    (command: ICommand<string>, isExtra: boolean) => {
      if (isMobile && isExtra) {
        return false;
      }
      return command;
    },
    [isMobile]
  );

  if (isNew) {
    initialForm = {
      ...initialForm,
      support: booth.defaults?.support,
      duration: booth.defaults?.duration,
    };
  }

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
    () => createProposalFormFields(initialForm),
    [proposal, proposal && proposal.isLoaded, booth.customActions.length]
  );

  body =
    proposalStore && proposalStore.isLoaded ? (
      <Grid2.Row>
        <Grid2.Column mb="12px" md={5} lg={8} xl={8}>
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
                const isMobileMode = isMobile;
                return (
                  <FormControl.Field>
                    <MarkdownEditor>
                      <MDEditor
                        style={{ fontFamily: "Inter, sans-serif" }}
                        height={500}
                        preview="edit"
                        value={content.state.value}
                        defaultTabEnable={true}
                        commandsFilter={filterCommands}
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
                    actions={booth.customActions}
                    choices={choices.state.value}
                    onActionUpdate={(activeActions: any) => {
                      // setActionConfigs(activeActions);
                    }}
                    onUpdate={(elements: ChoiceType[]) =>
                      choices.actions.onChange(elements)
                    }
                  />
                );
              }}
            </Observer>
          </Card>
        </Grid2.Column>
        <Grid2.Column reverse={["xs"]} mb="12px" sm={3} md={3} lg={4} xl={4}>
          <Flex
            height={30}
            mb="12px"
            justifyContent="flex-end"
            style={{ gap: 8 }}
          >
            {/* <Button py={1} variant="secondary">
            Save draft
          </Button> */}
            <Observer>
              {() => {
                return (
                  <Button
                    ref={saveButton}
                    isLoading={
                      (isNew && proposalStore.isAdding) ||
                      (!isNew && proposal.isLoading)
                    }
                    py={1}
                    tabIndex={choices.state.value.length + 8}
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
            mb="12px"
            style={{ borderColor: "transparent" }}
            elevation="lifted"
            height="fit-content"
          >
            <Text fontWeight="600" variant="h6" p={12} mb={2}>
              Voting
            </Text>
            <Grid gridGap={2} pl={12} pr={12} pb={12}>
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
                          tabIndex={3}
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
                            // TODO we need a refactor of the date component
                            // if we try to put a time before the start date, set to start date
                            const startDate = new Date(startTime.state.value);
                            if (
                              data.date &&
                              data.date.valueOf() <=
                                new Date(startTime.state.value).valueOf()
                            ) {
                              startDate.setMinutes(startDate.getMinutes() + 1); // set to one minute after start time
                              endTime.actions.onChange(startDate);
                            } else {
                              endTime.actions.onChange(data.date);
                            }
                          }}
                        />
                      </Box>
                    </FormControl.Field>
                  );
                }}
              </Observer>
              {/* Counting strategy */}
              <Observer>
                {() => {
                  return (
                    <FormControl.Field inline>
                      <Label>Counting Strategy</Label>
                      <Box justifyContent="flex-end">
                        <Select
                          id="strategy"
                          tabIndex={5}
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
                              label: "Ranked choice",
                              disabled: true,
                              value: "ranked-choice",
                            },
                            // {
                            //   label: "Quadratic voting",
                            //   disabled: true,
                            //   value: "quadratic-voting",
                            // },
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
              {/* Support required */}
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
            </Grid>
          </Card>
        </Grid2.Column>
      </Grid2.Row>
    ) : (
      emptyState()
    );

  return (
    <Grid2.Box fluid scroll>
      <Grid2.Box {...(isMobile && { p: 0 })}>
        <Grid2.Column
          {...(isMobile && { noGutter: true })}
          mb="16px"
          lg={12}
          xl={12}
        >
          <Grid2.Row>
            <Grid2.Column>
              <BreadcrumbNav
                onBack={onBack}
                crumbs={[
                  { label: "Proposals", onClick: onBack },
                  { label: "Create New" },
                ]}
              />
            </Grid2.Column>
          </Grid2.Row>
          {body}
        </Grid2.Column>
      </Grid2.Box>
    </Grid2.Box>
  );
});
