PDF := ozirus_dilemma.pdf
SRC := src/Ozirus_Dilemma.tex

all: build/$(PDF)

build/$(PDF): $(SRC)
	latexmk -pdf -outdir=build $(SRC)
	@cp build/*.pdf build/$(PDF) 2>/dev/null || true

clean:
	latexmk -C -outdir=build
	rm -rf build

.PHONY: all clean
