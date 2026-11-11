# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.0] - 2026-11-06

### Added

- Client identifies itself with its name and version; optional `appName` argument.

## [0.3.0] - 2026-03-13

### Added

- Country-specific phone validation.
- Production OTP example with a storage adapter.
- App Attest and token authentication helpers.
- Vapor and Hummingbird examples.
- CI, dependency and code analysis workflows.

### Changed

- Cross-platform improvements for Linux.

## [0.1.0] - 2026-03-05

### Added

- Initial release of the kwtSMS Swift client library.
- Full API coverage: send, balance, verify, validate, sender IDs, coverage, status, delivery reports.
- Auto-batching for large lists and automatic retry when the queue is full.
- Phone number and message cleaning utilities.
- All kwtSMS error codes mapped to clear action messages.
- `.env` loading and JSONL logging.
- Zero external dependencies; iOS 15+, macOS 12+, tvOS 15+, watchOS 8+ and Linux.
