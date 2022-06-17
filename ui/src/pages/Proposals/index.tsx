import React, { FC, useEffect } from "react";
import { Outlet, useParams } from "react-router";
import { useMst } from "../../logic/stores/root";
import { Spinner, Flex } from "@holium/design-system";
import { toJS } from "mobx";
import { observer } from "mobx-react";
import { getKeyFromUrl } from "../../logic/utils/path";
import { ProposalListLoader } from "./List/loader";

export const Proposals: FC = observer(() => {
  const { store } = useMst();
  const urlParams = useParams<{ boothName: string; groupName?: string }>();
  const urlBooth = store.booths.get(getKeyFromUrl(urlParams));
  if (urlBooth && urlBooth.proposalStore.loader.state === "initial") {
    // Only load this data on initial
    urlBooth.isActive && urlBooth.proposalStore.getProposals();
    urlBooth.isActive && urlBooth.participantStore.getParticipants();
    urlBooth.isActive && urlBooth.delegateStore.getDelegates();
  }
  if (urlBooth && urlBooth.proposalStore.isLoaded) {
    return <Outlet />;
  }
  // return (
  //   <Flex flex={1} alignItems="center" justifyContent="center">
  //     <Spinner size={2} />
  //   </Flex>
  // );
  return <ProposalListLoader />;
});
