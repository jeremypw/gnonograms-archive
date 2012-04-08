#  Make file for gnonograms3
#  Copyright (C) 2010-2011  Jeremy Wootten
#  based on the LGPL work of the Yorba Foundation 2009
#
#	This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License along
#    with this program; if not, write to the Free Software Foundation, Inc.,
#    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
# *
# *  Author:
# * 	Jeremy Wootten <jeremwootten@gmail.com>
PROGRAM=gnonograms3

VERSION=0.9.8
GETTEXT_PACKAGE=$(PROGRAM)
BUILD_ROOT=1

VALAC=valac
MIN_VALAC_VERSION = 0.12.0
INSTALL_PROGRAM = install
INSTALL_DATA = install -m 644

SUPPORTED_LANGUAGES=en_GB ja_JP de es
LOCAL_LANG_DIR=locale
SYSTEM_LANG_DIR=$(DESTDIR)$(PREFIX)/share/locale

# defaults that may be overridden by configure.mk
PREFIX=/usr
BUILD_RELEASE=1

-include configure.mk

# VALAFLAGS = -g --enable-checking $(USER_VALAFLAGS)
VALAFLAGS = $(USER_VALAFLAGS)

DEFINES=_PREFIX='"$(PREFIX)"' _VERSION='"$(VERSION)"' GETTEXT_PACKAGE='"$(GETTEXT_PACKAGE)"' _LANG_SUPPORT_DIR='"$(SYSTEM_LANG_DIR)"'

ifndef DISABLE_GNOME_DOC_INSTALL
	DEFINES+=_GNOME_DOC=1
else
	DEFINES+=_GNOME_DOC=0
endif

SRC_FILES = Gnonogram_cellgrid.vala \
	Game_editor.vala \
	Circular_buffer.vala \
	Gnonogram_controller.vala \
	Gnonogram_filereader.vala \
	Gnonogram_label.vala \
	Gnonogram_labelbox.vala \
	Gnonogram_model.vala \
	Gnonogram_permutor.vala \
	Gnonogram_region.vala \
	Gnonogram_solver.vala \
	Gnonogram_viewer.vala \
	img2gno.vala \
	main.vala \
	My2DCellArray.vala \
	Resource.vala \
	utils.vala

	SRC_FILES+= Gnonogram_config.vala
	SRC_FILES+= Gnonogram_conf_client.vala


RESOURCE_FILES = \
	icons/*.png \
	icons/*.svg \
	icons/*.xpm \
	games/*/*.gno \
	html/*.* \
	html/figures/*.* \
	help/C/*.* \
	help/C/figures/*.* \
	misc/gnonograms3.desktop.head \
	misc/x-gnonogram-puzzle.xml \
	po/gnonograms3.pot \
	po/additional_strings \
 	po/extract-strings.sh \
 	po/README \
 	po/supported_languages.txt \
 	po/VALAPOTFILES.in

TEXT_FILES = \
	AUTHORS \
	COPYING \
	INSTALL \
	MAINTAINERS \
	NEWS \
	README \
	THANKS

EXT_PKGS = gtk+-3.0
EXT_PKG_VERSIONS = gtk+-3.0 >= 3.0.0

PKGS = $(EXT_PKGS) $(LOCAL_PKGS)

ifndef BUILD_DIR
BUILD_DIR=build
endif

DESKTOP_APPLICATION_NAME="gnonograms3"
DESKTOP_APPLICATION_COMMENT="Design and solve Nonogram puzzles"
DESKTOP_APPLICATION_CLASS="Logic game"
TEMPORARY_DESKTOP_FILES = misc/gnonograms3.desktop
EXPANDED_PO_FILES = $(foreach po,$(SUPPORTED_LANGUAGES),po/$(po).po)
EXPANDED_SRC_FILES = $(foreach src,$(SRC_FILES),src/$(src))
EXPANDED_C_FILES = $(foreach src,$(SRC_FILES),$(BUILD_DIR)/$(src:.vala=.c))
EXPANDED_SAVE_TEMPS_FILES = $(foreach src,$(SRC_FILES),$(BUILD_DIR)/$(src:.vala=.vala.c))
EXPANDED_OBJ_FILES = $(foreach src,$(SRC_FILES),$(BUILD_DIR)/$(src:.vala=.o))

VALA_STAMP = $(BUILD_DIR)/.stamp
LANG_STAMP = $(LOCAL_LANG_DIR)/.langstamp

DIST_FILES = Makefile configure minver
DIST_FILES+= $(TEXT_FILES) $(EXPANDED_PO_FILES)
DIST_FILES+= $(EXPANDED_SRC_FILES)
DIST_FILES+= $(RESOURCE_FILES)

BIN_FILES = gnonograms3
BIN_FILES+= html/*.*
BIN_FILES+= html/figures/*.*
BIN_FILES+= icons/*.*
BIN_FILES+= locale/*/*/*.*
BIN_FILES+= games/*/*.*
BIN_FILES+= $(TEXT_FILES)

