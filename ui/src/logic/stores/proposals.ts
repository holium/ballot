import {
  observable,
  action,
  runInAction,
  makeAutoObservable,
  computed,
  ObservableMap,
  toJS,
} from "mobx";
import { ShipType } from "./ship";
import { makePersistable } from "mobx-persist-store";
import { ProposalsApi } from "../api/proposals";
import { LoaderType, STATE } from "../types/loader";
import { EffectType } from "../watcher";
import {
  ChoiceType,
  ProposalType,
  BallotType,
  VoteType,
  ProposalMap,
} from "../types/proposals";
import { store } from "../store";
import { timeout } from "../utils/dev";

const determineStatus = (proposal: ProposalType) => {
  const now = new Date().getTime();
  const startTime = new Date(proposal.start).getTime();
  const endTime = new Date(proposal.end).getTime();

  let status = "Draft";
  if (startTime > now) {
    status = "Upcoming";
  }
  if (endTime < now) {
    status = "Ended";
  }

  if (startTime < now && now < endTime) {
    status = "Active";
  }
  return {
    ...proposal,
    status,
  };
};

class ProposalStore {
  @observable public proposalsOld: { [boothName: string]: ProposalType[] } = {};
  @observable public proposals: ObservableMap<string, ProposalMap> =
    observable.map([], { deep: true });

  @observable public boothName: string = "";
  @observable public selectedBooth?: string = undefined;
  @observable public selectedProposal: ProposalType | null = null;
  @observable public ballots: { [proposalId: string]: BallotType[] } = {};

  @observable loader: LoaderType = {
    isLoading: computed(() => this.loader.state === STATE.LOADING),
    state: STATE.INITIAL,
    set: action((state: STATE) => (this.loader.state = state)),
  };

  constructor(private api: ProposalsApi) {
    this.api = api;
    makeAutoObservable(this);
    makePersistable(this, {
      name: "ProposalStore",
      properties: ["proposals", "selectedProposal"],
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
  initial = action(async (boothName: string) => {
    this.loader.set(STATE.LOADING);
    this.selectedBooth = boothName;
    const [proposals, error] = await this.api.getAll(boothName);
    const proposalsMap: ProposalMap = observable.map(
      proposals!.reduce((map: { [key: string]: ProposalType }, current) => {
        // @ts-ignore
        map[current.key] = determineStatus(current);
        return map;
      }, {}),
      { deep: true }
    );
    runInAction(() => {
      this.boothName = boothName;
      this.proposals.set(boothName, proposalsMap);
    });
    this.loader.set(STATE.LOADED);
    return this.proposals;
  });
  //
  //
  //
  create = action(
    async (
      boothKey: string,
      proposalForm: Partial<ProposalType>
    ): Promise<ProposalType> => {
      const [response, error] = await this.api.create(boothKey, proposalForm);
      // TODO standard error handling
      // if (error) return null;
      const newProposal = determineStatus(response.data);
      const currentMap = this.proposals.get(boothKey)!;
      runInAction(() => {
        currentMap.set(newProposal.key, newProposal);
        this.proposals.set(boothKey, currentMap);
      });
      return newProposal;
    }
  );
  //
  //
  //
  update = action(
    async (
      boothName: string,
      proposalKey: string,
      proposalForm: Partial<ProposalType>
    ): Promise<ProposalType> => {
      const [response, error] = await this.api.update(
        boothName,
        proposalKey,
        proposalForm
      );
      // if (error) return null;

      const updatedProposal = determineStatus(response.data);
      const currentMap = this.proposals.get(boothName)!;
      const currentProposal = currentMap.get(proposalKey);

      runInAction(() => {
        currentMap.set(proposalKey, {
          ...currentProposal,
          ...updatedProposal,
        });
        this.proposals.set(boothName, currentMap);
      });

      return currentMap.get(proposalKey)!;
    }
  );
  //
  //
  //
  delete = action(async (boothKey: string, proposalKey: string) => {
    const [response, error] = await this.api.delete(boothKey, proposalKey);
    if (error) return;
    const currentMap = this.proposals.get(boothKey)!;
    runInAction(() => {
      currentMap.delete(proposalKey);
    });
  });
  //
  // ---------------------------------------------
  // ------------- Getters & Setters -------------
  // ---------------------------------------------
  //
  listProposals = (boothName: string) => {
    const proposalMap = this.proposals.get(boothName);
    let proposalsList: ProposalType[] =
      proposalMap && proposalMap!.size > 0
        ? Array.from(this.proposals.get(boothName)!.values())
        : [];
    return proposalsList;
  };
  //
  //
  //
  getProposal = (boothName: string, proposalKey: string) => {
    return this.proposals.get(boothName)!.get(proposalKey);
  };
  //
  //
  //
  setBooth = action((boothName: string) => {
    this.boothName = boothName;
  });
  //
  //
  //
  setProposal = action((boothName: string, proposalKey: string) => {
    const proposal = this.proposals.get(boothName)!.get(proposalKey);
    this.selectedProposal = proposal!;
  });
  //
  //
  //
  getOurResourcePermission = (boothName: string, proposalKey: string) => {
    const proposal = this.proposals.get(boothName)!.get(proposalKey);
    if (proposal && proposal.owner.patp === store.shipStore.ship?.patp) {
      return "owner";
      // add admin permission at some point
    } else {
      return "member";
    }
  };
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
          this.addEffect(context.key, payload.data);
          break;
        case "update":
          this.updateEffect(context.key, payload.key, payload.data);
          break;
        case "delete":
          this.deleteEffect(context.key, payload.key);
          break;
        case "initial":
          console.log("proposal initial effect", payload.key, payload.data);
          break;
      }
    }
  );
  initialEffect = action((boothKey: string, proposalMap: ProposalMap) => {
    this.proposals.set(boothKey, proposalMap);
  });
  //
  //
  //
  addEffect = action((boothKey: string, proposal: ProposalType) => {
    let proposalMap = this.proposals.get(boothKey)!;
    proposalMap.set(proposal.key, determineStatus(proposal));
    this.proposals.set(boothKey, proposalMap);
  });
  //
  //
  //
  updateEffect = action(
    (boothKey: string, proposalKey: string, update: Partial<ProposalType>) => {
      const participantMap = this.proposals.get(boothKey)!;
      const oldProposal = participantMap.get(proposalKey)!;
      participantMap.set(
        proposalKey,
        determineStatus({
          ...oldProposal,
          ...update,
        })
      );
      this.proposals.set(boothKey, participantMap);
    }
  );
  //
  //
  //
  deleteEffect = action((boothKey: string, proposalKey: string) => {
    const proposalMap = this.proposals.get(boothKey)!;
    runInAction(() => {
      proposalMap.delete(proposalKey);
    });
  });
}

export const getProposalFilters = (proposals: ProposalType[]) => {
  if (!proposals) return {};
  const countedStatuses = proposals.reduce<{ [key: string]: number }>(
    (counted, currentProposal, currentIndex) => {
      const status = currentProposal.status;
      // @ts-ignore
      counted[status] = counted[status] || 0;
      // @ts-ignore
      counted[status] += 1;
      return counted;
    },
    {}
  );
  return countedStatuses;
};

export default ProposalStore;
