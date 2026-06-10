# Contributing

Contributions should preserve the package's conservative approach: automatic
formatting must not silently alter structural or ambiguous LaTeX source.

## Development Setup

Install a TeX distribution containing LuaLaTeX, `latexmk`, TikZ, PGFPlots,
Beamer, `listings`, and `tcolorbox`. Then run:

```sh
make check
```

Changes to parsing or rounding behavior should include focused assertions in
`tests/unit.lua`. Changes affecting LaTeX integration should also update
`tests/smoke.tex` or the relevant example.

## Pull Requests

- Keep changes focused and explain user-visible behavior.
- Add or update tests for behavioral changes.
- Update the manual and README when public commands or defaults change.
- Run `make check` before submitting.
- Do not commit temporary TeX build files.

## Release Procedure

1. Choose a semantic version and update `VERSION`.
2. Match the version in `luanumbers.sty`, `luanumbers.lua`, and the manual.
3. Move changelog entries from `Unreleased` into the dated release section.
4. Run `make clean && make check`.
5. Run `make dist` and inspect the generated ZIP.
6. Commit the release, create an annotated tag such as `v0.5.0`, and publish
   the ZIP and `documentation.pdf` as GitHub release assets.
