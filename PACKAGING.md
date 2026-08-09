# Packaging Ramakien Puzzle Journey

The game can be downloaded on Windows, macOS, and 64-bit Linux.

## Create packages locally

Install Godot 4.7 and its matching export templates, then run:

```sh
./scripts/package_all.sh
```

The finished archives are written to `dist/`.

## Create downloadable packages on GitHub

Open **Actions → Package game → Run workflow**. The three archives will be
available as a workflow artifact when the build completes.

To publish the archives on the repository's Releases page, push a version tag:

```sh
git tag v1.0.0
git push origin v1.0.0
```

The macOS package is unsigned. Players may need to control-click the app and
choose **Open** the first time. Public distribution without that warning requires
an Apple Developer certificate and notarization.

## Add downloads to a website

After publishing the first tagged release, copy the contents of
`docs/download-buttons.html` into the website. Its buttons use GitHub's permanent
`releases/latest/download` addresses, so no website changes are needed for future
versions. The GitHub repository must be public for visitors to download without
signing in.
