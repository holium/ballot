import React from "react";
import { KPI, Text, Icons, Box } from "@holium/design-system";
import { SideBySide, BarSet, Bar } from "./VoteBreakdownBar.styles";

export interface VoteBreakdownBarProps {
  ourChoice?: boolean;
  win?: boolean;
  label: string;
  percentage: number;
  overlay?: boolean;
  width?: string;
}

export const VoteBreakdownBar = (props: VoteBreakdownBarProps) => {
  const { win, label, percentage, overlay, ourChoice, width } = props;
  return (
    <BarSet overlay={overlay}>
      <SideBySide>
        <Box flexDirection="row" alignItems="center">
          <Text variant="body" fontWeight="medium">
            {label}
          </Text>
          {ourChoice && (
            <Icons.CheckCircle
              ml={3}
              opacity={win ? 1 : 0.4}
              color={win ? "brand.primary" : "text.primary"}
            />
          )}
        </Box>
        <KPI inline value={`${percentage || 0}%`} />
      </SideBySide>
      <Bar results={percentage} win={win} overlay={overlay} />
    </BarSet>
  );
};
