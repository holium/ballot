import { EffectType } from "./../watcher";
import { LoaderType, STATE } from "../types/loader";
import { BoothsApi } from "./../api/booths";
import {
  action,
  runInAction,
  observable,
  makeAutoObservable,
  computed,
  toJS,
  ObservableMap,
} from "mobx";
import { makePersistable } from "mobx-persist-store";
import { timeout } from "../utils/dev";
import { BoothType } from "../types/booths";
import { store } from "../store";
import { ResourcePermissionType } from "../types/common";

class BoothStore {
  @observable loader: LoaderType = {
    isLoading: computed(() => this.loader.state === STATE.LOADING),
    state: STATE.INITIAL,
    set: action((state: STATE) => (this.loader.state = state)),
  };
  @observable booth?: BoothType;
  @observable booths_old: BoothType[] = [];
  @observable booths: ObservableMap<string, BoothType> = observable.map([], {
    deep: true,
  });
  @observable private actions: { [key: string]: any } = {};

  constructor(private api: BoothsApi) {
    this.api = api;
    makeAutoObservable(this);
    makePersistable(this, {
      name: "BoothStore",
      properties: ["booths", "booth"],
      storage: window.localStorage,
    });
  }

  list = (): BoothType[] => {
    return Array.from(this.booths.values());
  };
  //
  // ---------------------------------------------
  // -------------- Loading states ---------------
  // ---------------------------------------------
  //
  isInitial = computed(() => this.loader.state === STATE.INITIAL);
  isLoading = computed(() => this.loader.state === STATE.LOADING);
  isError = computed(() => this.loader.state === STATE.ERROR);
  isLoaded = computed(() => this.loader.state === STATE.LOADED);
  //
  // ---------------------------------------------
  // ---------------- API actions ----------------
  // ---------------------------------------------
  //
  fetchAll = action(async () => {
    this.loader.set(STATE.LOADING);
    const [booths, error] = await this.api.getAll();
    if (error) return null;
    runInAction(() => {
      // this.booths = booths;
      // participants
      booths.forEach((booth: BoothType) => {
        this.booths.set(booth.name, this.setOurResourcePermission(booth));
        // @ts-ignore
        store.participantStore.getParticipants(booth.name);
      });
    });
    this.loader.set(STATE.LOADED);
    return this.booth;
  });
  //
  // action: join
  //
  joinBooth = action(async (boothName: string) => {
    const [response, error] = await this.api.join(boothName);
    if (error) console.log(error);
    runInAction(() => {
      this.actions[`${response.action}-${response.key}`] = "waiting";
    });
    return response;
  });
  //
  // action: accept
  //
  acceptInvite = action(async (boothName: string) => {
    const [response, error] = await this.api.acceptInvite(boothName);
    if (error) console.log(error);
    this.update(boothName, { status: "pending" });
    runInAction(() => {
      this.actions[`${response.action}-${response.key}`] = response.status;
    });
    return;
  });
  //
  // ---------------------------------------------
  // ------------- Getters & Setters -------------
  // ---------------------------------------------
  //
  getBooth = (boothName: string) => {
    return this.booths.get(boothName)!;
  };
  //
  //
  //
  getBoothName = () => {
    return this.booth?.name;
  };
  //
  //
  //
  setBooth = action(async (booth: BoothType) => {
    runInAction(() => {
      this.booth = {
        ...booth,
        meta: {
          color: "#000000",
        },
      };
    });
  });
  hasAdmin = (boothKey: string) => {
    const booth = this.booths.get(boothKey);
    if (booth) return booth.permission === "owner";
    return false;
  };
  //
  //
  //
  checkAction = (key: string) => {
    return this.actions[key];
  };
  //
  //
  //
  listActions = () => {
    return this.actions;
  };
  //
  //
  //
  setOurResourcePermission = (booth: BoothType) => {
    let permission: ResourcePermissionType = "member";
    if (booth.owner === store.shipStore.ship?.patp) {
      permission = "owner";
      // add admin permission at some point
    } else {
      permission = "member";
    }
    booth.permission = permission;
    return booth;
  };
  //
  // ---------------------------------------------
  // -------------- Effect handlers --------------
  // ---------------------------------------------
  //
  onEffect = action(
    async (payload: EffectType, context?: any, action?: any) => {
      await timeout(3000); // simulate long request
      switch (payload.effect) {
        case "add":
          return this.add(payload.data);
        case "update":
          return this.update(payload.key, payload.data);
        case "delete":
          return this.delete(payload.key);
        case "initial":
          return this.initial(payload);
      }
    }
  );
  //
  //
  //
  initial = action((payload: any) => {
    const { booth, participants, proposals, votes } = payload.data;
    // console.log("boothStore, initial effect ", booth, participants, proposals);
    // 1. update booth
    this.booths.set(booth.key, booth);
    // 2. add booth participants
    store.participantStore.initialEffect(booth.key, participants);
    // 3. add booth proposals
    store.proposalStore.initialEffect(booth.key, proposals);
    store.voteStore.initialEffect(booth.key, votes);
  });
  //
  //
  //
  add = action((booth: BoothType) => {
    // console.log("boothStore, add effect ", booth);
    this.booths.set(booth.name, booth);
  });
  //
  //
  //
  update = action((boothKey: string, booth: Partial<BoothType>) => {
    // console.log("boothStore, update effect ", boothKey, " booth ", booth);
    const oldBooth = this.booths.get(boothKey)!;
    this.booths.set(boothKey, { ...oldBooth, ...booth });
  });
  //
  //
  //
  delete = action((boothKey: string) => {
    // console.log("boothStore, delete effect ", boothKey);
    this.booths.delete(boothKey);
  });
}

export default BoothStore;
