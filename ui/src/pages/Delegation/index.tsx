import { Box, Fill, Text } from "@holium/design-system";
import React, { FC } from "react";
import { Outlet } from "react-router";

export const Delegation: FC = () => {
  return (
    <>
      <Box
        style={{
          position: "absolute",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          top: 50,
          bottom: 0,
          left: 0,
          right: 0,
          zIndex: 2,
        }}
      >
        <Text variant="h4" fontFamily="monospace">
          Feature coming soon...
        </Text>
      </Box>
      <Fill style={{ filter: "blur(4px)" }}>
        <Outlet />
      </Fill>
    </>
  );
};
