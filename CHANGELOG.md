# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-10

### Changed

- Moved implementation libraries under `lib/src/`; import via `package:zooper_flutter_core/zooper_flutter_core.dart`

### Added

- Unit tests for extension methods
- GitHub Actions PR workflow (format, analyze, test)
- PR now fails on analyzer infos/warnings (strict lint cleanliness)
- Dependency-free UUID generation/validation (v1–v8)
- ULID data type

### Removed

- `Guid` and `GuidConverter` (use UUID strings / `Uuid` helpers instead)
- `uuid` and `validators` dependencies

## [0.0.7]

### Added

- Small helper property to `StringExtensions`

## [0.0.6]

### Fixed

- Nullable GUIDs not being serialized correctly

## [0.0.5]

### Added

- JSON converter for GUID

## [0.0.4]

### Added

- GUID data type

## [0.0.3]

### Changed

- Moved code into the Zooper GitHub organization

## [0.0.2]

### Changed

- Updated package descriptions and README

## [0.0.1]

### Added

- Basic extension methods

