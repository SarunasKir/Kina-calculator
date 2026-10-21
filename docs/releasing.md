# Releasing

A release builds two things and attaches them to a GitHub release:

- `KinaCalculator-Setup-<version>.exe`, the Windows installer. It installs for
  the current user without an administrator prompt, adds a Start menu entry,
  and can add a desktop shortcut. Running a newer setup upgrades the install.
  A portable `.zip` of the same app is attached too.
- `KinaCalculator-<version>.apk`, the Android app, signed with the release key.

Both are built by GitHub Actions; nothing needs to be installed on a PC.

## One-time setup: the Android signing key

Android only lets an app update itself when every version is signed with the
same key, so make the key once and keep it safe. If it is lost, phones must
uninstall and reinstall to move to a new key.

1. Create the key (any machine with Java; use your own passwords):

   ```
   keytool -genkeypair -keystore kina-release.jks -storetype PKCS12 \
     -alias kina -keyalg RSA -keysize 2048 -validity 10000
   ```

2. In the repository go to Settings, Secrets and variables, Actions, and add
   these four secrets:

   | Secret | Value |
   | --- | --- |
   | `KINA_KEYSTORE_BASE64` | the key file as base64, from `base64 -w0 kina-release.jks` |
   | `KINA_KEYSTORE_PASSWORD` | the store password you typed |
   | `KINA_KEY_ALIAS` | `kina` |
   | `KINA_KEY_PASSWORD` | the key password you typed |

3. Keep `kina-release.jks` and the passwords somewhere private, such as a
   password manager. Never commit them.

Without these secrets the build still works, but signs with a throwaway key
and prints a warning. Do not publish such an APK.

## Making a release

1. Make sure the latest commit on `main` has a green CI run.
2. Start the release in either of two ways:

   - Push a tag from a clone of the repository:

     ```
     git tag v0.2.0
     git push origin v0.2.0
     ```

   - Or on GitHub open Releases, Draft a new release, type `v0.2.0` in
     "Choose a tag" and pick "Create new tag on publish" with target `main`,
     then Publish. Publishing creates the tag, and the workflow adds the
     installers to that release.

3. The Release workflow builds both files and publishes the release with
   generated notes. The version in the tag becomes the app version, and the
   Android build number is `major * 10000 + minor * 100 + patch`, so it always
   goes up with the version.

Every CI run also builds the installer and the APK as downloadable artifacts
with the `pubspec.yaml` version, so packaging problems show up before a tag.

## Installing

- Windows: run the setup. If Windows SmartScreen warns about an unknown
  publisher, choose More info, then Run anyway; the installer is not code
  signed. The first time you switch the sync hub on, Windows asks to allow
  network access: allow private networks so the phone can reach the PC.
- Android: open the APK on the phone and allow installing from that source
  when asked. Later releases install over the top.
