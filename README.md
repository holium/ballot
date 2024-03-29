# Ballot

An app to vote on proposals.

## `/desk`

All the Hoon development goes here.

## `/ui`

Ballot is built primarily using [React], [Typescript], and [@holium/design-system]. [Vite] ensures that all code and assets are loaded appropriately, bundles the application for distribution and provides a functional dev environment.

### Getting Started

To get started using Ballot first you need to run `yarn` inside the `ui` directory.

To develop you'll need a running ship to point to. You should have set up a fake zod in the top level README.md. This will be running on `http://localhost:80`.

Copy the `.env.local-example` file and rename it to `.env.zod`. Set your own ship if you want. This will allow you to run `yarn dev:env zod`. This will proxy all requests to the ship except for those powering the interface, allowing you to see live data.

Regardless of what you run to develop, Vite will hot-reload code changes as you work so you don't have to constantly refresh.

You will need to use `yarn link` to link `@holium/design-system`.

```zsh
cd <path-to-repo>/design-system
yarn link
```

Then in the `ballot/ui` folder run `yarn link "@holium/design-system"`.

#### Url for ballot

```
http://localhost:3000/apps/ballot/booth/~zod/proposals
```

[react]: https://reactjs.org/
[typescript]: https://www.typescriptlang.org/
[vite]: https://vitejs.dev/
