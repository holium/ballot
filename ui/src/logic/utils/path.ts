import { appName } from "../../app";

export const createPath = (
  boothKey: string,
  page: "proposals" | "delegate" | string = "proposals",
  proposalId: string = "",
  subPath: string = ""
): string => {
  if (subPath) {
    subPath = `/${subPath}`;
  }
  if (proposalId) {
    proposalId = `/${proposalId}${subPath}`;
  }
  return `/apps/${appName}/booth/${boothKey}/${page}${proposalId}`;
  // switch (booth.type) {
  //   case "ship":
  //     return `/apps/${appName}/booth/${booth.key}/${page}${proposalId}`;
  //   case "group":
  //     return `/apps/${appName}/booth/${booth.key}/${page}${proposalId}`;
  //   default:
  //     return `/apps/${appName}/booth/`;
  // }
};

export const getKeyFromUrl = (urlParams: {
  boothName?: string;
  groupName?: string;
}) => {
  let boothKey: string = urlParams.boothName!;
  if (urlParams.groupName) {
    boothKey = `${boothKey}/groups/${urlParams.groupName}`;
  }
  return boothKey;
};

export const getNameFromUrl = (urlParams: {
  boothName?: string;
  groupName?: string;
}) => {
  const nameArr = urlParams.boothName && urlParams.boothName.split("-groups-");

  if (nameArr?.length === 2) {
    return `${nameArr[0]}/${nameArr[1]}`;
  }
  return urlParams.boothName!;
};

// export const getNameFromUrl = (urlParams: {
//   boothName?: string;
//   groupName?: string;
// }) => {
//   if (urlParams.groupName) {
//     return urlParams.groupName!;
//   }
//   return urlParams.boothName!;
// };
