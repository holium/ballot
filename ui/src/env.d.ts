interface ImportMetaEnv
  extends Readonly<Record<string, string | boolean | undefined>> {
  /* Add custom env properties here */
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}

declare module "mobx-rest-fetch-adapter";
declare module "urbit-ob";
// declare module "@holium/design-system";
