import { toJS } from "mobx";
import shipStore from "./stores/ship";
shipStore.setShip(window.ship);
const baseUrl = import.meta.env.VITE_SHIP_URL?.toString() || "";

export type ActionType = {
  action: string;
  context:
    | {
        resource: string;
        key: string;
        [key: string]: any;
      }
    | undefined;
  effects: EffectType[];
};

export type EffectType = {
  effect: "add" | "update" | "delete" | "initial";
  key: string; // ~zod, group name, etc
  resource: string;
  data: any;
};

export type ChannelResponseType = {
  id?: number;
  json: ActionType | any;
  response: "diff";
};

export class BaseWatcher {
  counter: number = 0; // ~lodlev-migdev - used to generate unique id values
  sse: EventSource | null = null; // ~lodlev-migdev - sse (server-side-events) event source
  ship: string;
  channelUrl: string = "";
  retryTimeout: any = 0;

  constructor() {
    this.ship = shipStore.ship?.toString()!;
  }

  initialize = (app: string, path: string, onChannel: (data: any) => void) => {
    const channelId: string = [
      Date.now(),
      "",
      Math.floor(Math.random() * Number.MAX_SAFE_INTEGER),
    ]
      .toString()
      .replaceAll(",", "");

    this.channelUrl = `${baseUrl}/~/channel/${channelId}`;
    //
    // ~lodlev-migdev
    //    1) poke our ship to create a channel
    //    2) subscribe to the ballot /contexts wire
    //
    this.shconn(app, path, onChannel).then(() => {
      this.subscribe(app, path, onChannel)
        .then(() => console.log(`subscribed to %${app} on ${path}`))
        .catch((e: any) => console.error(e));
    });
  };

  // ~lodlev-migdev - helper to ack a message received on the channel
  ack = async (id: number) => {
    return this.send([
      {
        id: ++this.counter,
        action: "ack",
        "event-id": id,
      },
    ]);
  };

  // ~lodlev-migdev - connect to the ship (create a channel)
  //      and open an event stream
  shconn = async (app: string, path: string, onChannel: any) => {
    return new Promise((resolve, reject) => {
      this.send([
        {
          id: ++this.counter,
          action: "poke",
          ship: this.ship,
          app: "ballot",
          mark: "json",
          // @lodlev-migdev - believe it or not this should be a valid
          //   action at this point under the action/reaction/effect framework
          json: { action: "ping" },
        },
      ])
        .then((res) => {
          this.stream(this.channelUrl, app, path, onChannel);
          resolve(null);
        })
        .catch(reject);
    });
  };

  // ~lodlev-migdev - wrap the fetch call for re-use
  //   be sure to include credentials so that cookies are included in
  //   th request. also make sure payload is an array actions.
  //  see: https://urbit.org/docs/arvo/eyre/guide#using-channels
  send = (payload: any) => {
    return fetch(this.channelUrl, {
      method: "PUT",
      headers: {
        "Content-Type": "application/json",
      },
      // ~lodlev-migdev - this is important and will ensure cookie
      //    is sent with the request
      credentials: "include",
      // ~lodlev-migdev - seems at least one action is required when starting
      //    connecting to the channel. in this case we just poke our ballot
      //    and send a null json to indicate we don't need for the agent to do
      //    anything. simply 'eat' the poke so that the channel is created.
      body: JSON.stringify(payload),
    });
  };

  stream(
    channelUrl: string,
    app: string,
    path: string,
    onChannel: (data: any) => void
  ) {
    // ~lodlev-migdev - now connect to the channel and
    //   listen for notifications from the agent
    this.sse = new EventSource(channelUrl, {
      withCredentials: true,
    });

    this.sse.addEventListener("error", (e) => {
      console.log("An error occurred while attempting to connect.");
    });

    this.sse.addEventListener("message", (e) => {
      let jon = JSON.parse(e.data);

      this.ack(jon.id)
        // .then(() => console.log(`message ${jon.id} ack'd`))
        .catch((e: any) => console.error(e));

      if (jon.response === "diff") {
        onChannel(jon);
      }

      if (jon.response === "quit") {
        console.log(`received a quit. reconnecting to %${app} on ${path}...`);
        this.reconnect(app, path, onChannel);
      }
    });

    this.sse.addEventListener("open", (e) => {
      console.log(`The connection has been established to %${app} on ${path}`);
    });
  }

  reconnect = async (
    app: string,
    path: string,
    onChannel: (data: any) => void
  ) => {
    if (this.retryTimeout !== 0) clearTimeout(this.retryTimeout);
    this.subscribe(app, path, onChannel)
      .then(() => console.log(`re-subscribed to %${app} on ${path}`))
      .catch((e) => {
        console.log(
          `could not subscribe to %${app} on ${path}. retrying in 2 seconds...`
        );
        (function (watcher: BaseWatcher, app: string, path: string) {
          watcher.retryTimeout = setTimeout(() => {
            watcher.reconnect(app, path, onChannel);
          }, 2000);
        })(this, app, path);
      });
  };

  //
  // ~lodlev-migdev
  //    send subscribe action to the specified app/path
  //     - handler will get called when messages are received on the
  //       channel that match the agent wire path
  //
  subscribe = async (
    app: string,
    path: string,
    onChannel: (data: any) => void
  ) => {
    return new Promise((resolve, reject) => {
      const payload = [
        {
          id: ++this.counter,
          action: "subscribe",
          ship: this.ship,
          app: app,
          path: path,
        },
      ];
      this.send(payload)
        .then((res: any) => {
          if (res.response === "diff") {
            onChannel(res.json);
          }
          resolve(null);
        })
        .catch(reject);
    });
  };
  unsubscribe() {
    // console.log(`Connection to channel ${this.channelUrl}`);
    this.sse?.close();
    // this.send({
    //   id: this.channelUrl,
    //   action: "unsubscribe",
    //   subscription: this.counter,
    // });
  }
}

// export const Watcher = new BaseWatcher();
