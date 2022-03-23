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

export const appName = "ballot";

export const App: FC = observer(() => {
  const navigate = useNavigate();
  const location = useLocation();
  const urlParams = useParams();
  const [currentTheme, setCurrentTheme] = useState<string>("light");
  const { isShowing, toggle } = useDialog();
  const { appStore, shipStore, boothStore, proposalStore, onChannel } =
    useStore();

  // Runs on initial load
  useEffect(() => {
    // Set the currentUrl on load
    appStore.setCurrentUrl(location.pathname);
    boothStore.fetchAll().then(() => {
      // If the booth in the url param exists
      const urlBooth = boothStore.getBooth(urlParams.boothName!);
      if (urlBooth) {
        boothStore.setBooth(boothStore.getBooth(urlParams.boothName!)!);
      } else {
        // use your current ship booth since we didnt find the url booth
        let newPath = createPath(boothStore.booth!, appStore.currentPage);
        navigate(newPath);
        appStore.setCurrentUrl(newPath, appStore.currentPage);
        return;
      }
      // Start watching
      Watcher.initialize(mapToList(boothStore.booths), onChannel);
      proposalStore.initial(urlParams.boothName!);
    });
  }, []);

  const toggleTheme = () => {
    setCurrentTheme(currentTheme === "light" ? "dark" : "light");
  };

  return (
    // @ts-ignore
    <ThemeProvider theme={theme[currentTheme]}>
      <Helmet defer={false}>
        <title>{appStore.title}</title>
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
          <NewBoothDialog toggle={toggle} onJoin={boothStore.joinBooth} />
        </Dialog>
        <AppWindow
          isStandalone
          loadingContext={boothStore.loader.isLoading.get()}
          style={{ padding: "0px 16px" }}
          app={{
            icon: <Icons.Governance />,
            name: "Ballot",
            color: "#6535CC",
            contextMenu: (
              <BoothsDropdown
                booths={boothStore.list()}
                onNewBooth={toggle}
                onAccept={(boothName: string) =>
                  boothStore.acceptInvite(boothName)
                }
                onContextClick={(selectedBooth: any) => {
                  let newPath = createPath(selectedBooth, appStore.currentPage);
                  navigate(newPath);
                  appStore.setCurrentUrl(newPath, appStore.currentPage);
                  boothStore.setBooth(selectedBooth).then(() => {
                    // If there are no proposals loaded, try to fetch them
                    !proposalStore.proposals.get(selectedBooth.name)?.hasMap_ &&
                      proposalStore.initial(selectedBooth.name);
                  });
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
          selectedRouteUri={appStore.currentPage} // proposals or delegation
          selectedContext={boothStore.booth}
          onHomeClick={() => {
            let newPath = createPath(boothStore.booth!, appStore.currentPage);
            navigate(newPath);
            appStore.setCurrentUrl(newPath, appStore.currentPage);
          }}
          onRouteClick={(route: any) => {
            navigate(route.uri);
            appStore.setCurrentUrl(route.uri, route.name.toLowerCase());
          }}
          subRoutes={[
            {
              icon: <Icons.SurveyLine />,
              name: "Proposals",
              nav: "proposals",
              uri:
                boothStore.booth?.type === "ship"
                  ? `/apps/${appName}/booth/ship/${boothStore.booth?.name}/proposals`
                  : `/apps/${appName}/booth/group/${boothStore.booth?.name}/proposals`,
            },
            {
              icon: <Icons.ParentLine />,
              name: "Delegation",
              nav: "delegation",
              uri:
                boothStore.booth?.type === "ship"
                  ? `/apps/${appName}/booth/ship/${boothStore.booth?.name}/delegation`
                  : `/apps/${appName}/booth/group/${boothStore.booth?.name}/delegation`,
            },
          ]}
          contexts={boothStore.list()}
        >
          {boothStore.isLoaded.get() && <Outlet />}
          {/* <Outlet /> */}
        </AppWindow>
      </OSViewPort>
    </ThemeProvider>
  );
});
