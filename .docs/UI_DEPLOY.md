# Deploying the UI

1. Run `yarn build` in the `ballot/ui` directory. Make sure you have a `.env.production` file set with the following environment variables:
   ```bash
   # .env.production
   NODE_ENV=production
   ```
2. From the `ballot/ui` directory you can run `rsync -avL --delete dist/ ../ships/zod/ballot/app/ui` where `/zod` is your fake urbit's pier.
3. Once completed you can then run `|commit %ballot` on your urbit and you should see your files logged back out from the dojo.
4. Now run `=dir /=garden` to switch to the garden desk directory.
5. You can now run `-make-glob %ballot /app/ui` which will take the folder where you just added files and create a glob which can be thought of as a sort of bundle. It will be output to `~/zod/.urb/put`. It should be in the format `glob-<hash>.glob`.
6. Switch back to `=dir /=`
7. Upload this file to a Digital Ocean Space.
8. Update the `ballot/desk.docket-0` to the new glob.

```hoon
    glob-http+['https://bootstrap.urbit.org/glob-0v5.fdf99.nph65.qecq3.ncpjn.q13mb.glob' 0v5.fdf99.nph65.qecq3.ncpjn.q13mb]
```

9. This can now be committed and is ready to deploy on the app distribution moon.

## Testing upgrade from old version

You should create a new ship for this i.e. `~nec`

```zsh
./urbit -F nec
```

### Preparing various desks

1. In an old release branch and run:

- `|install our %ballot, =local %ballot-old`
- `|mount %ballot-old`

2. In an old release branch and run:

- `|install our %ballot`
- `|mount %ballot`

3. In an new release branch and run:

- `|install our %ballot, =local %ballot-new`
- `|mount %ballot-new`

You should have three desks:

- `ballot`
- `ballot-old`: clean old version
- `ballot-new`: clean new version

### Updating the version

1. With the old release branch running, make sure you do a few things like create a proposal so there is some state from the old version.
2. Run `|install our %ballot-new, =local %ballot`. This will update from the old version to the new version and you can identify any upgrade errors.

### Reverting to old version

1. Run `|nuke %ballot` to clear out the old state.
2. Run `|uninstall %ballot` (note: also uninstall from app grid if you are testing UI)
3. Run `|install our %ballot-old, =local %ballot`. This should load the old version of the app. You can check using `+vats` or by viewing the old ui.
