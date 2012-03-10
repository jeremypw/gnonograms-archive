#! /bin/bash

LINGUAS=`cat ./supported_languages.txt`

xgettext --add-comments --directory=. --default-domain=gnonograms3 --output=gnonograms3.pot --files-from=./VALAPOTFILES.in --keyword=_ --keyword=N_ --from-code=UTF-8 --c++

xgettext --add-comments --join-existing --directory=. --default-domain=gnonograms3 --output=gnonograms3.pot --from-code=UTF-8 --extract-all --c++ additional_strings

for lingua in $LINGUAS; do intltool-update -x -g gnonograms3 -d $lingua; done;
