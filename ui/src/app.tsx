import React, { FC, useEffect } from "react";
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
import { useMobile } from "./logic/utils/useMobile";

export const appName = "ballot";

export const App: FC = observer(() => {
  const navigate = useNavigate();
  const location = useLocation();
  const urlParams = useParams();
  const { isShowing, toggle } = useDialog();
  const isMobile = useMobile();
  const { store, app, metadata } = useMst();
  console.log("rerendering app level");
  // Runs on initial load
  useEffect(() => {
    app.setCurrentUrl(location.pathname);

    Promise.all([
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
      }),
      metadata.getMetadata(),
      metadata.getContactMetadata(),
    ]);
  }, []);

  const toggleTheme = () => {
    app.setTheme(app.theme === "light" ? "dark" : "light");
  };

  const routes = [
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
  ];

  if (store.booth?.hasAdmin) {
    routes.push({
      icon: <Icons.SettingsLine />,
      name: "Settings",
      nav: "settings",
      uri: `/apps/${appName}/booth/${store.booth?.key}/settings`,
    });
  }

  const contextLoading =
    store.isLoading ||
    metadata.groupsLoader.isLoading ||
    metadata.contactsLoader.isLoading;
  const ship = app.account;
  return (
    // @ts-ignore
    <ThemeProvider theme={theme[app.theme]}>
      <Helmet defer={false}>
        <title>{`${app.title} | ${app.ship.patp}`}</title>
      </Helmet>
      <OSViewPort blur={isShowing}>
        <Dialog
          variant="simple"
          hasCloseButton
          closeOnBackdropClick
          title="Join a booth"
          backdropOpacity={0.05}
          isShowing={isShowing}
          onHide={toggle}
        >
          {/* <NewBoothDialog toggle={toggle} onJoin={store.joinBooth} /> */}
        </Dialog>
        <AppWindow
          isStandalone
          loadingContext={contextLoading}
          style={{ padding: "0px 16px" }}
          app={{
            icon: <Icons.AppBallotSM size={2} />,
            name: "Ballot",
            color: "#6535CC",
            contextMenu: (
              <BoothsDropdown
                booths={store.list}
                onNewBooth={toggle}
                onJoin={(boothName: string) =>
                  store.booths.get(boothName)!.acceptInvite(boothName)
                }
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
            patp: ship.patp,
            avatar: ship.metadata.avatar!,
            nickname: ship.metadata.nickname!,
            color: ship.metadata.color,
            contextMenu: (
              <Flex p={3} pb={2} flexDirection="column">
                <Text mb={3} variant="patp">
                  {ship.metadata.nickname || ship.patp}
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
          subRoutes={routes}
          contexts={store.list}
        >
          {store.booth && store.booth.isLoaded && <Outlet />}
        </AppWindow>
      </OSViewPort>
    </ThemeProvider>
  );
});
