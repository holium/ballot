import React from "react";
import { Tag } from "@holium/design-system";

export interface StatusProps {
  status: "Active" | "Ended" | "Failed" | "Upcoming" | string;
}
export const Status = (props: StatusProps) => {
  const { status } = props;
  return (
    <>
      {status === "Ended" && <Tag label="Ended" minimal custom="#4e9efd" />}
      {status === "Failed" && <Tag label="Failed" minimal custom="#FF6240" />}
      {status === "Upcoming" && <Tag label="Upcoming" minimal intent="info" />}
      {status === "Active" && <Tag label="Active" minimal intent="success" />}
    </>
  );
};

// scheduled, started, ended
