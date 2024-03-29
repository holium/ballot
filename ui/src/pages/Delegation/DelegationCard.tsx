import React, { FC, useMemo } from "react";
import { observer } from "mobx-react";
import { useParams } from "react-router";
import { createField, createForm } from "mobx-easy-form";
import { isValidPatp } from "urbit-ob";
import {
  Button,
  Card,
  Flex,
  FormControl,
  Grid,
  Input,
  Ship,
  Text,
} from "@holium/design-system";
import { pluralize } from "../../logic/utils/text";
import { ShipModelType } from "../../logic/stores/app";
import { getKeyFromUrl } from "../../logic/utils/path";
import { useMst } from "../../logic/stores/root";
import styled from "styled-components";

interface DelegationCardProps {
  delegatingFor?: any[];
  ship: ShipModelType;
}

const OurDelegateInput = styled.div`
  background: ${(props: any) => props.theme.colors.ui.tertiary};
  padding-left: 8px;
  padding-right: 8px;
  display: flex;
  align-items: center;
  font-size: 14px;
  border: 1px solid
    ${(props: any) =>
      props.error
        ? props.theme.colors.ui.intent.alert
        : props.theme.colors.ui.input.borderColor};
  border-radius: ${(props) => props.theme.input.borderRadius}px;
`;

export const DelegationCard: FC<DelegationCardProps> = observer(
  (props: DelegationCardProps) => {
    const { store } = useMst();
    const { ship } = props;
    const urlParams = useParams();
    const isLoading = store.booth?.isLoading;
    // const currentBooth = getKeyFromUrl(urlParams);
    const currentBooth = getKeyFromUrl(urlParams);
    const delegateStore = store.booths.get(currentBooth)?.delegateStore;
    const ourDelegate = delegateStore?.delegates.get(ship.patp)?.delegate;
    const ourVotingPower = delegateStore!.getVotingPower(ship.patp);
    const hasDelegated = ourVotingPower === 0;
    const isDelegateLoading = delegateStore?.delegateLoader.isLoading;
    // console.log(totalVotingPower);
    const { form, delegate } = useMemo(
      () => createDelegateForm(ourDelegate),
      [ourDelegate]
    );

    // console.log("delegate card update", isDelegateLoading, ourVotingPower);

    const error = !delegate.computed.isDirty || delegate.computed.error;

    return (
      <Card
        mt={12}
        padding="12px"
        style={{ borderColor: "transparent" }}
        elevation="lifted"
      >
        <Flex
          justifyContent="space-between"
          alignItems="center"
          style={{ flex: 1, width: "100%" }}
        >
          <Ship
            textOpacity={1}
            patp={ship.patp}
            avatar={ship.metadata?.avatar}
            nickname={ship.metadata?.nickname}
            color={ship.metadata?.color || "#000000"}
            clickable={false}
          />
          {/* <Ship
          patp={ship.patp}
          color={ship.metadata?.color || "#000000"}
          textOpacity={1}
        /> */}
          {!isLoading && (
            <Text variant="body" opacity={0.7}>
              {ourVotingPower} {pluralize("vote", ourVotingPower)}
            </Text>
          )}
        </Flex>
        <Flex flexDirection="column" mt={2}>
          {ourDelegate ? (
            <Text variant="body" opacity={0.7}>
              You have delegated your vote to{" "}
              <b
                style={{
                  fontFamily: "Source Code Pro, mono",
                  fontWeight: "600",
                }}
              >
                {ourDelegate}
              </b>
              , which means they will vote on your behalf in the booth:{" "}
              <b
                style={{
                  fontFamily: "Source Code Pro, mono",
                  fontWeight: "600",
                }}
              >
                {currentBooth}
              </b>
            </Text>
          ) : (
            <Text variant="body" opacity={0.7}>
              Delegating your vote to another ship will prevent you from being
              able to vote on proposals in the booth:{" "}
              <b
                style={{
                  fontFamily: "Source Code Pro, mono",
                  fontWeight: "600",
                }}
              >
                {currentBooth}
              </b>
            </Text>
          )}

          <FormControl.Field mt={2}>
            <Grid gridTemplateColumns="2fr 100px" gridColumnGap={2}>
              <Grid gridTemplateRows="auto" gridRowGap={2}>
                {ourDelegate ? (
                  <OurDelegateInput>{ourDelegate}</OurDelegateInput>
                ) : (
                  <Input
                    placeholder="e.g. ~zod"
                    spellCheck={false}
                    variant="body"
                    onChange={(evt: any) => {
                      delegate.actions.onChange(evt.target.value);
                    }}
                    onFocus={() => delegate.actions.onFocus()}
                    onBlur={() => delegate.actions.onBlur()}
                  />
                )}
              </Grid>
              <Button
                variant="minimal"
                type="submit"
                isLoading={isDelegateLoading}
                disabled={ourDelegate ? false : !!error}
                onClick={() => {
                  if (ourDelegate) {
                    delegateStore.undelegate(ourDelegate);
                  } else {
                    const formData = form.actions.submit();
                    delegateStore!.delegate(formData.delegate);
                  }
                  // onAdd(formData.delegate);
                }}
              >
                {ourDelegate ? "Undelegate" : "Delegate"}
              </Button>
            </Grid>

            {delegateStore?.delegateLoader.error != null && (
              <FormControl.Error>
                {delegateStore?.delegateLoader.errorMessage}
              </FormControl.Error>
            )}
          </FormControl.Field>
        </Flex>
      </Card>
    );
  }
);

export const createDelegateForm = (ourDelegate?: string) => {
  const form = createForm({
    onSubmit({ values }) {
      return values;
    },
  });
  const delegate = createField({
    id: "delegate",
    form,
    initialValue: ourDelegate || "",
    validate: (patp: string) => {
      if (patp.length > 1 && isValidPatp(patp)) {
        return { error: undefined, parsed: patp };
      }

      return { error: "Invalid patp", parsed: undefined };
    },
  });

  return {
    form,
    delegate,
  };
};
