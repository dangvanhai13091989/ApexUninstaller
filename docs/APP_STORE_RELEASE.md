# Mac App Store release guide

This project intentionally ships two different macOS apps:

| Channel | Scheme | Bundle identifier | App name | Sandbox |
| --- | --- | --- | --- | --- |
| Mac App Store | `ApexUninstaller` | `com.haidv.apexuninstaller` | ApexUninstaller | Enabled |
| GitHub Direct | `ApexUninstaller-Direct` | `com.haidv.apexuninstaller.direct` | ApexUninstaller Direct | Disabled |

Keep the App Store identifier unchanged. App Store Connect identifies the existing app record by its bundle ID, so changing it would create a different Store app instead of an update.

## Before each Store update

1. Work only from the `ApexUninstaller` scheme. Never use `ApexUninstaller-Direct` or `scripts/release-direct.sh` for an App Store upload.
2. Run the standard scheme tests and manually test a signed sandboxed `Release` build. The user must be able to choose `~/Library` through the folder picker and revoke that access without the app failing.
3. Update `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in `project.yml`. The build number must be higher than every build already uploaded for that version.
4. Run XcodeGen after changing `project.yml` so `ApexUninstaller.xcodeproj` matches the source configuration.
5. Check App Privacy answers and the public privacy-policy URL. If clipboard history changes, the policy must continue to say that clipboard data is optional, encrypted locally, retained for 24 hours, and never transmitted.

## Archive and submit

1. Open `ApexUninstaller.xcodeproj` in Xcode.
2. Select the `ApexUninstaller` scheme and the `My Mac` run destination.
3. Choose **Product > Archive**. This scheme archives with `Release`, which uses `ApexUninstaller.entitlements` and enables App Sandbox.
4. In Organizer, select **Validate App** and resolve every validation error.
5. Select **Distribute App > App Store Connect > Upload**. Xcode uses the App Store signing path; do not notarize this archive with the Direct-distribution script.
6. When processing finishes, open the existing app record in App Store Connect, create the next macOS version, select the uploaded build, complete its metadata and App Review notes, then submit it for review.

After Apple approves the first public version, copy its public `https://apps.apple.com/app/id…` URL into the README and website. Do not add an invented or generic App Store link before then.

## Store rules kept by this project

- The App Store build remains sandboxed and uses security-scoped bookmarks for user-selected folders.
- It has no GitHub updater, Sparkle updater, or other alternate update mechanism.
- The external PayPal, GitHub source, and Full Disk Access controls appear only in the Direct edition.
- Clipboard history works in both editions without Full Disk Access, Accessibility, or Input Monitoring. Its user-selectable system hotkey opens one non-activating utility panel, copies a selected item to the pasteboard, and keeps the current input context available so the user can explicitly press Command-V.

## Clipboard History review notes

This feature is intentionally designed to remain compatible with App Sandbox:

- It does not monitor keys or record typing. The global shortcut is registered through the system hotkey API and every selectable shortcut includes Command or Control.
- It does not request Accessibility or Input Monitoring permission.
- It never simulates Command-V or injects input into another application. App Sandbox restricts accessibility APIs and input simulation, and silent auto-paste would also be a poor privacy default.
- The user explicitly enables history; copied text, links, and images up to 8 MB are encrypted locally, retained for at most 24 hours, and can be cleared immediately.

Include these points in the App Review notes whenever Clipboard History is part of a submitted build.

## Licensing checkpoint

The repository is GPL-3.0-or-later. Before selling the Store edition, decide and document a compatible distribution approach—typically a dual license for the App Store binary or a GPL additional permission written by counsel. Do not change the public license or accept third-party contributions under new terms without the copyright holder's approval.
