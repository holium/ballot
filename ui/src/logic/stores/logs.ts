import { action, makeAutoObservable, observable } from "mobx";
import { makePersistable } from "mobx-persist-store";

class LogStore {
  @observable logs: any[] = [];

  constructor() {
    makeAutoObservable(this);
    makePersistable(this, {
      name: "LogStore",
      properties: ["logs"],
      storage: window.localStorage,
    });
  }

  addLog = action((log: any) => {
    this.logs.push({ time: new Date().getTime(), log });
  });

  getLogs = () => {
    return this.logs;
  };
}

export default LogStore;
