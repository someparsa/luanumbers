# luanumbers

Document-wide decimal adjustment from a single LuaLaTeX preamble setup.

`luanumbers` automatically rounds eligible decimal literals written directly
in prose and mathematics. Authors do not normally need to wrap each number in
a command or maintain a separate numeric data structure. Changing one preamble
setting can revise the displayed precision throughout the document.

Current release: **0.5.0** (10 June 2026)

## Features

- One-time, document-wide precision and rounding configuration
- Exact decimal-string arithmetic without binary floating-point conversion
- Integers preserved by default, so `2` does not become `2.0`
- Optional zero padding, exponent preservation, and decimal-comma input
- Conservative protection for labels, references, file names, URLs, generated
  LaTeX metadata, and graphics source
- Local exclusion of one selected section, figure, table, or custom object
- Explicit `\LuaNumber{...}` formatting for protected or ambiguous contexts
- Tested integration examples for TikZ, PGFPlots, and Beamer

## Requirements

- LuaLaTeX
- A reasonably complete TeX Live or MiKTeX installation

pdfLaTeX and XeLaTeX are not supported because the package uses LuaTeX input
callbacks.

## Installation

For a single project, place these files beside the main `.tex` document:

```text
luanumbers.sty
luanumbers.lua
```

For a user-wide installation, copy both files into a local TeX tree under a
directory such as `tex/latex/luanumbers/`, then refresh the TeX filename
database if required by the distribution.

## Quick Start

```tex
\documentclass{article}
\usepackage{luanumbers}

\LuaNumbersSetup{
  decimals=1,
  rounding=half-up,
  pad-zeroes=true,
  integers=false,
  warnings=once
}

\begin{document}
Decimal 3.14159 becomes 3.1.
Decimal 3.00 becomes 3.0.
Integer 2 remains 2.
\end{document}
```

Compile with:

```sh
lualatex document.tex
```

## Selected Exclusions

Use `luanumbersexclude` when one particular object and its label must remain
unchanged. Other objects of the same type continue to be processed.

```tex
\begin{luanumbersexclude}
  \begin{figure}
    Raw figure content: 3.14159.
    \caption{Unmodified result 3.14159}
    \label{fig:raw-3.14159}
  \end{figure}
\end{luanumbersexclude}
```

Recurring command or environment types can be protected globally:

```tex
\LuaNumbersProtectCommands{section,caption}
\LuaNumbersProtectEnvironments{mydiagram,mydata}
```

## TikZ and PGFPlots

`tikzpicture`, `pgfpicture`, and `axis` are protected from automatic rewriting
by default. This keeps coordinates, dimensions, styles, and datasets exact.
The explicit formatter remains available for visible labels:

```tex
\begin{tikzpicture}
  \draw (0.00,0.00) rectangle (3.26,1.74);
  \node at (1.63,0.87) {Value: \LuaNumber{3.14159}};
\end{tikzpicture}
```

Here the geometry is unchanged and the node displays `Value: 3.1` under the
one-decimal setup. Use PGFPlots number-format controls for generated tick
labels.

## Documentation

The compiled manual is available as [documentation.pdf](documentation.pdf),
with its source in [doc/luanumbers-doc.tex](doc/luanumbers-doc.tex). It covers
all settings, rounding modes, safeguards, exclusions, compatibility behavior,
limitations, and input/output examples.

## Development

```sh
make check     # build documentation/examples and run all tests
make doc       # build documentation.pdf
make examples  # compile TikZ/PGFPlots and Beamer examples
make test      # run Lua unit tests and the LuaLaTeX smoke test
make dist      # create the versioned release ZIP under dist/
make clean     # remove generated files
```

The repository includes Lua unit tests and compilable integration examples.
GitHub Actions runs `make check` for pushes and pull requests.

## Versioning and Releases

The project follows semantic versioning. The authoritative version is stored
in `VERSION` and must match `luanumbers.sty`, `luanumbers.lua`, the manual, and
the changelog. Release tags use the form `v0.5.0`.

See [CHANGELOG.md](CHANGELOG.md) for release history and
[CONTRIBUTING.md](CONTRIBUTING.md) for contribution and release procedures.

## License

Copyright 2026 Parsa Yazdi. This work is distributed under the LaTeX Project
Public License, version 1.3c or later. See the canonical [LICENSE](LICENSE)
and package-specific [NOTICE](NOTICE).