DIST_TAR_GZ = $(PROGRAM)-$(VERSION).tar.gz
BIN_TAR_GZ = $(PROGRAM)-$(VERSION)-bin.tar.gz
ORIG_TAR_GZ = $(PROGRAM)_$(VERSION).orig.tar.gz
DIST_WITH_C_TAR_GZ = $(PROGRAM)-$(VERSION)c.tar.gz

VALA_CFLAGS = `pkg-config --cflags $(EXT_PKGS)` $(foreach hdir,$(HEADER_DIRS),-I$(hdir)) \
	$(foreach def,$(DEFINES),-D$(def))

VALA_LDFLAGS = `pkg-config --libs $(EXT_PKGS)`

# setting CFLAGS in configure.mk overrides build type
ifndef CFLAGS
ifdef BUILD_DEBUG
CFLAGS = -O0 -g -pipe -Wall
else
CFLAGS = -O2 -pipe -Wl,--as-needed
endif
endif
CFLAGS+="-DGTK_DISABLE_SINGLE_INCLUDES"
CFLAGS+="-DGDK_DISABLE_DEPRECATED -DGTK_DISABLE_DEPRECATED"

#-----------------------------------TARGETS----------------------------------------------
all: $(PROGRAM)
###############

$(PROGRAM): $(EXPANDED_OBJ_FILES) $(RESOURCES) $(LANG_STAMP)
############################################################
	$(CC) $(EXPANDED_OBJ_FILES) $(CFLAGS) $(RESOURCES) $(VALA_LDFLAGS) -o $@

$(EXPANDED_OBJ_FILES): %.o: %.c $(CONFIG_IN) Makefile
#####################################################
	$(CC) -c $(VALA_CFLAGS) $(CFLAGS) -o $@ $<

# Do not remove hard tab or at symbol; necessary for dependencies to complete.
$(EXPANDED_C_FILES): $(VALA_STAMP)
###################################
	@

$(LANG_STAMP): $(EXPANDED_PO_FILES)
#####################################
	$(foreach po,$(SUPPORTED_LANGUAGES), \
		`mkdir -p $(LOCAL_LANG_DIR)/$(po)/LC_MESSAGES ; \
       msgfmt -o $(LOCAL_LANG_DIR)/$(po)/LC_MESSAGES/gnonograms3.mo po/$(po).po` \
    )
	touch $(LANG_STAMP)

$(VALA_STAMP): $(EXPANDED_SRC_FILES) $(EXPANDED_VAPI_FILES) $(EXPANDED_SRC_HEADER_FILES) Makefile \
	$(CONFIG_IN)
#####################################################################

	@ ./minver `valac --version | awk '{print $$2}'` $(MIN_VALAC_VERSION) || ( echo 'gnonograms3 requires Vala compiler $(MIN_VALAC_VERSION) or greater.  You are running' `valac --version` '\b.'; exit 1 )

ifndef ASSUME_PKGS
ifdef EXT_PKG_VERSIONS
	pkg-config --print-errors --exists '$(EXT_PKG_VERSIONS)'
else ifdef EXT_PKGS
	pkg-config --print-errors --exists $(EXT_PKGS)
endif
endif

	@ type msgfmt > /dev/null || ( echo 'msgfmt (usually found in the gettext package) is missing and is required to build gnonograms3. ' ; exit 1 )

	mkdir -p $(BUILD_DIR)
	$(VALAC) --ccode --directory=$(BUILD_DIR) --basedir=src $(VALAFLAGS) \
	$(foreach pkg,$(PKGS),--pkg=$(pkg)) \
	$(foreach def,$(DEFINES),-X -D$(def)) \
	$(EXPANDED_SRC_FILES)
	touch $@

