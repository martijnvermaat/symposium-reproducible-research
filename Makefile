# Makefile for LaTeX documents.
#

# LaTeX core binaries.
TEX := latex
BIBTEX := bibtex
GLOSSARY := makeglossaries

# Conversion to other formats.
DVIPS := dvips
PS2PDF := ps2pdf14
LATEX2RTF := latex2rtf
LIBREOFFICE := libreoffice

# Pictures.
DIA := dia
DOT := dot
FIG2DEV := fig2dev
CONVERT := convert
GNUPLOT := gnuplot
FONTSIZE := 20
GUNZIP := gunzip

# Load the configuration file.
-include config.mkc

# Find the input files.
SRC := $(basename $(shell grep -l '\\begin{document}' *.tex))
DIA_PIC := $(basename $(shell ls *.dia 2>/dev/null))
FIG_PIC := $(basename $(shell ls *.fig 2>/dev/null))
GNP := $(basename $(shell ls *.gnp 2>/dev/null))
PIC_EXT := dot gif jpg png ppm svg xcf bmp
PIC := $(foreach I, $(PIC_EXT), $(basename $(shell ls *.$I 2>/dev/null))) $(foreach I, $(PIC_EXT) eps, $(basename $(basename $(shell ls *.$I.gz 2>/dev/null))))

# Output.
PDF := $(addsuffix .pdf, $(SRC))
RTF := $(addsuffix .rtf, $(SRC))
DOC := $(addsuffix .docx, $(SRC))
HDT := $(addsuffix _handout.pdf, $(SRC))
TXT := $(addsuffix .txt, $(SRC))

# Temporary files.
TMP := blg log nav out snm toc dvi aux idx vrb ps glg glo ist
PNG := $(addsuffix .png, $(DIA_PIC))
TNP := $(addsuffix .tnp, $(GNP))
NOT := $(addsuffix _notes.pdf, $(SRC))

# Semi-permanent files.
BIB := $(addsuffix .bbl, $(SRC))
GLS := $(addsuffix .gls, $(GLS))
EPS := $(addsuffix .eps, $(DIA_PIC) $(FIG_PIC) $(GNP) $(PIC))
TEX_T_EXT := pstex pstex_t
TEX_T := $(foreach I, $(TEX_T_EXT), $(addsuffix .$I, $(FIG_PIC)))

# Do not delete the semi-permanent files automatically.
.PRECIOUS: $(BIB) $(GLS) $(EPS) $(TEX_T)

# Disable built-in rules.
.SUFFIXES:

# Targets that are not associated with files.
.PHONY: all rtf doc handout text clean distclean release


# Main targets

all: $(PDF)

rtf: $(RTF)

doc: $(DOC)

handout: $(HDT)

text: $(TXT)

clean:
	rm -f $(foreach I, $(TMP), $(addsuffix .$I, $(SRC))) $(foreach I, $(TMP), $(addsuffix _notes.$I, $(SRC))) $(PNG) $(TNP) $(NOT)

distclean: clean
	rm -f $(PDF) $(RTF) $(DOC) $(HDT) $(TXT) $(BIB) $(EPS) $(TEX_T)

release: all clean


# Picture targets.

%.png: %.dia
	$(DIA) -e $@ -t png-libart $<

%.eps: %.png
	$(CONVERT) $< $@

%.eps: %.dot
	$(DOT) -Teps -o $@ $<

%.eps: %.gif
	$(CONVERT) $< $@

%.eps: %.jpg
	$(CONVERT) $< $@

%.eps: %.ppm
	$(CONVERT) $< $@

%.eps: %.svg
	$(CONVERT) $< $@

%.eps: %.xcf
	$(CONVERT) $< $@

%.eps: %.bmp
	$(CONVERT) $< $@

%.tnp: %.gnp $(DEP)
	echo "set terminal postscript color eps font \"Helvetica,$(FONTSIZE)\"" > $@ ;\
	cat $< >> $@

%.eps: %.tnp
	$(GNUPLOT) < $< > $@

%.eps: %.fig
	$(FIG2DEV) -L eps $< $@

%.pstex: %.fig
	$(FIG2DEV) -L pstex $< $@

%.pstex_t: %.fig %.pstex
	$(FIG2DEV) -L pstex_t -p $(word 2, $^) $< $@


# Compressed files.
# Hmm can probably prevent listing all extensions here with secondary
# expension...

%.eps: %.eps.gz
	$(GUNZIP) -k $<

%.dot: %.dot.gz
	$(GUNZIP) -k $<

%.gif: %.gitf.gz
	$(GUNZIP) -k $<

%.jpg: %.jpg.gz
	$(GUNZIP) -k $<

%.png: %.png.gz
	$(GUNZIP) -k $<
%.ppm: %.ppm.gz
	$(GUNZIP) -k $<

%.svg: %.svg.gz
	$(GUNZIP) -k $<
%.xcf: %.xcf.gz
	$(GUNZIP) -k $<

%.bmp: %.bmp.gz
	$(GUNZIP) -k $<


# BibTeX targets (called recursively).

%.blg: %.aux
	$(BIBTEX) $(basename $^)

%.bbl: %.blg
	@

# Glossary targets (called recursively).

%.glg: %.aux
	$(GLOSSARY) $*

%.glo: %.glg
	@

%.ist: %.glg
	@

%.gls: %.aux %.glg %.glo %.ist
	@

# LaTeX build targets.

%_notes.tex: %.tex
	sed 's/^\\documentclass\[/\\documentclass\[handout, /' $< > $@

%.aux: %.tex $(EPS) $(TEX_T)
	$(TEX) $< ;\
	if (grep -s "LaTeX Warning: Citation" $*.log); then \
	  $(MAKE) $*.bbl ;\
	  $(TEX) $< ;\
	fi ;\
	if (grep -s "No file $*.gls" $*.log); then \
	  $(MAKE) $*.gls ;\
	fi ;\
	while (grep -s "Rerun to get cross-references right." $*.log); do \
	  $(TEX) $< ;\
	done ;\
	while (grep -s "Rerun to get /PageLabels entry." $*.log); do \
	  $(TEX) $< ;\
	done ;\
	while (grep -s "LaTeX Warning: There were undefined references" $*.log); do \
	  $(TEX) $< ;\
	done ;\
	while (grep -s "Package rerunfilecheck Warning: File" $*.log); do \
	  $(TEX) $< ;\
	done

%.log: %.aux
	@

%.dvi: %.aux
	@

%.idx: %.aux
	@

%.nav: %.aux
	@

%.out: %.aux
	@

%.snm: %.aux
	@

%.toc: %.aux
	@

%.vrb: %.aux
	@

%.ps: %.dvi %.log %.aux %.idx %.nav %.out %.snm %.toc %.vrb
	$(DVIPS) $< -o $@


# Output targets.

%.pdf: %.ps
	$(PS2PDF) $^

%.rtf: %.tex %.dvi %.log %.aux %.idx %.nav %.out %.snm %.toc %.vrb
	$(LATEX2RTF) -o $@ $<

%.docx: %.rtf
	$(LIBREOFFICE) --headless --invisible --convert-to docx $< -o $@

%.txt: %.tex
	grep "^%" $< | cut -b 3- > $@

%_handout.pdf: %_notes.pdf
	pdfnup -o $@ --nup 1x4 -q --a4paper --no-landscape --scale 0.9 --delta "0 5mm" --frame true $<
