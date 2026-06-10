VERSION := $(shell cat VERSION)
DIST_DIR := dist/luanumbers-$(VERSION)
DIST_FILES := README.md LICENSE CHANGELOG.md CONTRIBUTING.md CITATION.cff \
	VERSION Makefile documentation.pdf luanumbers.sty luanumbers.lua

.PHONY: all check version-check doc examples test dist clean

all: check

check: version-check doc examples test

version-check:
	@grep -Fq 'v$(VERSION) ' luanumbers.sty
	@grep -Fq 'version = "$(VERSION)"' luanumbers.lua
	@grep -Fq 'Version $(VERSION),' doc/luanumbers-doc.tex
	@grep -Fq 'Current release: **$(VERSION)**' README.md
	@printf 'Version metadata is consistent: %s\n' '$(VERSION)'

doc:
	latexmk -lualatex -interaction=nonstopmode -halt-on-error doc/luanumbers-doc.tex
	cp luanumbers-doc.pdf documentation.pdf

examples:
	latexmk -lualatex -interaction=nonstopmode -halt-on-error examples/tikz-pgfplots.tex
	latexmk -lualatex -interaction=nonstopmode -halt-on-error examples/beamer.tex

test:
	texlua tests/unit.lua
	latexmk -lualatex -interaction=nonstopmode -halt-on-error tests/smoke.tex

dist: check
	rm -rf $(DIST_DIR)
	mkdir -p $(DIST_DIR)
	cp $(DIST_FILES) $(DIST_DIR)/
	cp -R doc examples tests $(DIST_DIR)/
	cd dist && zip -qr luanumbers-$(VERSION).zip luanumbers-$(VERSION)
	rm -rf $(DIST_DIR)
	@printf 'Created dist/luanumbers-%s.zip\n' '$(VERSION)'

clean:
	latexmk -C doc/luanumbers-doc.tex
	latexmk -C examples/tikz-pgfplots.tex
	latexmk -C examples/beamer.tex
	latexmk -C tests/smoke.tex
	rm -f luanumbers-doc.pdf beamer.pdf tikz-pgfplots.pdf smoke.pdf
	rm -rf dist
