# zooper_flutter_core

`zooper_flutter_core` is the shared core package for all Zooper Flutter packages.

It contains the small, stable building blocks that multiple Zooper packages depend on:

- **Interfaces and primitives** that are used throughout the Zooper ecosystem
- **Shared helpers** that are too small to justify their own package
- **Common extensions** to keep code consistent across packages

This package is intentionally kept focused and lightweight so that other packages can depend on it without pulling in unnecessary dependencies.

## Getting started

Add a new line inside your `pubspec.yaml`:

`zooper_flutter_core: <latest>`

## Usage

Import what you need from the package entrypoint:

`import 'package:zooper_flutter_core/zooper_flutter_core.dart';`

### What’s inside

- **Identifiers**
	- `Uuid`: dependency-free UUID generation + parsing/validation (v1–v8)
	- `Ulid`: ULID generation + parsing/validation
- **Extensions**
	- `DateTime`, `Duration`, `String`, `String?`, `double`

If you’re using Zooper packages, you’ll typically only interact with this package indirectly through their shared interfaces and helpers.