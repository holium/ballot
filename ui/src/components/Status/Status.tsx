import React from "react";
import { Tag, Icons } from "@holium/design-system";

export type StatusProps = {
  status: "Active" | "Ended" | "Failed" | "Upcoming" | string;
};
export const Status = (props: StatusProps) => {
  const { status } = props;
  return (
    <>
      {status === "Ended" && (
        <Tag label="Ended" minimal custom="#4e9efd" rounded />
      )}
      {status === "Failed" && (
        <Tag label="Failed" minimal custom="#FF6240" rounded />
      )}
      {status === "Upcoming" && (
        <Tag label="Upcoming" minimal intent="info" rounded />
      )}
      {status === "Active" && (
        <Tag label="Active" minimal intent="success" rounded />
      )}
    </>
  );
};

// scheduled, started, ended
