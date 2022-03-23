const path = require("path");

// @ts-ignore
module.exports = {
  core: { builder: "storybook-builder-vite" },
  async viteFinal(config, { configType }) {
    // customize the Vite config here
    // config.resolve.alias.foo = "bar";
    // config.server.fs = {
    //   allow: ["../"],
    // };
    config.dedup = ["styled-components", "styled-system"];

    // return the customized config
    return config;
  },
  // webpackFinal: async (config, { configType }) => {
  //   // `configType` has a value of 'DEVELOPMENT' or 'PRODUCTION'
  //   // You can change the configuration based on that.
  //   // 'PRODUCTION' is used when building the static version of storybook.

  //   config.resolve.alias["crypto"] = "crypto-browserify";
  //   config.resolve.alias["stream"] = "stream-browserify";

  //   config.resolve.alias["@holium/design-system"] = path.resolve(
  //     __dirname,
  //     "../node_modules/@holium/design-system"
  //   );

  //   // Return the altered config
  //   return config;
  // },
  stories: [
    // "**/*.stories.mdx",
    "../src/**/stories.@(js|jsx|ts|tsx)",
    // "**/*.stories.@(js|jsx|ts|tsx)",
    "../src/**/*.stories.@(js|jsx|ts|tsx)",
  ],
  addons: [
    "@storybook/addon-links",
    "@storybook/addon-docs",
    "@storybook/addon-essentials",
    "@storybook/addon-controls",
    "@storybook/addon-a11y",
    "@storybook/addon-viewport/register",
    "@storybook/addon-storysource",
    "@storybook/preset-scss",
  ],
  typescript: {
    check: false,
    reactDocgen: "react-docgen-typescript",
    reactDocgenTypescriptOptions: {
      compilerOptions: {
        target: "ES2015",
        module: "ES2015",
        allowSyntheticDefaultImports: true,
        esModuleInterop: true,
        skipLibCheck: true,
        strict: false,
      },
    },
  },
};
