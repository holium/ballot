import api from "./api";

const baseUrl = import.meta.env.VITE_SHIP_URL?.toString()!;
// // Sent through PUT to /participants/~bus
// type ActionType = {
//   action: "invite" | "join";
//   resource: string;
//   key: string;
//   data: any;
// };

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

// // Received through channel
// export type ActionType = {
//   action: "invite" | "invite-effect" | "join";
//   reaction?: "ack" | "nawk" | "nod";
//   resource: string;
//   key: string;
//   data: any;
// };

export type ChannelResponseType = {
  id?: number;
  json: ActionType;
  response: "diff";
};

export class BaseWatcher {
  counter: number = 0; // ~lodlev-migdev - used to generate unique id values
  sse: EventSource | null = null; // ~lodlev-migdev - sse (server-side-events) event source
  ship: string;
  channelUrl: string;
  // ~lodlev-migdev - map of channel path to handler methods
  //   handlers are called when a message is sent from an agent (on a specific path)
  stores: any = {};
  onChannel: (data: any) => void = () => {};
  retryTimeout: any = 0;

  constructor() {
    const channelId = [
      Date.now(),
      "",
      Math.floor(Math.random() * Number.MAX_SAFE_INTEGER),
    ]
      .toString()
      .replaceAll(",", "");
    this.channelUrl = `${baseUrl}/~/channel/${channelId}`;
    this.ship = api.ship?.toString()!;
  }

  // onBoothUpdates = (data: any) => {
  //   console.log("onBoothUpdate", data);
  // };

  initialize = (booths: any[], onChannel: (data: any) => void) => {
    this.onChannel = onChannel;
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
    this.shconn().then((res) => {
      this.subscribe("ballot", `/booths`, onChannel)
        .then(() => console.log(`subscribed to ballot '/booths'`))
        .catch((e: any) => console.error(e));
      // subscribe to each booth we are a member of
      // if (booths && booths.length > 0) {
      //   for (let i = 0; i < booths.length; i++) {
      //     let booth = booths[i];
      //     console.log(
      //       `connected to '${this.ship}'. subscribing to ballot '/booths/${booth.key}'`
      //     );
      //     this.subscribe("ballot", `/booths/${booth.key}`, onChannel)
      //       .then(() =>
      //         console.log(`subscribed to ballot '/booths/${booth.key}'`)
      //       )
      //       .catch((e: any) => console.error(e));
      //   }
      // }
    });
  };

  // ~lodlev-migdev - helper to ack a message received on the channel
  ack = async (id: number) => {
    return this.send(this.channelUrl, [
      {
        id: ++this.counter,
        action: "ack",
        "event-id": id,
      },
    ]);
  };

  // ~lodlev-migdev - connect to the ship (create a channel)
  //      and open an event stream
  shconn = async () => {
    return new Promise((resolve, reject) => {
      this.send(this.channelUrl, [
        {
          id: ++this.counter,
          action: "poke",
          ship: this.ship,
          app: "ballot",
          mark: "json",
          json: { command: "null" },
        },
      ])
        .then((res) => {
          this.stream(this.channelUrl);
          resolve(null);
        })
        .catch(reject);
    });
  };

  // ~lodlev-migdev - wrap the fetch call for re-use
  //   be sure to include credentials so that cookies are included in
  //   th request. also make sure payload is an array actions.
  //  see: https://urbit.org/docs/arvo/eyre/guide#using-channels
  send = (channelUrl: string, payload: any) => {
    return fetch(channelUrl, {
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

  stream(channelUrl: string) {
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

      // console.log("message => %o", jon);
      this.onChannel(jon);

      // ~lodlev-migdev - use closure to ensure id is in scope
      //   when promise resolve is called
      // (function (id) {
      this.ack(jon.id)
        .then(() => console.log(`message ${jon.id} ack'd`))
        .catch((e: any) => console.error(e));
      // })(jon.id);

      // ~lodlev-migdev - diffs are sent when agents give facts
      //   see: https://urbit.org/docs/arvo/eyre/external-api-ref#diff
      if (jon.response === "diff") {
        // ~lodlev-migdev - build a key from the path. use
        //    it to look up the handler for the message
        //  it is a requirement of all agents to send the path
        //   of the wire where the message originated. this is then used
        //   to map messages to handlers
        const key = jon.json?.path?.replace("/", "_");

        if (this.stores.hasOwnProperty(key)) {
          const handler = this.stores[key];
          handler && handler(jon.json);
        }
      }

      if (jon.response === "quit") {
        console.log("received a quit. reconnecting to /booths...");
        this.reconnect("ballot", "/booths", this.onChannel);
      }
    });

    this.sse.addEventListener("open", (e) => {
      console.log("The connection has been established.");
    });
  }

  reconnect = async (
    app: string,
    path: string,
    handler: (data: any) => void
  ) => {
    if (this.retryTimeout !== 0) clearTimeout(this.retryTimeout);
    this.subscribe(app, path, this.onChannel)
      .then(() => console.log(`re-subscribed to ballot ${app}://'${path}'`))
      .catch((e) => {
        console.log(
          `could not subscribe to ${app}://${path}. retrying in 2 seconds...`
        );
        (function (
          watcher: BaseWatcher,
          app: string,
          path: string,
          handler: (data: any) => void
        ) {
          watcher.retryTimeout = setTimeout(() => {
            watcher.reconnect(app, path, handler);
          }, 2000);
        })(this, app, path, handler);
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
    handler: (data: any) => void
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
      this.send(this.channelUrl, payload)
        .then((res) => {
          const key = path.replace("/", "_");
          if (this.stores.hasOwnProperty(key)) {
            console.warn(
              `warn: store with path '${path}' exists. replacing...`
            );
          }
          this.stores[key] = handler;
          resolve(null);
        })
        .catch(reject);
    });
  };
}

export const Watcher = new BaseWatcher();
