import { observable, ObservableMap } from "mobx";
import { VoteType } from "../types/proposals";

export const mapStorageAdapter = {
  setItem: (name: string, content: Object) => {
    const result = JSON.stringify(content);
    localStorage.setItem(name, result);
  },
  removeItem: window.localStorage.removeItem,
  // TODO yikes...
  getItem: (key: string) => {
    let item = window.localStorage.getItem(key)!;
    const storeData = JSON.parse(JSON.parse(item));
    if (storeData && storeData.results) {
      // convert to map of map of maps
      item = storeData.results.reduce(
        (boothReduced: ObservableMap, mapArr: any[]) => {
          const booth = mapArr[0];
          const boothProposals = mapArr[1];
          // map.set(booth, );
          const proposalMap = observable.map(
            boothProposals.reduce(
              (proposalReduced: ObservableMap, proposalArr: any[]) => {
                const proposalName = proposalArr[0];
                const proposalVoter = proposalArr[1];
                const voterMap = observable.map(
                  proposalVoter.reduce(
                    (
                      map: { [key: string]: VoteType },
                      voterArr: [string, VoteType]
                    ) => {
                      const voterName = voterArr[0];
                      const voter = voterArr[1];
                      map[voterName] = voter;
                      return map;
                    },
                    {}
                  ),
                  { deep: true }
                );
                proposalReduced.set(proposalName, voterMap);
              },
              observable.map([], { deep: true })
            ),
            { deep: true }
          );
          //
          boothReduced.set(booth, proposalMap);
        },
        observable.map([], { deep: true })
      );
    }
    console.log("after custom get item, ", item);
    return item;
  },
};
