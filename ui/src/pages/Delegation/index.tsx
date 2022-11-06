import React, { FC } from "react";
import { Outlet, useParams } from "react-router";
import { useMst } from "../../logic/stores/root";
import { Spinner, Flex } from "@holium/design-system";
import { observer } from "mobx-react";
import { getKeyFromUrl } from "../../logic/utils/path";

export const Delegation: FC = observer(() => {
  const { store } = useMst();
  const urlParams = useParams<{ boothName: string; groupName?: string }>();
  const urlBooth = store.booths.get(getKeyFromUrl(urlParams))!;
  if (urlBooth && urlBooth.delegateStore.isLoaded) {
    return <Outlet />;
  }
  // todo better loading state
  return (
    <Flex flex={1} alignItems="center" justifyContent="center">
      <Spinner size={2} />
    </Flex>
  );
});
