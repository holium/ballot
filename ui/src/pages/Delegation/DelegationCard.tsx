import React, { FC, useMemo } from "react";
import { Observer } from "mobx-react";
import { useParams } from "react-router";
import { createField, createForm } from "mobx-easy-form";
import { isValidPatp } from "urbit-ob";
import {
  Button,
  Card,
  Flex,
  FormControl,
  Grid,
  Header,
  Icons,
  Input,
  Ship,
  Text,
} from "@holium/design-system";
import { pluralize } from "../../logic/utils/text";
import { ShipModelType } from "../../logic/stores/app";

type DelegationCardProps = {
  votingPower: number;
  delegatingFor?: any[];
  ship: ShipModelType;
};

export const DelegationCard: FC<DelegationCardProps> = (
  props: DelegationCardProps
) => {
  const { ship, votingPower } = props;
  const urlParams = useParams();
  const currentBooth = urlParams.boothName!;
  // console.log(totalVotingPower);
  const { form, delegate } = useMemo(createDelegateForm, []);

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
          patp={ship.patp}
          color={ship.metadata?.color || "#000000"}
          textOpacity={1}
        />
        <Text variant="body" opacity={0.7}>
          {votingPower} {pluralize("vote", votingPower)}
        </Text>
      </Flex>
      <Flex flexDirection="column" mt={2}>
        <Text variant="body" opacity={0.7}>
          Delegating your vote to another Urbit ID will prevent you from being
          able to vote on proposals in the booth:{" "}
          <b style={{ fontFamily: "Source Code Pro, mono", fontWeight: "600" }}>
            {currentBooth}
          </b>
        </Text>

        <FormControl.Field mt={2}>
          <Observer>
            {() => {
              const error =
                !delegate.computed.isDirty || delegate.computed.error;
              return (
                <>
                  <Grid gridTemplateColumns="2fr 80px" gridColumnGap={2}>
                    <Grid gridTemplateRows="auto" gridRowGap={2}>
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
                    </Grid>
                    <Button
                      variant="minimal"
                      type="submit"
                      disabled={error ? true : false}
                      onClick={() => {
                        const formData = form.actions.submit();
                        // onAdd(formData.delegate);
                      }}
                    >
                      Delegate
                    </Button>
                  </Grid>
                  {/* <FormControl.Hint>
                    You must enter a valid patp.
                  </FormControl.Hint> */}
                </>
              );
            }}
          </Observer>
        </FormControl.Field>
      </Flex>
    </Card>
  );
};

export const createDelegateForm = () => {
  const form = createForm({
    onSubmit({ values }) {
      return values;
    },
  });
  const delegate = createField({
    id: "delegate",
    form,
    initialValue: "",
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
