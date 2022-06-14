### Getting Started

[Installing Urbit](https://urbit.org/getting-started/cli)

[Development Ships](https://urbit.org/docs/development/environment#development-ships)

**Note: When working with the Development Ships instructions above, change all references to %mydesk to %ballot.**

### Installing ballot

From a command prompt (`<project-dir>/ballot folder`), run the `copy-desk.sh <ship-name> ballot`

This will copy all `./ballot/desk` files to the Urbit ship running on the localmachine (e.g. `./ballot/ships/zod`).

From the dojo (Urbit command line), run the following:

```hoon
|install our %ballot
```

Installing ballot will:

- Create a default booth based on your ship name (e.g. ~zod)
- Create a booth for all groups you own (have created)

### Running ballot

From the dojo, run the following:

```hoon
|rein %ballot [& %ballot]
```

### Usage

There are a number of ways to interact with the ballot agent:

- Directly within the dojo
- Interfacing over HTTP (REST based API)
- Signaling the agent over channels/wires

## Action / Reaction / Effects

### Action

An action is initiated by the source ship `our.bowl` (ie. a user clicks invite `~bus`, their ship (`~zod`) pokes `~bus`.

### Reaction

Reactions can be initiated by the destination ship `src.bowl` (ie. `~bus` responds to the invite action from `~zod`) or the source ship `our.bowl` (ie. `~zod` sends a reaction to `~bus`'s reaction to the original action).

A reaction is an action that is triggered that the user doesn't initiate.

### Effects

An effect initiates a change to state based on actions and reactions. Effects are propagated in the local server only. Effects do not send pokes to other ships, they only change the state and notify the UI.

### Example

An example:

- `~zod` invites `~bus`
- `~bus` acknowledges receiving invite.

#### `~zod` flow

- **action**: `~zod` invites '~bus`
- **effect**: add `~bus` to local store with `status: pending`

Now `~zod` is waiting for a reaction.

- **reaction**: `~bus` acknowledges receiving invite.
- **effect**: `~zod` updates local store with `~bus` as `status: invited`

## Ballot API

All actions funnel thru the `<ship-url>/ballot/api/booths` endpoint as HTTP POST requests.

Each ship supports the following actions:

- invite
- accept
- save-booth
- save-proposal
- delete-proposal
- cast-vote
- delete-participant
- delegate
- undelegate

## Inviting a participant to a booth

```
action  :  invite
endpoint:  /ballot/api/booths
method  :  POST
payload :  see below
```

Payload definition for invite

```jsonc
{
  "action": "invite",
  "resource": "booth",
  "context": {
    "booth": "<booth-key>",
    // participant ship name (e.g. ~bus)
    "participant": "<participant-key>"
  },
  // optional - ignored
  "data": {}
}
```

**Error Handling Actions**

In addition to logging output in the dojo, ship UIs will receive errors as effects from the system. Errors are dependent on the actions invoked.

Error effect payloads are sent as reactions to an originating action. Error effects follow this general format:

```jsonc
{
  // e.g. when action is invite, the error action will be "invite-reaction"
  "action": "<action>-reaction",
  "resource": "<resource>",
  "context": {
    // action specific data
  },
  "effects": [
    {
      "resource": "<resource>",
      "effect": "error",
      "data": {
        "error": "<error message>"
      }
    }
  ]
}
```

**Custom Actions**
Custom actions give app developers a way to extend on the functionality of the baseline ballot app. Custom actions are executed when a poll is completed. These actions are based on the voting results. As app developers, you can determine the voting choices for a proposal, and additionally assign a custom action to be executed when a voting decision is reached.

By default, ballot comes with the following custom actions:

- **No action** - no action is executed when a poll is complete

- **Invite Member** - valid for group booths only. invites a member to a group booth. invited members must go through the basic group invite workflow (groups app) to accept the invitation. This in turn will add the member to the group booth.

- **Kick Member** - removes a member from the group booth

As mentioned, by default the ballot app comes with two predefined custom actions: invite-member and kick-member.

These are configured in the `<desk>/lib/ballot/custom-actions/config.json` file.

To customize the actions that are available to all booths on your ship, you will need to modify the file and commit any changes.

The format of the config files is as follows. Note that there would be on key per custom action; meaning this config files supports multiple custom actions.

```jsonc
{
  // custom action key - e.g. invite-member. note that whatever you specify here will need to become the <custom-action-key>.hoon file that includes the custom action source code to be executed.
  "<custom-action-key>": {
    // custom action label as it appears in the UI
    "label": "<label>", // e.g. Invite Member
    // custom action description as it appears in the UI
    "description": "<description>" // e.g. Invites a member to the associated group by poking %group-store",
    // custom action form. simple form descriptor indicating the name and type of input(s) to accept when configuring the action. these inputs are captured at runtime and passed to the custom action handler when a polling decision is reached
    "form": {
      "member": {
        "type": "cord"
      }
    }
  }
}
```

In addition to this configuration file, you will need to add a corresponding `<custom-action-key>.hoon` file to the `<desk>/lib/ballot/custom-actions` folder. For example, for the `invite-member` action, there MUST BE a corresponding `<desk>/lib/ballot/custom-actions/invite-member.hoon` file where the custom action code is included.

Custom action source files MUST follow the format of the `invite-member.hoon` and `kick-member.hoon` files that are provided by default. This is because these source files are called with certain expectations for context and gate input arguments.

Here is the simplest valid form:

```hoon
/-  *plugin, ballot
|%
++  on
  |=  [=bowl:gall store=state-1:ballot context=[booth-key=@t proposal-key=@t]]
  |%
    ++  action
      |=  [action-data=json payload=json]
      ^-  action-result

      `action-result`[%.n ~ ~ ~]
  --
--
```

Notes

- \*plugin include is to pull in the definition of the action-result type
- ballot include is to pull in the ballot state
- `++ on` arm is required and must be named as such
- context information includes:
  - bowl - gall bowl (on-poke)
  - store - ballot state (generic json)
  - context - booth-key and proposal-key
- `++ action` arm is required and must be named as such
- `++ action` gate arguments
  - action-data - top choice action data. the format/definition of this data will depend on the custom action configuration. in the case of `invite-member`, since the "form" config defines a member input of type cord, the `data` element of the payload will contain a `member` element with a value of type `cord` - containing the member value entered in the proposal form.
  - payload - this is the poll tally results payload a json (see below)
- `++ action` must return an `action-result` type (see `<desk>/sur/plugin.hoon` for more information)

**custom action `payload` gate argument format**

```jsonc
{
  "status": "counted | failed",
  "voteCount": "<@ud>", // total # of votes cast
  "participantCount": "<@ud>", // number of participants that voted
  "topChoice": "<label>", // label of the top choice (e.g. Approve)
  // note tallies array will not exist if status = 'failed'
  "tallies": "array of json" // array of tally objects (see tally below)
}
```

**tally format**

```jsonc
{
  "label": "<choice label>", // e.g. 'Approve'
  "action": "<custom-action-key>", // e.g. `invite-member`
  "count": "@ud", // num votes for this choice>
  "percentage": "@ud" // percentage of overall votes for this choice
}
```
