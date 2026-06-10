# Changelog

All notable changes to `luanumbers` are documented here. The project follows
[Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.5.0] - 2026-06-10

### Added

- Document-wide automatic rounding from one LuaLaTeX preamble setup.
- Exact decimal-string rounding with multiple rounding modes.
- Integer preservation, configurable zero padding, scientific notation, and
  decimal-comma support.
- Conservative detection and warnings for ambiguous numeric source.
- Default protection for structural commands, generated metadata, TikZ,
  PGFPlots, verbatim-like environments, URLs, and file names.
- `luanumbersexclude` for preserving one selected document object and its label.
- Global command and environment protection APIs.
- Explicit `\LuaNumber` formatting and temporary on/off controls.
- Lua unit tests, LuaLaTeX smoke tests, compatibility examples, and a complete
  user manual.
