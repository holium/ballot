import { theme as defaultTheme, ThemeType } from "@holium/design-system";
import { darken, invert, lighten, rgba, transparentize } from "polished";
import { useEffect, useState, useCallback } from "react";

type CssVariables = Record<string, string>;

type UseRealmTheme = () => ThemeType | null;

export const useRealmTheme: UseRealmTheme = () => {
  const [cssVariables, setCssVariables] = useState<CssVariables>();

  const getCssVariable = useCallback(
    (name: string) =>
      getComputedStyle(document.documentElement).getPropertyValue(name).trim(),
    []
  );

  const handleCssUpdate = useCallback(() => {
    const updatedCssVariables = {
      mode: getCssVariable("--rlm-theme-mode"),
      font: getCssVariable("--rlm-font"),
      baseColor: getCssVariable("--rlm-base-color"),
      accentColor: getCssVariable("--rlm-accent-color"),
      inputColor: getCssVariable("--rlm-input-color"),
      borderColor: getCssVariable("--rlm-border-color"),
      windowColor: getCssVariable("--rlm-window-color"),
      cardColor: getCssVariable("--rlm-card-color"),
      textColor: getCssVariable("--rlm-text-color"),
      iconColor: getCssVariable("--rlm-icon-color"),
    };
    setCssVariables(updatedCssVariables);
  }, [getCssVariable]);

  useEffect(() => {
    // On blur we continuously listen for changes in injected css
    let interval: NodeJS.Timer;
    window.addEventListener("blur", () => {
      interval = setInterval(handleCssUpdate, 100);
      return () => {
        clearInterval(interval);
      };
    });
    window.addEventListener("focus", () => {
      handleCssUpdate();
      clearInterval(interval);
    });

    return () => {
      window.removeEventListener("blur", handleCssUpdate);
      window.removeEventListener("focus", handleCssUpdate);
    };
  }, [handleCssUpdate]);

  if (!cssVariables || Object.values(cssVariables).some((v) => !v)) {
    return null;
  }

  const baseTheme =
    cssVariables.mode === "dark" ? defaultTheme.dark : defaultTheme.light;

  const realmTheme: ThemeType = {
    // For properties not yet injected by Realm, we fall back to default theming
    ...baseTheme,
    fonts: {
      ...baseTheme.fonts,
      body: cssVariables.font,
      heading: cssVariables.font,
    },
    colors: {
      ...baseTheme.colors,
      brand: {
        primary: cssVariables.accentColor,
        secondary: darken(0.2, cssVariables.cardColor),
        neutral: darken(0.1, cssVariables.cardColor),
        accent: lighten(0.1, cssVariables.accentColor),
        muted: rgba(cssVariables.baseColor, 0.2),
      },
      ui: {
        ...baseTheme.colors.ui,
        borderColor: cssVariables.borderColor,
        input: {
          background: cssVariables.inputColor,
          secondary: cssVariables.windowColor,
          borderColor: transparentize(0.9, cssVariables.borderColor),
          borderHover: transparentize(0.8, cssVariables.borderColor),
        },
      },
      bg: {
        ...baseTheme.colors.bg,
        primary: cssVariables.windowColor,
        secondary: lighten(0.05, cssVariables.windowColor),
        tertiary: lighten(0.1, cssVariables.windowColor),
        inset: lighten(0.15, cssVariables.windowColor),
        toolbar: lighten(0.2, cssVariables.windowColor),
        divider: cssVariables.borderColor,
      },
      icon: {
        ...baseTheme.colors.icon,
        bgButton: rgba(baseTheme.colors.icon.app, 0.5),
      },
      text: {
        ...baseTheme.colors.text,
        primary: cssVariables.textColor,
        secondary: lighten(0.2, cssVariables.textColor),
        tertiary: lighten(0.4, cssVariables.textColor),
        disabled: lighten(0.6, cssVariables.textColor),
        placeholder: transparentize(0.7, cssVariables.textColor),
        inverse: invert(cssVariables.textColor),
      },
      highlights: {
        ...baseTheme.colors.highlights,
        primaryHighlight: lighten(0.05, cssVariables.baseColor),
        primaryExtraHighlight: lighten(0.1, cssVariables.baseColor),
        bgHighlight: darken(0.01, cssVariables.windowColor),
        bgSoftHighlight: darken(0.05, cssVariables.windowColor),
      },
    },
  };

  return realmTheme;
};
