import {
  action,
  computed,
  makeAutoObservable,
  observable,
  ObservableMap,
  runInAction,
} from "mobx";
import { ParticipantsApi } from "./../api/participants";
import { makePersistable } from "mobx-persist-store";
import { LoaderType, STATE } from "../types/loader";
import { ParticipantMap, ParticipantType } from "../types/participants";
import { timeout } from "../utils/dev";
import { EffectType } from "../watcher";

class ParticipantStore {
  @observable participants: ObservableMap<string, ParticipantMap> =
    observable.map([], { deep: true });

  @observable loader: LoaderType = {
    isLoading: computed(() => this.loader.state === STATE.LOADING),
    state: STATE.INITIAL,
    set: action((state: STATE) => (this.loader.state = state)),
  };

  constructor(private api: ParticipantsApi) {
    makeAutoObservable(this);
    makePersistable(this, {
      name: "ParticipantStore",
      properties: ["participants"],
      storage: window.localStorage,
    });
  }
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
  getParticipants = action(async (boothKey: string) => {
    const [participants, error] = await this.api.getParticipants(boothKey);
    if (error) return null;

    const participantMap = observable(
      participants!.reduce(
        (map: { [key: string]: ParticipantType }, current) => {
          // @ts-ignore
          map[current.name] = current;
          return map;
        },
        {}
      ),
      { deep: true }
    );

    runInAction(() => {
      this.participants.set(boothKey, participantMap);
    });
  });
  //
  //
  //
  addParticipant = action(async (boothKey: string, participantKey: string) => {
    this.loader.set(STATE.LOADING);
    const [response, error] = await this.api.addParticipant(
      boothKey,
      participantKey
    );
    if (error) return null;
    const currentMap = this.participants.get(boothKey)!;
    currentMap[participantKey] = {
      name: participantKey,
      status: "pending",
    };
    runInAction(() => {
      this.participants.set(boothKey, currentMap);
      this.loader.set(STATE.LOADED);
    });
  });
  //
  //
  //
  updateParticipant = action(
    (
      boothName: string,
      participantKey: string,
      update: Partial<ParticipantType>
    ) => {
      const currentMap = this.participants.get(boothName)!;
      const currentParticipant = currentMap[participantKey];
      currentMap[participantKey] = {
        ...currentParticipant,
        ...update,
      };
      return this.participants.set(boothName, currentMap);
    }
  );
  //
  //
  //
  removeParticipant = action(
    async (boothKey: string, participantKey: string) => {
      const [response, error] = await this.api.deleteParticipant(
        boothKey,
        participantKey
      );
      if (error) return null;
      const currentMap = this.participants.get(boothKey)!;
      runInAction(() => {
        delete currentMap[participantKey];
        this.participants.set(boothKey, currentMap);
      });
    }
  );
  //
  // ---------------------------------------------
  // ------------- Getters & Setters -------------
  // ---------------------------------------------
  //
  getParticipantCount = (boothKey: string) => {
    const participantsMap = this.participants.get(boothKey)!;
    if (!participantsMap) return 1; // Default to 1 because host is a participant.
    let count = Object.keys(participantsMap).length || 1; // Default to 1 because host is a participant.
    return count;
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
          return this.addEffect(context.key, payload.data);
        case "update":
          return this.updateEffect(context.key, payload.key, payload.data);
        case "delete":
          return this.deleteEffect(context.key, payload.key);
        case "initial":
          console.log("initial ", payload.key, payload.data);
          break;
      }
    }
  );
  initialEffect = action((boothKey: string, participantMap: ParticipantMap) => {
    this.participants.set(boothKey, participantMap);
  });
  //
  //
  //
  addEffect = action((boothKey: string, participant: ParticipantType) => {
    console.log("participantStore, add effect ", boothKey, participant);
    let participantMap = this.participants.get(boothKey)!;
    participantMap = {
      ...participantMap,
      [participant.name]: participant,
    };
    this.participants.set(boothKey, participantMap);
  });
  //
  //
  //
  updateEffect = action(
    (
      boothKey: string,
      participantKey: string,
      update: Partial<ParticipantType>
    ) => {
      console.log(
        "participantStore, update effect ",
        boothKey,
        " participant ",
        participantKey,
        update
      );
      const participantMap = this.participants.get(boothKey)!;
      const oldParticipant = participantMap[participantKey];
      participantMap[participantKey] = { ...oldParticipant, ...update };
      this.participants.set(boothKey, participantMap);
    }
  );
  //
  //
  //
  deleteEffect = action((boothKey: string, participantKey: string) => {
    console.log(
      "participantStore, delete effect ",
      boothKey,
      " participant ",
      participantKey
    );
    const participantMap = this.participants.get(boothKey)!;
    delete participantMap[participantKey];
    this.participants.set(boothKey, participantMap);
  });
}

export default ParticipantStore;
