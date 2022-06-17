/******************************************************************************
 *
 * @author:  ~lodlev-migdev (p.james)
 * @purpose:
 *   Connects to the local ship and sets up a
 *          subscription to the ballot /contexts wire.
 *
 ******************************************************************************/

export function initializeShipSubscriptions(booths: any[]) {
  // ~lodlev-migdev - used to generate unique id values
  var counter: number = 0;

  // ~lodlev-migdev - map of channel path to handler methods
  //   handlers are called when a message is sent from an agent (on a specific path)
  var stores: any = {};

  // ~lodlev-migdev - sse (server-side-events) event source
  var sse: EventSource | null = null;

  // ~lodlev-migdev - React/UI will need to configure these based on needs
  const ship: string = "zod";
  const secure: boolean = false;
  const protocol: string = secure ? "https" : "http";
  const hostname: string = "localhost";
  const port: number = 80;

  const channelId: string = [
    Date.now(),
    "",
    Math.floor(Math.random() * Number.MAX_SAFE_INTEGER),
  ]
    .toString()
    .replaceAll(",", "");

  const channelUrl: string = `${
    import.meta.env.VITE_SHIP_URL
  }/~/channel/${channelId}`;
  console.log(channelUrl);

  /*****************************************************
   *
   * ~lodlev-migdev
   *   Called when the ballot agent sends a message to the /updates subscription.
   *
   *    example usage (see shconn method):
   *
   *      subscribe("ballot", "/updates", onBallotUpdates)
   *        .then(() => console.log(`subscribed to ballot /updates`))
   *        .catch((e) => console.error(e));
   *
   *  @see: subscribe call in this file
   *
   * @param data - json data sent by the ballot agent
   *   see ballot agent for exact contract/definition
   */
  function onBoothUpdates(data: any) {}

  function stream(channelUrl: string) {
    // ~lodlev-migdev - now connect to the channel and
    //   listen for notifications from the agent
    sse = new EventSource(channelUrl, {
      withCredentials: true,
    });

    sse.addEventListener("error", (e) => {
      console.log("An error occurred while attempting to connect.");
    });

    sse.addEventListener("message", function (e) {
      let jon = JSON.parse(e.data);

      console.log("message => %o", jon);

      // ~lodlev-migdev - use closure to ensure id is in scope
      //   when promise resolve is called
      (function (id) {
        ack(id)
          .then(() => console.log(`message ${id} ack'd`))
          .catch((e) => console.error(e));
      })(jon.id);

      // ~lodlev-migdev - diffs are sent when agents give facts
      //   see: https://urbit.org/docs/arvo/eyre/external-api-ref#diff
      if (jon.response === "diff") {
        // ~lodlev-migdev - build a key from the path. use
        //    it to look up the handler for the message
        //  it is a requirement of all agents to send the path
        //   of the wire where the message originated. this is then used
        //   to map messages to handlers
        const key = jon.json?.path?.replace("/", "_");

        if (stores.hasOwnProperty(key)) {
          const handler = stores[key];
          handler && handler(jon.json);
        }
      }
    });

    sse.addEventListener("open", (e) => {
      console.log("The connection has been established.");
    });
  }

  // ~lodlev-migdev - helper to ack a message received on the channel
  async function ack(id: number) {
    return send(channelUrl, [
      {
        id: ++counter,
        action: "ack",
        "event-id": id,
      },
    ]);
  }

  // ~lodlev-migdev - connect to the ship (create a channel)
  //      and open an event stream
  async function shconn() {
    return new Promise((resolve, reject) => {
      send(channelUrl, [
        {
          id: ++counter,
          action: "poke",
          ship: ship,
          app: "ballot",
          mark: "json",
          // @lodlev-migdev - believe it or not this should be a valid
          //   action at this point under the action/reaction/effect framework
          json: { action: "ping" },
        },
      ])
        .then((res) => {
          stream(channelUrl);
          resolve(null);
        })
        .catch(reject);
    });
  }

  //
  // ~lodlev-migdev
  //    send subscribe action to the specified app/path
  //     - handler will get called when messages are received on the
  //       channel that match the agent wire path
  //
  async function subscribe(
    app: string,
    path: string,
    handler: (data: any) => void
  ) {
    return new Promise((resolve, reject) => {
      const payload = [
        {
          id: ++counter,
          action: "subscribe",
          ship: ship,
          app: app,
          path: path,
        },
      ];
      send(channelUrl, payload)
        .then((res) => {
          const key = path.replace("/", "_");
          if (stores.hasOwnProperty(key)) {
            console.warn(
              `warn: store with path '${path}' exists. replacing...`
            );
          }
          stores[key] = handler;
          resolve(null);
        })
        .catch(reject);
    });
  }

  // ~lodlev-migdev - wrap the fetch call for re-use
  //   be sure to include credentials so that cookies are included in
  //   th request. also make sure payload is an array actions.
  //  see: https://urbit.org/docs/arvo/eyre/guide#using-channels
  async function send(channelUrl: string, payload: any) {
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
  }

  //
  // ~lodlev-migdev
  //    1) poke our ship to create a channel
  //    2) subscribe to the ballot /contexts wire
  //
  shconn().then((res) => {
    subscribe("ballot", `/booths`, onBoothUpdates)
      .then(() => console.log(`subscribed to ballot '/booths'`))
      .catch((e: any) => console.error(e));
    // subscribe to each booth we are a member of
    // if (booths && booths.length > 0) {
    //   for (let i = 0; i < booths.length; i++) {
    //     let booth = booths[i];
    //     console.log(
    //       `connected to '${ship}'. subscribing to ballot '/booths/${booth.key}'`
    //     );
    //     subscribe("ballot", `/booths/${booth.key}`, onBoothUpdates)
    //       .then(() =>
    //         console.log(`subscribed to ballot '/booths/${booth.key}'`)
    //       )
    //       .catch((e: any) => console.error(e));
    //   }
    // }
  });
}
