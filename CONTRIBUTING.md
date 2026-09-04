# Contributing

Thank you for helping improve ApexUninstaller.

## Before opening a pull request

1. Open an issue for behavior changes that affect scanning or cleanup rules.
2. Generate the project with `xcodegen generate` after changing `project.yml`.
3. Run both the Direct and App Store test configurations.
4. Add tests for path matching, removal rules and regressions.
5. Keep cleanup operations recoverable and never bypass `RemovalSafetyPolicy`.

## Development rules

- Do not add telemetry, advertising or remote file uploads.
- Do not add shell commands that permanently delete files.
- Do not request administrator privileges for the whole application.
- New cleanup candidates must be visible to the user before removal.
- Items with ambiguous ownership must not be selected by default.
- Do not commit signing certificates, notarization credentials or Apple API keys.

## License

Contributions are accepted under GPL-3.0-or-later. Contributions do not grant rights to the ApexUninstaller trademarks or brand assets.
