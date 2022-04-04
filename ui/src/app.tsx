import React, { FC, useEffect, useState } from "react";
import { observer } from "mobx-react";
import { useLocation, useNavigate, Outlet, useParams } from "react-router-dom";
import Helmet from "react-helmet";
import { ThemeProvider } from "styled-components";

import {
  theme,
  AppWindow,
  Icons,
  OSViewPort,
  useDialog,
  Dialog,
  Fill,
  Text,
  Button,
  Flex,
} from "@holium/design-system";
import { BoothsDropdown } from "./components/BoothsDropdown";
import { NewBoothDialog } from "./components";
import { createPath, getKeyFromUrl } from "./logic/utils/path";
import { toJS } from "mobx";
import { useMst } from "./logic/stores/root";
import { BoothModelType } from "./logic/stores/booths";

export const appName = "ballot";

export const App: FC = observer(() => {
  const navigate = useNavigate();
  const location = useLocation();
  const urlParams = useParams();
  const { isShowing, toggle } = useDialog();

  const { store, app } = useMst();

  // Runs on initial load
  useEffect(() => {
    app.setCurrentUrl(location.pathname);
    store.getBooths().then(() => {
      const urlBooth = store.booths.get(getKeyFromUrl(urlParams));
      if (urlBooth) {
        store.setBooth(urlBooth.key);
      } else {
        // use your current ship booth since we didnt find the url booth
        store.setBooth(app.ship.patp);
        let newPath = createPath(store.booth!.key, app.currentPage);
        navigate(newPath);
        app.setCurrentUrl(newPath, app.currentPage);
        return;
      }
    });
  }, []);

  const toggleTheme = () => {
    app.setTheme(app.theme === "light" ? "dark" : "light");
  };

  return (
    // @ts-ignore
    <ThemeProvider theme={theme[app.theme]}>
      <Helmet defer={false}>
        <title>{`${app.title} | ${app.ship.patp}`}</title>
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
          loadingContext={store.isLoading}
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
                onContextClick={(selectedBooth: Partial<BoothModelType>) => {
                  let newPath = createPath(selectedBooth.key!, app.currentPage);
                  navigate(newPath);
                  app.setCurrentUrl(newPath, app.currentPage);
                  store.setBooth(selectedBooth.key!);
                }}
              />
            ),
          }}
          ship={{
            patp: app.ship!.patp,
            color: app.ship!.metadata!.color,
            contextMenu: (
              <Flex p={3} pb={2} flexDirection="column">
                <Text mb={3} variant="patp">
                  {app.ship!.patp}
                </Text>

                <Button
                  data-prevent-menu-close
                  variant="minimal"
                  onClick={() => toggleTheme()}
                >
                  Theme: {app.theme}
                </Button>
              </Flex>
            ),
          }}
          selectedRouteUri={app.currentPage} // proposals or delegation
          selectedContext={store.booth}
          onHomeClick={() => {
            let newPath = createPath(store.booth!.key, app.currentPage);
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
                  ? `/apps/${appName}/booth/${store.booth?.key}/proposals`
                  : `/apps/${appName}/booth/${store.booth?.key}/proposals`,
            },
            {
              icon: <Icons.ParentLine />,
              name: "Delegation",
              nav: "delegation",
              uri:
                store.booth?.type === "ship"
                  ? `/apps/${appName}/booth/${store.booth?.key}/delegation`
                  : `/apps/${appName}/booth/${store.booth?.key}/delegation`,
            },
          ]}
          contexts={store.list}
        >
          {store.booth && store.booth.isLoaded && <Outlet />}
        </AppWindow>
      </OSViewPort>
    </ThemeProvider>
  );
});
