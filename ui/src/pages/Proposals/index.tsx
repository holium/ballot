import React, { FC } from "react";
import { Outlet, useParams } from "react-router";
import { useMst } from "../../logic/stores/root";
import { toJS } from "mobx";
import { observer } from "mobx-react";
import { getKeyFromUrl } from "../../logic/utils/path";

export const Proposals: FC = observer(() => {
  const { store } = useMst();
  const urlParams = useParams<{ boothName: string; groupName?: string }>();
  const urlBooth = store.booths.get(getKeyFromUrl(urlParams));
  if (urlBooth && urlBooth.proposalStore.isLoaded) {
    return <Outlet />;
  }
  return null; // todo some loading or initial state
});
