# Security Policy

ClipBMac processes clipboard contents locally and never makes network connections. We still take security and privacy issues seriously.

## Supported versions

| Version | Supported |
| --- | --- |
| Latest release | Yes |
| Older releases | No |

## Reporting a vulnerability

Please **do not open a public issue** for security problems.

Use GitHub's **private vulnerability reporting**: go to the repository's **Security** tab → **Report a vulnerability**. Include steps to reproduce and the potential impact. You will get a response as soon as possible.

## Scope notes

- Clipboard history is stored unencrypted in `~/Library/Application Support/ClipBMac/`. This is a known limitation, documented in the README, and encryption is on the roadmap.
- The Accessibility permission is used only to simulate `⌘V`.
