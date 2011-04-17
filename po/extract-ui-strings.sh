#! /bin/bash

#UIFILES=

LINGUAS="en_GB ja_JP"

#for uifile in $UIFILES; do intltool-extract --local --type="gettext/glade" $uifile; done;

xgettext --add-comments --directory=. --default-domain=gnonograms --output=gnonograms.pot --files-from=./VALAPOTFILES.in --keyword=_ --keyword=N_ --from-code=UTF-8

for lingua in $LINGUAS; do intltool-update -x -g gnonograms -d $lingua; done;
