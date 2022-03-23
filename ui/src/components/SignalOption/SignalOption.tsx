import React, { useState } from "react";
import {
  Tag,
  Icons,
  Flex,
  Grid,
  KPI,
  TlonIcon,
  Text,
  Card,
  CardInner,
  ColorLine,
} from "@holium/design-system";
import { flex } from "styled-system";

export type SignalOptionProps = {
  SignalOption:
    | "active"
    | "succeeded"
    | "ends soon"
    | "defeated"
    | "queued"
    | "cancelled"
    | "executed"
    | "disputed"
    | "user voted"
    | "error";
  participantCount: number;
  totalMembers: number;
  option: any;
  selectable: boolean;
};
export const SignalOption = (props: SignalOptionProps) => {
  const [optionSelected, setOptionSelected] = useState(false);
  console.log(optionSelected, "option");
  return (
    <Card
      selectable={props.selectable}
      selected={optionSelected}
      onClick={() => setOptionSelected(!optionSelected)}
    >
      <Grid
        gridAutoFlow="column"
        p={["8px", "4px", "4px"]}
        justifyContent="space-between"
      >
        <Text variant="body">{props.option}</Text>
        <KPI icon={<TlonIcon icon="Users" />} value={props.participantCount} />
      </Grid>
    </Card>
  );
};
