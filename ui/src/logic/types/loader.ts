import { IComputedValue, IActionFactory } from "mobx";

export enum STATE {
  INITIAL = "initial",
  LOADING = "loading",
  ERROR = "error",
  LOADED = "loaded",
}

export type LoaderType = {
  isLoading: IComputedValue<boolean>;
  state: STATE;
  set: (state: STATE) => STATE;
};
