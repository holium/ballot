# Data Structure

## Polls

There are four structures: `booth`, `poll` | `proposal`, `ballot`, `comment`.

- **Booth**: The top level data structure. A booth is a graph that contains polls.
- **Poll**: A data structure that contains information about the poll (i.e. title, strategy, choices, etc.), the `ballots`, and `comments` associated with it.
- **Proposal** (v2): A data structure that contains information about a proposal (i.e. title, strategy, action, choices, etc.), the `ballots`, and `comments` associated with it.
- **Ballot**: A node that represents a ship's casted vote. Depending on the `strategy` of voting, there could be one, or multiple, per ship.
- **Comment**: These are comments posted about a poll.

Below is the graph layout.

```txt
|- Booth
 \
  |- Poll | Proposal
   \
    |- Ballot
    |- Comment
```

Every `booth` represents a collection of `polls` or `proposals`. A booth can be of three types: `ship`, `group`, `colony`.

### `booth` types:

- **ship**: the `ship` type contains all polls that the ship (i.e. `~lomder-librun`) is hosting or has been invited to by outside groups and colonies.
- **group**: the `group` type contains all polls for a specific `group` (i.e. `~lomder-librun/the-river`) that a `ship` has joined.
- **colony**: (v2) the `colony` type contains all polls for a specific `colony` (i.e. `~lomder-librun/colony/mars-one`) that a `ship` is a member of.

The paths would be:

- `/apps/vote/~vote/booth/ship/~lomder-librun/poll`
- `/apps/vote/~vote/booth/group/~lomder-librun/the-river/poll`
- `/apps/vote/~vote/booth/colony/~lomder-librun/colony/mars-one/proposal`

### `poll` metadata

```hoon
+$  poll
  $:  title=@t
      body=@t
      strategy=?(%single-choice %multi-choice)
      hide-individual-vote=?(%yes %no)
      choices=(list choice)
      invitees=(set ship)
      start=@d
      end=@d
      created-by=ship
      created-at=time
  ==
```

### `ballot` metadata

```hoon
+$  ballot
  $:  voter=ship
      =choice
      =signature
      created-at=time

  ==
```

### `comment` structure

```hoon
+$  comment
  $:  author=ship
      text=@t
  ==
```

## Architecture

Below is an attempt to define the architecture of the ballot application.

```
desk
├── app
│   ├── booth-view.hoon
│   ├── booth-pull-hook.hoon
│   ├── booth-push-hook.hoon
│   ├── booth-store.hoon
│   ├── delegate-view.hoon
│   ├── delegate-pull-hook.hoon
│   ├── delegate-push-hook.hoon
│   └── delegate-store.hoon
├── gen
├── lib
│   ├── booth.hoon
│   ├── booth-view.hoon
│   ├── booth-store.hoon
│   ├── delegate.hoon
│   ├── delegate-view.hoon
│   └── delegate-store.hoon
├── mar
│   ├── booth
│   │   ├── action.hoon
│   │   └── update.hoon
│   ├── delegate
│   │   ├── action.hoon
│   │   └── update.hoon
├── sur
│   ├── booth-store.hoon
│   ├── booth-view.hoon
│   ├── delegate-store.hoon
│   └── delegate-view.hoon
├── ted
└── tests
```

### Concepts

#### Hooks (controllers)

- pull-hook: A pull-hook syncs data from a remote resource down to a local resource.
- push-hook: A push-hook allows remote ships to subscribe to and sync down the information from a local resource.
- observe-hook: The observe-hook subscribes to data coming in from another agent, and starts up a thread of computation every time a subscription update from that agent is received.
- poke-proxy-hooK: The poke-proxy-hook conditionally forwards a poke from a foreign ship to a store on the local ship if the foreign ship has permission to do so.

#### Stores (models)

A store may only accept local reads and writes, not remote ones. All interaction with the stores are done through hooks.

Landscape maintains the following stores:

- `%graph-store`
- `%group-store`
- `%metadata-store`
- `%contact-store`
- `%invite-store`

We will build the following stores:

- `%booth-store`
- `%delegate-store`

### Agents

We will build the following agents

- `%booth` agent
- `%delegate` agent

### Features

#### `%booth-store` (new)

This stores all metadata about a voting booth and also tracks all `%ballots` that are submitted. This store must validate

#### `%delegate-store` (new)

This keeps track of delegation of various Urbit IDs in relation to `%booth`. An example would be `~lomder-librun` delegates their vote to `~livdux-fognex` in the group `~master-forwex/galactic-tooling`, which means that `~livdux-fognex`'s voting power in `galactic-tooling` is `2`.

#### `%group-store` (integration)

We want to utilize the `groups` concept from landscape in order to store voting booths and utilize the policies implemented for access. We really only need to read from the `%groups-store` and store booths in reference to groups.

#### `contact` (integration)

Landscape currently has `%contact-store` which keeps tack of nicknames, profile pictures, sigil color, etc. We need to load this data from the `%contact-store`.

#### `hark` (integration)

Currently, there is a notification subsystem built into landscape and the app grid. It's called `%hark-store`. We need to add our notifications into this structure.