clean:
######
	rm -f $(EXPANDED_C_FILES)
	rm -f $(EXPANDED_SAVE_TEMPS_FILES)
	rm -f $(EXPANDED_OBJ_FILES)
	rm -f $(VALA_STAMP)
	rm -rf $(PROGRAM)-$(VERSION)
	rm -f $(PROGRAM)
	rm -rf $(LOCAL_LANG_DIR)
	rm -f $(LANG_STAMP)
	rm -f $(TEMPORARY_DESKTOP_FILES)

cleantemps:
###########
	rm -f $(EXPANDED_C_FILES)
	rm -f $(EXPANDED_SAVE_TEMPS_FILES)
	rm -f $(EXPANDED_OBJ_FILES)
	rm -f $(VALA_STAMP)
	rm -f $(LANG_STAMP)

dist: $(PROGRAM) $(DIST_FILES)
##############################
	mkdir -p $(PROGRAM)-$(VERSION)
	cp --parents $(DIST_FILES) $(PROGRAM)-$(VERSION)
	rm -f $(DIST_TAR_GZ)
	tar --gzip -cvf $(DIST_TAR_GZ) $(PROGRAM)-$(VERSION)
	rm -rf $(PROGRAM)-$(VERSION)

bin: $(PROGRAM) $(BIN_FILES)
############################
	rm -f $(BIN_TAR_GZ)
	mkdir -p $(PROGRAM)-$(VERSION)-bin
	cp --parents $(BIN_FILES) $(PROGRAM)-$(VERSION)-bin
	tar --gzip -cvf $(BIN_TAR_GZ) $(PROGRAM)-$(VERSION)-bin
	rm -rf $(PROGRAM)-$(VERSION)-bin

distclean: clean
##########
	rm -f configure.mk

