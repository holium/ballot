import { observable, action, computed, makeAutoObservable } from "mobx";
import { LoaderType, STATE } from "../types/loader";

export class BaseStore {
  @observable loader: LoaderType = {
    isLoading: computed(() => this.loader.state === STATE.LOADING),
    state: STATE.INITIAL,
    set: action((state: STATE) => (this.loader.state = state)),
  };

  constructor() {
    // makeAutoObservable(this);
  }

  isInitial = computed(() => this.loader.state === STATE.INITIAL);
  isLoading = computed(() => this.loader.state === STATE.LOADING);
  isError = computed(() => this.loader.state === STATE.ERROR);
  isLoaded = computed(() => this.loader.state === STATE.ERROR);
}
