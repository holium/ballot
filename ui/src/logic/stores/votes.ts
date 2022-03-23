import api from "../api";
import {
  makeAutoObservable,
  action,
  observable,
  computed,
  ObservableMap,
} from "mobx";
import { makePersistable } from "mobx-persist-store";
import { LoaderType, STATE } from "../types/loader";
import { VoteMap, VoteType } from "../types/votes";
import { VotesApi } from "../api/votes";
import { EffectType } from "../watcher";
import { timeout } from "../utils/dev";

// Three level map
//
//  VoteBoothMap<'~zod', VoteProposalMap>
//    VoteProposalMap<'proposal-12345', VoteMap>
//      VoteMap<'~bus', VoteType>
//

export type VoteBoothMap = ObservableMap<string, VoteProposalMap>;
export type VoteProposalMap = ObservableMap<string, VoteMap>;

class VoteStore {
  @observable loaders: { [key: string]: LoaderType } = {
    initial: {
      isLoading: computed(() => this.loaders.initial.state === STATE.LOADING),
      state: STATE.INITIAL,
      set: action((state: STATE) => (this.loaders.initial.state = state)),
    },
    casting: {
      isLoading: computed(() => this.loaders.casting.state === STATE.LOADING),
      state: STATE.INITIAL,
      set: action((state: STATE) => (this.loaders.casting.state = state)),
    },
  };
  @observable our: any = null;
  @observable results: VoteBoothMap = observable.map([]);

  constructor(private api: VotesApi) {
    this.api = api;
    makeAutoObservable(this);
    makePersistable(this, {
      name: "VoteStore",
      properties: ["our", "results"],
      storage: window.localStorage,
    });
  }
  //
  // ---------------------------------------------
  // -------------- Loading states ---------------
  // ---------------------------------------------
  //
  isInitial = computed(() => this.loaders.initial.state === STATE.INITIAL);
  isLoading = computed(() => this.loaders.initial.state === STATE.LOADING);
  isError = computed(() => this.loaders.initial.state === STATE.ERROR);
  isLoaded = computed(() => this.loaders.initial.state === STATE.LOADED);
  // Custom
  isCastingLoading = computed(
    () => this.loaders.casting.state === STATE.LOADING
  );
  isCastingError = computed(() => this.loaders.casting.state === STATE.ERROR);
  isCastingComplete = computed(
    () => this.loaders.casting.state === STATE.LOADED
  );
  //
  // ---------------------------------------------
  // ---------------- API actions ----------------
  // ---------------------------------------------
  //
  castVote = action(
    async (boothKey: string, proposalKey: string, chosenVote: any) => {
      this.loaders.casting.set(STATE.LOADING);
      const [response, error] = await this.api.castVote(
        boothKey,
        proposalKey,
        chosenVote
      );
      console.log(
        `sending vote for proposal: ${proposalKey} in booth: ${boothKey}`,
        chosenVote
      );
      console.log("response  ", response);
      this.loaders.casting.set(STATE.LOADED);
      return response;
    }
  );

  initialVotes = action(async (boothKey: string, proposalKey: string) => {
    this.loaders.initial.set(STATE.LOADING);
    const [response, error] = await this.api.initialVotes(
      boothKey,
      proposalKey
    );
    console.log(response);
  });
  //
  // ---------------------------------------------
  // ------------- Getters & Setters -------------
  // ---------------------------------------------
  //
  //
  // ---------------------------------------------
  // -------------- Effect handlers --------------
  // ---------------------------------------------
  //
  onEffect = action(
    async (payload: EffectType, context?: any, action?: any) => {
      await timeout(1500); // simulate long request
      switch (payload.effect) {
        case "add":
          this.addEffect(
            context["booth-key"],
            context["proposal-key"],
            payload.data
          );
          break;
        case "update":
          this.updateEffect(
            context["booth-key"],
            context["proposal-key"],
            payload.data
          );
          break;
        case "delete":
          console.log("should not delete a vote");
          break;
        case "initial":
          console.log(
            "proposal initial effect",
            context["booth-key"],
            context["proposal-key"],
            payload.data
          );
          break;
      }
    }
  );
  initialEffect = action(
    (boothKey: string, proposalVoteKey: VoteProposalMap) => {
      console.log(
        `initial, vote results booth: ${boothKey}, proposalVoteMap: `,
        proposalVoteKey
      );
    }
  );
  //
  // booth: ~zod, proposal: proposal-1647985737067, voter: ~bus {label: 'Approve'}
  //
  addEffect = action(
    (boothKey: string, proposalKey: string, vote: VoteType) => {
      console.log(
        `add, vote results booth: ${boothKey}, proposal: ${proposalKey}, voter:`,
        vote.voter,
        vote.choice
      );
    }
  );
  //
  //
  //
  updateEffect = action(
    (boothKey: string, proposalKey: string, update: Partial<VoteType>) => {
      console.log(
        `update, vote results booth: ${boothKey}, proposal: ${proposalKey}, voter:`,
        update.voter,
        update
      );
    }
  );
}

export default VoteStore;
