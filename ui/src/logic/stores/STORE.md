## Store structure

We use a lib called `mobx-state-tree` to which helps us manage our state. It is organized as a tree with map hierarchies to various models.

```
|- booth-store
|   \
|   |- booth-model
|   |   \
|   |   |- {...booth-data}
|   |   |- participant-store
|   |   |   \
|   |   |    | - participant-model
|   |   |   /
|   |   |- proposal-store
|   |   |  \
|   |   |   |- proposal-model
|   |   |   |  \
|   |   |   |   |- {...proposal-data}
|   |   |   |   |- choices
|   |   |   |   |- poll
|   |   |   |   |  \
|   |   |   |   |   |- status
|   |   |   |   |- results
|   |   |   |   |   \
|   |   |   |   |    |- tally-model
|   |   |   |   |    |- vote-model
```

## Actions, reactions, and effects

An action initiates a change to the store. An action (as of now) can only manipulate your own ship. An effect is propagated to watchers and your UI.

You can think of an `action` as a `poke`, but they are guaranteed to produce effects that any watcher should expect.

You can think of an `effect` as a standardized format for facts.

The reason we developed our own methodology for this is because we needed a more robust structure for how we manage our UI stores, agent stores, and how watchers manager their stores.

### Actions

Each action has a standard structure:

```js
{
  action: "<action-name>",
  resource: "<resourceName>",
  context: {
    booth: boothKey,
    '<resourceName>': resourceKey
  },
  data: {},
}
```

### Reactions

Each reaction has a standard structure:

```js
{
  action: "<action-name>-reaction",
  context: {
    booth: boothKey,
    '<resourceName>': resourceKey
  },
  effects: [{
    resource: "<resourceName>",
    key: resourceKey,
    effect: "add",
    data: {}
  }]
}
```

#### Effects

Effects tell a watcher to perform operations on their local resources. A watcher can be an `agent` or a `user interface`.

- `add`: create a new resource in the context
- `update`: update a resource in the context
- `delete`: delete a resource in the context
- `initial`: create all resources in the context

## `%ballot` action API

### `save-proposal` flow

### Action: `save-proposal`

- **Resource**: `proposal`
- **Method**: `POST`
- **Route**: `/ballot/api/booths`
- **Body**:

```js
  {
    id: '<id>',
    action: "save-proposal",
    resource: "proposal",
    context: {
      booth: boothKey,
    },
    data: {
      start: {
        mode: 'immediate', // start: 1648702800999

      },
      end: {
        mode: 'timer'
        date: 1649307600999
      },
      ...proposal
    },
  }
```

**Response**:

```js
{
  action: "save-proposal",
  resource: "proposal",
  context: {
    booth: boothKey,
  },
  data: {
    source: 'xyz123',
    proposal: {}
  },
}
```

```js
{
  end: {
    mode: 'timer'
    date: 1649307600999
  },
  end: {
    mode: 'vote-threshold'
    threshold: .70
  },
  start: {
    mode: 'immediate', // start: 1648702800999
  },
  start: {
    mode: 'timer'
    date: 1648702800999
  },
}
```

This action creates a proposal record and starts a thread that will fire when the proposal `start` is reached on the host machine.

It produces the following effects as a `reaction`:

A `reaction` is a list of `effects` that are triggered by the response to an `action`.

#### Reaction: `save-proposal-reaction`

```js
{
  source: '<id>',
  action: "save-proposal-reaction",
  context: {
    booth: "~zod",
    proposal: "proposal-1648736647426"
  },
  effects: [
    {
      resource: "proposal",
      key: "proposal-1648736647426",
      effect: "add",
      data: {},
    },
  ]
}
```

#### Reaction: `poll-started-reaction`

```js
{
  source: '<id>',
  action: "poll-started-reaction",
  context: {
    booth: "~zod",
    proposal: "proposal-1648736647426"
  },
  effects: [
    {
      resource: "poll",
      key: "<poll-key>",
      effect: "add",
      data: {},
    }
  ]
}
```

#### `proposal` `add` effect

```js
{
  resource: "proposal",
  key: "proposal-1648736647426",
  effect: "add",
  data: {},
},
```

#### `poll` `add` effect

```js
{
  resource: "poll",
  key: "<poll-key>",
  effect: "add",
  data: {},
}
```
