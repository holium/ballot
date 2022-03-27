import React, { FC } from "react";
import { Outlet, useParams } from "react-router";
import { useMst } from "../../logic/stores/root";
import { toJS } from "mobx";
import { observer } from "mobx-react";

export const Proposals: FC = observer(() => {
  const { store } = useMst();
  const urlParams = useParams();

  const urlBooth = store.booths.get(urlParams.boothName!);
  if (urlBooth && urlBooth.proposalStore.isLoaded) {
    return <Outlet />;
  }
  return null; // todo some loading or initial state
});
