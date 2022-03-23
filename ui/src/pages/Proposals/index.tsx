import React, { FC } from "react";
import { Outlet } from "react-router";
import { Fill } from "@holium/design-system";

export const Proposals: FC<{}> = (props: {}) => {
  return (
    // <Fill>
    <Outlet />
    // </Fill>
  );
};
