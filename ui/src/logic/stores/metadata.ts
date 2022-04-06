import { rootStore } from "./root";
import { LoaderModel } from "./common/loader";
import { types, Instance, clone } from "mobx-state-tree";
import { BaseWatcher, ChannelResponseType } from "../watcher";

export type LandscapeGroup = {
  color: string;
  creator: string;
  description: string;
  picture: string;
  title: string;
};
export type MetadataType = { "app-name": string; group: string; metadata: any };

export function cleanColor(ux: string) {
  if (ux.length > 2 && ux.substr(0, 2) === "0x") {
    const value = ux.substr(2).replace(".", "").padStart(6, "0");
    return `#${value}`;
  }

  const value = ux.replace(".", "").padStart(6, "0");
  return `#${value}`;
}

export const GroupMetadataModel = types.model({
  color: types.string,
  description: types.maybeNull(types.string),
  picture: types.maybeNull(types.string),
  title: types.maybeNull(types.string),
});

export type GroupModelType = Instance<typeof GroupMetadataModel>;
export function cleanGroupMetadata({
  color,
  description,
  picture,
  title,
}: GroupModelType) {
  color = cleanColor(color);
  return { color, description, picture, title };
}

export const ContactMetadataModel = types.model({
  avatar: types.maybeNull(types.string),
  color: types.optional(types.string, "#000"),
  nickname: types.maybeNull(types.string),
});
export type ContactModelType = Instance<typeof ContactMetadataModel>;

export function cleanContact({
  color,
  avatar,
  nickname,
}: ContactModelType): ContactModelType {
  color = cleanColor(color);
  return { color, avatar, nickname };
}

const GroupWatcher = new BaseWatcher();
const ContactWatcher = new BaseWatcher();

export const MetadataModel = types
  .model("MetadataStore", {
    groupsLoader: types.optional(LoaderModel, { state: "initial" }),
    contactsLoader: types.optional(LoaderModel, { state: "initial" }),
    groupsMap: types.optional(types.map(GroupMetadataModel), {}),
    contactsMap: types.optional(types.map(ContactMetadataModel), {}),
  })
  .views((self) => ({
    getGroupMetadata(groupName: string) {
      return self.groupsMap.get(groupName);
    },
  }))
  .actions((self) => ({
    setContactMap(contactMap: any) {
      self.contactsMap = contactMap;
      // TODO implement updates. For now, close after initial
      ContactWatcher.unsubscribe();
    },
    setGroupMap(groupsMap: any) {
      self.groupsMap = groupsMap;
      // TODO implement updates. For now, close after initial
      GroupWatcher.unsubscribe();
    },
    getMetadata() {
      // If we havent loaded this, lets load
      self.groupsLoader.set("loading");
      GroupWatcher.initialize(
        "metadata-store",
        "/all",
        (data: ChannelResponseType) => {
          const metadata = data.json["metadata-update"];
          // Only look for the initial associations key
          if (metadata["associations"]) {
            const associations: MetadataType = metadata
              ? metadata["associations"]
              : {};
            const groupsMap = Object.values(associations)
              .filter(
                (metadata: MetadataType) => metadata["app-name"] === "groups"
              )
              .reduce((groupMap, currentGroup: MetadataType, index) => {
                const groupPathSplit = currentGroup["group"].split("/");
                // remove the /ship/ from the group name
                groupPathSplit.shift();
                groupPathSplit.shift();
                const shipGroup = groupPathSplit.join("-groups-");
                groupMap[shipGroup] = cleanGroupMetadata(currentGroup.metadata);
                return groupMap;
              }, {});
            Object.keys(groupsMap).forEach((group: string) => {
              // If there is extra metadata
              if (groupsMap[group]) {
                rootStore.store.setGroupMetadata(group, groupsMap[group]);
              }
            });
            rootStore.metadata.setGroupMap(groupsMap);
            self.groupsLoader.set("loaded");
          } else {
            // TODO other metadata store updates
            // console.log("other event", data);
          }
        }
      );
    },
    getContactMetadata: () => {
      self.contactsLoader.set("loading");
      ContactWatcher.initialize(
        "contact-store",
        "/all",
        (data: ChannelResponseType) => {
          const contactInitial: any = data.json["contact-update"];
          const initial: any = contactInitial && contactInitial["initial"];
          // Only look for the initial key
          if (initial) {
            const rolodex: Map<string, ContactModelType> =
              initial && initial["rolodex"];
            const contactKeys = Object.keys(rolodex || {});
            const contactMap = Object.values(rolodex).reduce(
              (
                contacts: any,
                currentContact: ContactModelType,
                index: number
              ) => {
                const contactName = contactKeys[index];

                contacts[contactName] = ContactMetadataModel.create(
                  cleanContact(currentContact)
                );
                return contacts;
              },
              {}
            );
            rootStore.store.ships.forEach((ship) => {
              if (contactMap[ship.name]) {
                rootStore.store.setShipMetadata(
                  ship.name,
                  clone(contactMap[ship.name])
                );
              }
            });

            // setContactMap();
            // self.contactsMap = contactMap;
            rootStore.metadata.setContactMap(contactMap);
            self.contactsLoader.set("loaded");
          } else {
            // TODO other contact store updates
            // console.log("other event", data);
          }
        }
      );
    },
  }));

export type MetadataModelType = Instance<typeof MetadataModel>;
