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
