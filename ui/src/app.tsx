import React, { FC, useCallback, useEffect, useMemo } from "react";
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
import { useRealmTheme } from "./logic/utils/useRealmTheme";
import { AppModelType } from "./logic/stores/app";

export const appName = "ballot";

export const App: FC = observer(() => {
  const navigate = useNavigate();
  const location = useLocation();
  const urlParams = useParams();
  const { isShowing, toggle } = useDialog();
  const isMobile = useMobile();
  const { store, app, metadata } = useMst();
  const realmTheme = useRealmTheme();
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

  const getTheme = () => {
    if (app.theme === "auto") {
      return realmTheme ?? theme.light;
    }
    return theme[app.theme];
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

  const onContextClick = useCallback(
    (selectedBooth: Partial<BoothModelType>) => {
      let newPath = createPath(selectedBooth.key!, app.currentPage);
      navigate(newPath);
      app.setCurrentUrl(newPath, app.currentPage);
      store.setBooth(selectedBooth.key!);
    },
    [app]
  );

  const onAccept = useCallback(
    (boothName: string) => {
      store.booths.get(boothName)!.acceptInvite(boothName);
    },
    [store.booths]
  );

  const BoothsContext = useMemo(
    () => (
      <BoothsDropdown
        booths={store.list}
        onNewBooth={toggle}
        onJoin={onAccept}
        onAccept={onAccept}
        onContextClick={onContextClick}
      />
    ),
    [store.list]
  );

  const contextLoading =
    store.isLoading ||
    metadata.groupsLoader.isLoading ||
    metadata.contactsLoader.isLoading;
  const ship = app.account;
  return (
    // @ts-ignore
    <ThemeProvider theme={getTheme()}>
      <Helmet defer={false}>
        <title>{`${app.title} | ${app.ship.patp}`}</title>
      </Helmet>
      <OSViewPort blur={isShowing} bg="primary">
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
          isMobile={isMobile}
          isStandalone
          loadingContext={contextLoading}
          style={{ padding: "0px 16px" }}
          app={{
            icon: <Icons.AppBallotSM size={2} />,
            name: "Ballot",
            color: "#6535CC",
            contextMenu: BoothsContext,
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

                <Text pb={1} variant="body">
                  Theme:
                </Text>

                <Flex gap={2}>
                  {["light", "dark", "auto"].map((themeMode) => (
                    <Button
                      key={themeMode}
                      data-prevent-menu-close
                      style={{ textTransform: "capitalize" }}
                      variant={
                        app.theme === themeMode ? "primary" : "secondary"
                      }
                      onClick={() =>
                        app.setTheme(themeMode as AppModelType["theme"])
                      }
                    >
                      {themeMode}
                    </Button>
                  ))}
                </Flex>
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
