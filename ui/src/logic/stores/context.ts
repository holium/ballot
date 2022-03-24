// import { action, makeAutoObservable, observable } from "mobx";
// import { PersistStoreMap, makePersistable } from "mobx-persist-store";
// import {store} from '../store'
// type ContextType = {name: string}

// class ContextStore {
//   @observable public contexts: any[] = []

//   constructor() {
//     makePersistable(this, {
//       name: "AppStore",
//       properties: ["contexts"],
//       storage: window.localStorage,
//     });
//   }

//   initial = (contexts: ContextType[]) => {
//     contexts.forEach((context: ContextType) => {
//       PersistStoreMap.set(
//         [context.name], store.boothStore
//     ) }
//   }

//   setTitle = action((title: string | undefined) => {
//     this.title = title;
//   });

//   setTheme = action((themeTemplate: "light" | "dark") => {
//     this.theme.template = themeTemplate;
//   });

//   setCurrentUrl = action((url: string, page?: string) => {
//     this.currentUrl = url;
//     if (page) this.currentPage = page;
//   });
// }

// export default AppStore;
export default {};
