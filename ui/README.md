# Ballot UI

A React app that interfaces with the `%ballot` desk and agents.

## Getting started

Run `yarn` to install dependencies. Next you need to link the design system.

### Design system

You will need to use `yarn link` to link [`@holium/design-system`](https://github.com/holium/design-system).

```zsh
cd <path-to-repo>/design-system
yarn link
```

Then in the `ballot/ui` folder run `yarn link "@holium/design-system"`.

### Start the dev server

When you have installed the dependencies and linked the design system, run `yarn dev` to start the app on `localhost:3000`.

Run `yarn dev:env bus` to start another ui instance for the `~bus` fake ship. Will run on `localhost:3001`. Yu will need to make a new `.env.bus` file with the variables set appropriately.

Once running try to load: `http://localhost:3000/apps/ballot/booth/ship/~zod/proposals`

## Storybook

There is a storybook for this app. Run `yarn storybook` to start it on `localhost:6007`

## Deploying

To deploy, run `yarn build` in the `ui` directory which will bundle all the code and assets into the `dist/` folder. This can then be made into a glob by doing the following:

1. Start your fake zod in the `<repo>/ships` folder.
2. On that urbit, if you don't already have a desk to run from, run `|merge %ballot our %base` to create a new desk and mount it with `|mount %ballot`.
3. Now the `%ballot` desk is accessible through the host OS's filesystem as a directory of that urbit's pier ie `~/zod/ballot`.
4. From the `ui` directory you can run `rsync -avL --delete dist/ ~/zod/ballot/app` where `~/zod` is your fake urbit's pier.
5. Once completed you can then run `|commit %ballot` on your urbit and you should see your files logged back out from the dojo.
6. Now run `=dir /=garden` to switch to the garden desk directory
7. You can now run `-make-glob %ballot /app` which will take the folder where you just added files and create a glob which can be thought of as a sort of bundle. It will be output to `~/zod/.urb/put`.
8. If you navigate to `~/zod/.urb/put` you should see a file that looks like this `glob-0v5.fdf99.nph65.qecq3.ncpjn.q13mb.glob`. The characters between `glob-` and `.glob` are a hash of the glob's contents.
9. Now that we have the glob it can be uploaded to any publicly available HTTP endpoint that can serve files. This allows the glob to distributed over HTTP.
10. Once you've uploaded the glob, you should then update the corresponding entry in the docket file at `desk/desk.docket-0`. Both the full URL and the hash should be updated to match the glob we just created, on the line that looks like this:

```hoon
    glob-http+['https://bootstrap.urbit.org/glob-0v5.fdf99.nph65.qecq3.ncpjn.q13mb.glob' 0v5.fdf99.nph65.qecq3.ncpjn.q13mb]
```

11. This can now be safely committed and deployed.
