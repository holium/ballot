import React, { FC, useEffect, useState } from "react";
import { observer } from "mobx-react";
import { useLocation, useNavigate, Outlet, useParams } from "react-router-dom";
import Helmet from "react-helmet";
import { ThemeProvider } from "styled-components";
import { useStore } from "./logic/store";
import { Watcher } from "./logic/watcher";
import {
  theme,
  AppWindow,
  Icons,
  OSViewPort,
  useDialog,
  Dialog,
  Fill,
  Button,
} from "@holium/design-system";
import { BoothsDropdown } from "./components/BoothsDropdown";
import { NewBoothDialog } from "./components";
import { createPath } from "./logic/utils/path";
import { toJS } from "mobx";
import { mapToList } from "./logic/utils/map";
import { useMst } from "./logic/store-tree/root";

export const appName = "ballot";

export const App: FC = observer(() => {
  const navigate = useNavigate();
  const location = useLocation();
  const urlParams = useParams();
  const [currentTheme, setCurrentTheme] = useState<string>("light");
  const { isShowing, toggle } = useDialog();
  const { shipStore, proposalStore, onChannel } = useStore();
  const { store, app } = useMst();

  // Runs on initial load
  useEffect(() => {
    app.setCurrentUrl(location.pathname);
    store.getBooths().then(() => {
      const urlBooth = store.booths.get(urlParams.boothName!);
      if (urlBooth) {
        store.setBooth(urlBooth);
      } else {
        // use your current ship booth since we didnt find the url booth
        let newPath = createPath(store.booth, app.currentPage);
        navigate(newPath);
        app.setCurrentUrl(newPath, app.currentPage);
        return;
      }
    });
    // Set the currentUrl on load
    // appStore.setCurrentUrl(location.pathname);
    // store.fetchAll().then(() => {
    //   // If the booth in the url param exists
    // const urlBooth = store.getBooth(urlParams.boothName!);
    // if (urlBooth) {
    //   store.setBooth(store.getBooth(urlParams.boothName!)!);
    // } else {
    //   // use your current ship booth since we didnt find the url booth
    //   let newPath = createPath(store.booth!, appStore.currentPage);
    //   navigate(newPath);
    //   appStore.setCurrentUrl(newPath, appStore.currentPage);
    //   return;
    // }
    //   // Start watching
    //   Watcher.initialize(mapToList(store.booths), onChannel);
    //   proposalStore.initial(urlParams.boothName!); // todo remove this from here
    // });
  }, []);

  const toggleTheme = () => {
    setCurrentTheme(currentTheme === "light" ? "dark" : "light");
  };

  return (
    // @ts-ignore
    <ThemeProvider theme={theme[currentTheme]}>
      <Helmet defer={false}>
        <title>{app.title}</title>
      </Helmet>
      <OSViewPort bg="primary" blur={isShowing}>
        <Dialog
          variant="simple"
          hasCloseButton
          closeOnBackdropClick
          title="Join a booth"
          backdropOpacity={0.05}
          isShowing={isShowing}
          onHide={toggle}
        >
          <NewBoothDialog toggle={toggle} onJoin={store.joinBooth} />
        </Dialog>
        <AppWindow
          isStandalone
          loadingContext={store.loader.isLoading}
          style={{ padding: "0px 16px" }}
          app={{
            icon: <Icons.Governance />,
            name: "Ballot",
            color: "#6535CC",
            contextMenu: (
              <BoothsDropdown
                booths={store.list}
                onNewBooth={toggle}
                onAccept={(boothName: string) =>
                  store.booths.get(boothName)!.acceptInvite(boothName)
                }
                onContextClick={(selectedBooth: any) => {
                  let newPath = createPath(selectedBooth, app.currentPage);
                  navigate(newPath);
                  app.setCurrentUrl(newPath, app.currentPage);
                  store.setBooth(selectedBooth);
                }}
              />
            ),
          }}
          ship={{
            patp: shipStore.ship!.patp,
            color: shipStore.ship!.metadata!.color,
            contextMenu: (
              <Button variant="secondary" onClick={() => toggleTheme()}>
                Theme: {currentTheme}
              </Button>
            ),
          }}
          selectedRouteUri={app.currentPage} // proposals or delegation
          selectedContext={store.booth}
          onHomeClick={() => {
            let newPath = createPath(store.booth!, app.currentPage);
            navigate(newPath);
            app.setCurrentUrl(newPath, app.currentPage);
          }}
          onRouteClick={(route: any) => {
            navigate(route.uri);
            app.setCurrentUrl(route.uri, route.name.toLowerCase());
          }}
          subRoutes={[
            {
              icon: <Icons.SurveyLine />,
              name: "Proposals",
              nav: "proposals",
              uri:
                store.booth?.type === "ship"
                  ? `/apps/${appName}/booth/ship/${store.booth?.name}/proposals`
                  : `/apps/${appName}/booth/group/${store.booth?.name}/proposals`,
            },
            {
              icon: <Icons.ParentLine />,
              name: "Delegation",
              nav: "delegation",
              uri:
                store.booth?.type === "ship"
                  ? `/apps/${appName}/booth/ship/${store.booth?.name}/delegation`
                  : `/apps/${appName}/booth/group/${store.booth?.name}/delegation`,
            },
          ]}
          contexts={store.list}
        >
          {store.loader.isLoaded && <Outlet />}
          {/* <Outlet /> */}
        </AppWindow>
      </OSViewPort>
    </ThemeProvider>
  );
});
