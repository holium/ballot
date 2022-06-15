import React from "react";
import MDEditor from "@uiw/react-md-editor";
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
  DateSingleInput,
  Box,
} from "@holium/design-system";

import { MarkdownEditor } from "../../../components/MarkdownEditor";
import { ChoiceEditor } from "./Choices";

export const emptyState = () => {
  return (
    <Grid gridTemplateColumns="2fr 320px" gridColumnGap={16}>
      <Flex mb={12} flexDirection="column">
        <ListHeader
          title={
            <InlineEdit
              variant="h4"
              pb={1}
              pt={1}
              tabIndex={1}
              fontWeight={600}
              disabled
              placeholder="Enter proposal title"
            />
          }
        />
        <FormControl.FieldSet pl={3} pr={3}>
          <FormControl.Field>
            <MarkdownEditor>
              <MDEditor
                style={{ fontFamily: "Inter, sans-serif" }}
                height={500}
                preview="edit"
                defaultTabEnable={true}
                textareaProps={{
                  tabIndex: 2,
                  disabled: true,
                  placeholder: "Explain more about your proposal",
                }}
                previewOptions={{
                  rehypePlugins: [[rehypeSanitize]],
                  style: { fontFamily: "Inter, sans-serif" },
                }}
              />
            </MarkdownEditor>
          </FormControl.Field>
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
          <ChoiceEditor
            actions={[]}
            choices={[]}
            onUpdate={() => {}}
            onActionUpdate={() => {}}
          />
        </Card>
      </Flex>
      <Grid gridTemplateRows="44px 1fr" gridGap={16}>
        <Flex height={30} justifyContent="flex-end" style={{ gap: 8 }}>
          <Button py={1} variant="secondary">
            Save draft
          </Button>
          <Button
            py={1}
            type="submit"
            variant="minimal"
            onClick={() => {}}
            disabled
          >
            Publish
          </Button>
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
            <FormControl.Field inline>
              <Label>Strategy</Label>
              <Box justifyContent="flex-end">
                <Select
                  id="strategy"
                  tabIndex={3}
                  style={{ width: 162 }}
                  placeholder="Select..."
                  selectionOption={"single-choice"}
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
                  onSelected={() => {}}
                />
              </Box>
            </FormControl.Field>
            {/* Start time */}
            <FormControl.Field inline>
              <Label>Start</Label>
              <Box justifyContent="flex-end">
                <DateSingleInput
                  inputId="startTime"
                  tabIndex={4}
                  minBookingDate={new Date()}
                  onFocusChange={() => {}}
                  date={null}
                  onDateChange={() => {}}
                />
              </Box>
            </FormControl.Field>
            {/* End time */}
            <FormControl.Field inline>
              <Label>End</Label>
              <Box justifyContent="flex-end">
                <DateSingleInput
                  inputId="endTime"
                  tabIndex={4}
                  minBookingDate={new Date()}
                  onFocusChange={() => {}}
                  date={null}
                  onDateChange={(data: any) => {}}
                />
              </Box>
            </FormControl.Field>
            {/* Support required */}
            <FormControl.Field inline>
              <Label>Support</Label>
              <Box justifyContent="flex-end">
                <Input
                  style={{ width: 75 }}
                  type="number"
                  placeholder="ie. 50%"
                  tabIndex={5}
                  disabled
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
                  // error={title.computed.ifWasEverBlurredThenError}
                  onChange={(e: any) => {}}
                />
              </Box>
            </FormControl.Field>
          </Grid>
        </Card>
      </Grid>
    </Grid>
  );
};
