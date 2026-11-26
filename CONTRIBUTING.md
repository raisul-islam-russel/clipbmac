# Contributing to ClipBMac

Thanks for helping make ClipBMac better! Every bug report, idea and pull request is appreciated.

## Quick start

```bash
git clone https://github.com/raisul-islam-russel/clipbmac.git
cd clipbmac
bash scripts/build.sh      # builds build/ClipBMac.app and build/ClipBMac.dmg
open build/ClipBMac.app
```

Requirements: macOS 13+, Xcode Command Line Tools. No third-party dependencies.

## Ways to contribute

- **Report a bug** — use the [bug report form](../../issues/new?template=bug_report.yml). Include macOS version, Mac model and steps to reproduce.
- **Suggest a feature** — use the [feature request form](../../issues/new?template=feature_request.yml).
- **Send a pull request** — see below.

## Pull request guidelines

1. Open an issue first for anything bigger than a small fix, so we can agree on the approach.
2. Keep the app small and dependency-free. New features should not add network access.
3. Follow the existing code style (Swift, 4-space indent, short functions, `// MARK:` sections).
4. Make sure `bash scripts/build.sh` succeeds and test the feature by hand (hotkey, search, paste, pin, delete).
5. Update `README.md` and `CHANGELOG.md` when behaviour changes.
6. Fill in the pull request template.

## Privacy rules

ClipBMac handles clipboard contents, which can be sensitive. Contributions must not log, transmit or otherwise leak clipboard data.

## Code of Conduct

By participating you agree to the [Code of Conduct](CODE_OF_CONDUCT.md).
