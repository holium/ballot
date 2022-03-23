import React, { FC } from "react";
import { Icons, TlonIcon, KPI } from "@holium/design-system";

export type StatusInfoType = {
  value: string;
  label?: string;
  status:
    | "active"
    | "succeeded"
    | "ends soon"
    | "defeated"
    | "queued"
    | "cancelled"
    | "executed"
    | "disputed"
    | "user voted"
    | "error"
    | string;
};

export const StatusInfo: FC<StatusInfoType> = (props: StatusInfoType) => {
  const { value, status, label } = props;
  return (
    <>
      {status === "succeeded" && (
        <KPI value={value} icon={<Icons.Check />} label={label} />
      )}
      {status === "user voted" && (
        <KPI value={value} icon={<Icons.Check />} label={label} />
      )}
      {status === "defeated" && (
        <KPI value={value} icon={<Icons.Close />} label={label} />
      )}
      {status === "cancelled" && (
        <KPI value={value} icon={<Icons.Close />} label={label} />
      )}
      {status === "error" && (
        <KPI value={value} icon={<Icons.Error />} label={label} />
      )}
      {status === "disputed" && (
        <KPI value={value} icon={<Icons.Error />} label={label} />
      )}
      {status === "active" && (
        <KPI value={value} icon={<TlonIcon icon="Clock" />} label={label} />
      )}
      {status === "ends soon" && (
        <KPI value={value} icon={<TlonIcon icon="Clock" />} label={label} />
      )}
      {status === "queued" && (
        <KPI value={value} icon={<TlonIcon icon="Clock" />} label={label} />
      )}
      {status === "executed" && (
        <KPI value={value} icon={<Icons.CalendarChecked />} label={label} />
      )}
    </>
  );
};
