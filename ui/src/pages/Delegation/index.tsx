import { Box, Fill, Text } from "@holium/design-system";
import React, { FC } from "react";
import { Outlet } from "react-router";

export const Delegation: FC = () => {
  return (
    <Fill>
      <Outlet />
    </Fill>
  );
};
