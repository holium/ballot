import React, { useMemo } from "react";
import { Observer } from "mobx-react";
import { Grid, Text, Button, Input, FormControl } from "@holium/design-system";
import { createParticipantForm } from "./ParticipantForm";
import { toJS } from "mobx";

export const ParticipantModal = (props: {
  participants?: any;
  onAdd: (patp: string) => any;
}) => {
  const { onAdd } = props;
  const { form, invitee } = useMemo(createParticipantForm, []);

  return (
    <React.Fragment>
      <Text lineHeight="20px" opacity={0.7} mb={4} variant="body">
        A participant can vote on proposals in your voting booth.
      </Text>
      <Observer>
        {() => {
          const error = !invitee.computed.isDirty || invitee.computed.error;
          return (
            <FormControl.Field>
              <Grid gridTemplateColumns="2fr 60px" gridColumnGap={2}>
                <Grid gridTemplateRows="auto" gridRowGap={2}>
                  <Input
                    autoFocus
                    tabIndex={0}
                    placeholder="e.g. ~zod"
                    spellCheck={false}
                    variant="body"
                    onChange={(evt: any) => {
                      invitee.actions.onChange(evt.target.value);
                    }}
                    onFocus={() => invitee.actions.onFocus()}
                    onBlur={() => invitee.actions.onBlur()}
                  />
                </Grid>
                <Button
                  tabIndex={0}
                  variant="minimal"
                  type="submit"
                  disabled={error ? true : false}
                  onClick={() => {
                    const formData = form.actions.submit();
                    onAdd(formData.invitee);
                  }}
                >
                  Invite
                </Button>
              </Grid>
              <FormControl.Hint>You must enter a valid patp.</FormControl.Hint>
            </FormControl.Field>
          );
        }}
      </Observer>
      {/* List here */}
    </React.Fragment>
  );
};
