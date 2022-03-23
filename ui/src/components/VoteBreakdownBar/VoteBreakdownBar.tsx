import React, { FC } from "react";
import { KPI, Text, TlonIcon } from "@holium/design-system";
import { SideBySide, BarSet, Bar } from "./VoteBreakdownBar.styles";

export type VoteBreakdownBarProps = {
  win?: boolean;
  label: string;
  results: number;
  overlay?: boolean;
  width?: string;
};

export const VoteBreakdownBar = (props: VoteBreakdownBarProps) => {
  const { win, label, results, overlay, width } = props;
  return (
    <BarSet overlay={overlay}>
      <SideBySide>
        <Text variant="body" fontWeight="medium">
          {label}
        </Text>
        <KPI inline value={`${results}%`} trailingLabel="voted" />
      </SideBySide>
      <Bar results={results} win={win} overlay={overlay} />
    </BarSet>
  );
};