install: $(PROGRAM)
###################
	cp misc/gnonograms3.desktop.head misc/gnonograms3.desktop
	$(foreach lang,$(SUPPORTED_LANGUAGES), \
		echo Name[$(lang)]=`TEXTDOMAINDIR=locale LANGUAGE=$(lang) gettext --domain=gnonograms3 $(DESKTOP_APPLICATION_NAME)` >>  misc/gnonograms3.desktop ; \
		echo GenericName[$(lang)]=`TEXTDOMAINDIR=locale LANGUAGE=$(lang) gettext --domain=gnonograms3 $(DESKTOP_APPLICATION_CLASS)` >>  misc/gnonograms3.desktop ; \
		echo Comment[$(lang)]=`TEXTDOMAINDIR=locale LANGUAGE=$(lang) gettext --domain=gnonograms3 $(DESKTOP_APPLICATION_COMMENT)` >> misc/gnonograms3.desktop;)

	touch $(LANG_STAMP)

	mkdir -p $(DESTDIR)$(PREFIX)/games
	$(INSTALL_PROGRAM) $(PROGRAM) $(DESTDIR)$(PREFIX)/games

	mkdir -p $(DESTDIR)$(PREFIX)/share/gnonograms3/icons
	$(INSTALL_DATA) icons/* $(DESTDIR)$(PREFIX)/share/gnonograms3/icons

	mkdir -p $(DESTDIR)$(PREFIX)/share/gnonograms3/games
	mkdir -p $(DESTDIR)$(PREFIX)/share/gnonograms3/games/easy
	$(INSTALL_DATA) games/easy/* $(DESTDIR)$(PREFIX)/share/gnonograms3/games/easy
	mkdir -p $(DESTDIR)$(PREFIX)/share/gnonograms3/games/moderately\ easy
	$(INSTALL_DATA) games/moderately\ easy/* $(DESTDIR)$(PREFIX)/share/gnonograms3/games/moderately\ easy
	mkdir -p $(DESTDIR)$(PREFIX)/share/gnonograms3/games/hard
	$(INSTALL_DATA) games/hard/* $(DESTDIR)$(PREFIX)/share/gnonograms3/games/hard
	mkdir -p $(DESTDIR)$(PREFIX)/share/gnonograms3/games/very\ hard
	$(INSTALL_DATA) games/very\ hard/* $(DESTDIR)$(PREFIX)/share/gnonograms3/games/very\ hard

	mkdir -p $(DESTDIR)$(PREFIX)/share/icons/hicolor/48x48/apps
	$(INSTALL_DATA) icons/gnonograms3-48.png $(DESTDIR)$(PREFIX)/share/icons/hicolor/48x48/apps/gnonograms3.png

	mkdir -p $(DESTDIR)$(PREFIX)/share/icons/hicolor/48x48/mimetypes
	$(INSTALL_DATA) icons/gnonogram-puzzle.png $(DESTDIR)$(PREFIX)/share/icons/hicolor/48x48/mimetypes/application-x-gnonogram-puzzle.png

	mkdir -p $(DESTDIR)$(PREFIX)/share/icons/hicolor/scalable/apps
	$(INSTALL_DATA) icons/gnonograms3.svg $(DESTDIR)$(PREFIX)/share/icons/hicolor/scalable/apps/gnonograms3.svg

	mkdir -p $(DESTDIR)$(PREFIX)/share/pixmaps
	$(INSTALL_DATA) icons/gnonograms3-32.xpm $(DESTDIR)$(PREFIX)/share/pixmaps/gnonograms3.xpm

	$(foreach lang,$(SUPPORTED_LANGUAGES),`mkdir -p $(SYSTEM_LANG_DIR)/$(lang)/LC_MESSAGES ; \
        $(INSTALL_DATA) $(LOCAL_LANG_DIR)/$(lang)/LC_MESSAGES/gnonograms3.mo \
            $(SYSTEM_LANG_DIR)/$(lang)/LC_MESSAGES/gnonograms3.mo`)

	mkdir -p $(DESTDIR)$(PREFIX)/share/mime/packages
	$(INSTALL_DATA) misc/x-gnonogram-puzzle.xml $(DESTDIR)$(PREFIX)/share/mime/packages

	mkdir -p $(DESTDIR)$(PREFIX)/share/applications
	$(INSTALL_DATA) misc/gnonograms3.desktop $(DESTDIR)$(PREFIX)/share/applications/gnonograms3.desktop

ifndef DISABLE_DESKTOP_UPDATE
	-gtk-update-icon-cache -t -f $(DESTDIR)$(PREFIX)/share/icons/hicolor || :
	-update-mime-database $(DESTDIR)$(PREFIX)/share/mime || :
	-update-desktop-database || :
endif

	mkdir -p $(DESTDIR)$(PREFIX)/share/gnonograms3/html
	mkdir -p $(DESTDIR)$(PREFIX)/share/gnonograms3/html/figures
	$(INSTALL_DATA) html/*.* $(DESTDIR)$(PREFIX)/share/gnonograms3/html
	$(INSTALL_DATA) html/figures/*.* $(DESTDIR)$(PREFIX)/share/gnonograms3/html/figures

ifndef DISABLE_GNOME_DOC_INSTALL
	mkdir -p $(DESTDIR)$(PREFIX)/share/gnome/help/gnonograms3/C
	$(INSTALL_DATA) help/C/*.page $(DESTDIR)$(PREFIX)/share/gnome/help/gnonograms3/C
	mkdir -p $(DESTDIR)$(PREFIX)/share/gnome/help/gnonograms3/C/figures
	$(INSTALL_DATA) help/C/figures/*.png $(DESTDIR)$(PREFIX)/share/gnome/help/gnonograms3/C/figures
endif

uninstall:
##########
	rm -f $(DESTDIR)$(PREFIX)/games/$(PROGRAM)
	rm -fr $(DESTDIR)$(PREFIX)/share/gnonograms3

	rm -fr $(DESTDIR)$(PREFIX)/share/icons/hicolor/scalable/apps/gnonograms.png
	rm -fr $(DESTDIR)$(PREFIX)/share/icons/hicolor/48x48/apps/gnonograms.png
	rm -fr $(DESTDIR)$(PREFIX)/share/icons/hicolor/48x48/mimetypes/application-x-gnonogram-puzzle.png

	rm -f $(DESTDIR)$(PREFIX)/share/applications/gnonograms3.desktop
	rm -f misc/gnonograms3.desktop

	rm -f $(DESTDIR)$(PREFIX)/share/mime/packages/x-gnonogram-puzzle.xml

ifndef DISABLE_DESKTOP_UPDATE
	update-mime-database $(DESTDIR)$(PREFIX)/share/mime || :
	update-desktop-database || :
endif
ifndef DISABLE_GNOME_DOC_INSTALL
	rm -rf $(DESTDIR)$(PREFIX)/share/gnome/help/gnonograms3
endif

	$(foreach lang,$(SUPPORTED_LANGUAGES),`rm -f $(SYSTEM_LANG_DIR)/$(lang)/LC_MESSAGES/gnonograms3.mo`)

