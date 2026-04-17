#!/bin/zsh

ROOT=$(git rev-parse --show-toplevel)
workdir="$(realpath $ROOT/Diff)"
cd "$workdir"

## Command used to generate diff between current version and pre-review version
# This did not work as expected: when the paragraph with changes spanned two pages, it often output the incorrect one. For instance, let's say page N ends in the middle of a paragraph, which continues at the beginning of page N+1. The change is near the end of the paragraph (i.e. on page N+1), but the ONLYCHANGEDPAGE subtype excludes page N+1 and outputs page N.
#git latexdiff --main dissertation.tex --verbose --quiet --latexmk --no-cleanup --math-markup=3 --type=CULINECHBAR --driver=xetex --subtype=ONLYCHANGEDPAGE --graphics-markup=0 pre-review

# The ZLABEL subtype tags each changed page in the aux file. The preamble extension from latexdiff contains instructions on how to use the aux file to extract only the changed pages from the compiled PDF.

echo "Calling git-latexdiff with tmpdirprefix=$workdir. Numerical suffix of tmpdir generated will be placed in $workdir/tmpsuffix"

git latexdiff --whole-tree --main dissertation.tex --verbose --quiet --latexmk --tmpdirprefix "$workdir" --filter 'echo -n $$ >"$tmpdir/../tmpsuffix"' --no-cleanup --math-markup=3 --type=CULINECHBAR --driver=xetex --subtype=ZLABEL --graphics-markup=0 "$1"

echo "Done."
echo "Moving tmp files from "$workdir"/git-latexdiff.$(cat "$workdir"/tmpsuffix) to "$workdir""
mv "$workdir/git-latexdiff.$(cat "$workdir"/tmpsuffix)/*" "$workdir"

"Removing git-latexdiff.$(cat "$workdir"/tmpsuffix)..."
rm -r "$workdir"/git-latexdiff.$(cat $workdir/tmpsuffix)

echo "Done."

## Script for extracting only changed pages

pdftk dissertation.pdf cat $(perl -lne 'if (m/\\zref\@newlabel{DIFchgb(\d*)}{.*\\abspage{(\d*)}}/ ) { $start{$1}=$2; print $2 } if (m/\\zref\@newlabel{DIFchge(\d*)}{.*\\abspage{(\d*)}}/) {if (defined($start{$1})) {for ($j=$start{$1}; $j<=$2; $j++) {print "$j";} } else {print "$2" } }' "$workdir/new/dissertation.aux" | uniq | tr \\n ' ') output dissertation-onlychanges.pdf
