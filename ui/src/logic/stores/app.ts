import { action, makeAutoObservable, observable } from "mobx";
import { makePersistable } from "mobx-persist-store";
class AppStore {
  public title?: string;
  @observable public currentUrl: string = "";
  @observable public currentPage: string = "proposals";
  @observable public theme: {
    template: "light" | "dark";
  } = { template: "light" };

  constructor() {
    makeAutoObservable(this);
    makePersistable(this, {
      name: "AppStore",
      properties: ["theme"],
      storage: window.localStorage,
    });
  }

  setTitle = action((title: string | undefined) => {
    this.title = title;
  });

  setTheme = action((themeTemplate: "light" | "dark") => {
    this.theme.template = themeTemplate;
  });

  setCurrentUrl = action((url: string, page?: string) => {
    this.currentUrl = url;
    if (page) this.currentPage = page;
  });
}

export default AppStore;
