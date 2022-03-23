import React, { useState, useMemo } from "react";
import {
  Card,
  Grid,
  Button,
  FormControl,
  Label,
  Input,
  Text,
} from "@holium/design-system";
import { Observer } from "mobx-react";
import styled from "styled-components";
import { createNewBoothForm } from "./NewBoothForm";
import { toJS } from "mobx";

export const Container = styled(Card);

export type NewBoothDailogProps = {
  status?: "loading" | "success" | "error";
  onJoin: (boothName: string) => any;
};

export const NewBoothDialog: any = (props: NewBoothDailogProps) => {
  const { status, onJoin } = props;
  const { form, boothName } = useMemo(createNewBoothForm, []);

  return (
    <React.Fragment>
      <Text lineHeight="20px" opacity={0.7} mb={4} variant="body">
        A voting booth is where groups can view proposals, create new proposals,
        and vote.
      </Text>
      <Observer>
        {() => {
          const error = !boothName.computed.isDirty || boothName.computed.error;
          return (
            <FormControl.Field>
              <Label required>Booth name</Label>
              <Grid gridTemplateColumns="2fr 60px" gridColumnGap={2}>
                <Input
                  placeholder="e.g. ~zod"
                  spellCheck={false}
                  onFocus={() => boothName.actions.onFocus()}
                  onBlur={() => boothName.actions.onBlur()}
                  onChange={(evt: any) => {
                    boothName.actions.onChange(evt.target.value);
                  }}
                />
                <Button
                  variant="minimal"
                  type="submit"
                  disabled={error ? true : false}
                  onClick={() => {
                    const formData = form.actions.submit();
                    onJoin(formData.boothName);
                  }}
                >
                  Join
                </Button>
              </Grid>
              <FormControl.Hint>You must enter a valid patp.</FormControl.Hint>
            </FormControl.Field>
          );
        }}
      </Observer>
    </React.Fragment>
  );
};
