#  Make file for Gnonograms
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
PROGRAM = gnonograms

VERSION = 0.9.0
GETTEXT_PACKAGE = $(PROGRAM)
BUILD_ROOT = 1

VALAC = valac
MIN_VALAC_VERSION = 0.7.10
INSTALL_PROGRAM = install
INSTALL_DATA = install -m 644

# defaults that may be overridden by configure.mk
PREFIX=/usr
#SCHEMA_FILE_DIR=/etc/gconf/schemas
BUILD_RELEASE=1

-include configure.mk

VALAFLAGS = -g --enable-checking $(USER_VALAFLAGS)

DEFINES=_PREFIX='"$(PREFIX)"' _VERSION='"$(VERSION)"' GETTEXT_PACKAGE='"$(GETTEXT_PACKAGE)"' _LANG_SUPPORT_DIR='"$(SYSTEM_LANG_DIR)"'

SUPPORTED_LANGUAGES=en_GB ja_JP
LOCAL_LANG_DIR=locale
SYSTEM_LANG_DIR=$(DESTDIR)$(PREFIX)/share/locale

SRC_FILES = \
	Circular_buffer.vala \
	Game_editor.vala \
	Config.vala \
	Gnonogram_cellgrid.vala \
	Gnonogram_controller.vala \
	Gnonogram_filereader.vala \
	Gnonogram_label.vala \
	Gnonogram_labelbox.vala \
	Gnonogram_model.vala \
	Gnonogram_permutor.vala \
	Gnonogram_region.vala \
	Gnonogram_solver.vala \
	Gnonogram_viewer.vala \
	main.vala \
	My2DCellArray.vala \
	Resource.vala \
	utils.vala

RESOURCE_FILES = \
	icons/*.png \
	icons/*.svg \
	games/easy/*.gno \
	games/moderately\ easy/*.gno \
	games/moderately\ hard/*.gno \
	games/hard/*.gno \
	games/very\ hard/*.gno \
	games/almost\ impossible/*.gno \
	html/*.html \
	html/*.png \
	html/media/*.png \
	misc/gnonograms.desktop.head \
	misc/x-gnonogram-puzzle.xml \
	po/gnonograms.pot \
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

EXT_PKGS = \
   gdk-2.0 \
   gtk+-2.0 \
   gio-2.0 \
   glib-2.0 \
   pango \
   cairo \
   gconf-2.0 \

EXT_PKG_VERSIONS = \
   gtk+-2.0 >= 2.20.0 \
	cairo >= 1.8.0 \
	pango >= 1.28.0

PKGS = $(EXT_PKGS) $(LOCAL_PKGS)

ifndef BUILD_DIR
BUILD_DIR=build
endif

DESKTOP_APPLICATION_NAME="Gnonograms"
DESKTOP_APPLICATION_COMMENT="Design and solve Nonogram puzzles"
DESKTOP_APPLICATION_CLASS="Logic game"
TEMPORARY_DESKTOP_FILES = misc/gnonograms.desktop
EXPANDED_PO_FILES = $(foreach po,$(SUPPORTED_LANGUAGES),po/$(po).po)
EXPANDED_SRC_FILES = $(foreach src,$(SRC_FILES),src/$(src))
EXPANDED_C_FILES = $(foreach src,$(SRC_FILES),$(BUILD_DIR)/$(src:.vala=.c))
EXPANDED_SAVE_TEMPS_FILES = $(foreach src,$(SRC_FILES),$(BUILD_DIR)/$(src:.vala=.vala.c))
EXPANDED_OBJ_FILES = $(foreach src,$(SRC_FILES),$(BUILD_DIR)/$(src:.vala=.o))

VALA_STAMP = $(BUILD_DIR)/.stamp
LANG_STAMP = $(LOCAL_LANG_DIR)/.langstamp

DIST_FILES = Makefile configure minver
DIST_FILES+= $(TEXT_FILES) $(EXPANDED_PO_FILES) $(EXPANDED_SRC_FILES)
DIST_FILES+= $(RESOURCE_FILES)

DIST_TAR_GZ = $(PROGRAM)-$(VERSION).tar.gz
ORIG_TAR_GZ = $(PROGRAM)_$(VERSION).orig.tar.gz
DIST_WITH_C_TAR_GZ = $(PROGRAM)-$(VERSION)c.tar.gz

VALA_CFLAGS = `pkg-config --cflags $(EXT_PKGS)` $(foreach hdir,$(HEADER_DIRS),-I$(hdir)) \
	$(foreach def,$(DEFINES),-D$(def))

VALA_LDFLAGS = `pkg-config --libs $(EXT_PKGS)`

# setting CFLAGS in configure.mk overrides build type
ifndef CFLAGS
ifdef BUILD_DEBUG
CFLAGS = -O0 -g -pipe
else
CFLAGS = -O2 -g -pipe -Wall
endif
endif

#-----------------------------------TARGETS----------------------------------------------
all: $(PROGRAM)
###############

$(PROGRAM): $(EXPANDED_OBJ_FILES) $(RESOURCES) $(LANG_STAMP)
############################################################
	$(CC) $(EXPANDED_OBJ_FILES) $(CFLAGS) $(RESOURCES) $(VALA_LDFLAGS) -o $@

$(EXPANDED_OBJ_FILES): %.o: %.c $(CONFIG_IN) Makefile
####################################################
	$(CC) -c $(VALA_CFLAGS) $(CFLAGS) -o $@ $<

# Do not remove hard tab or at symbol; necessary for dependencies to complete.
$(EXPANDED_C_FILES): $(VALA_STAMP)
########################
	@

$(LANG_STAMP): $(EXPANDED_PO_FILES)
#####################################
	$(foreach po,$(SUPPORTED_LANGUAGES), \
		`mkdir -p $(LOCAL_LANG_DIR)/$(po)/LC_MESSAGES ; \
       msgfmt -o $(LOCAL_LANG_DIR)/$(po)/LC_MESSAGES/gnonograms.mo po/$(po).po` \
    )
	touch $(LANG_STAMP)

$(VALA_STAMP): $(EXPANDED_SRC_FILES) $(EXPANDED_VAPI_FILES) $(EXPANDED_SRC_HEADER_FILES) Makefile \
	$(CONFIG_IN)
#####################################################################

ifndef NO_VALA
	@ ./minver `valac --version | awk '{print $$2}'` $(MIN_VALAC_VERSION) || ( echo 'gnonograms requires Vala compiler $(MIN_VALAC_VERSION) or greater.  You are running' `valac --version` '\b.'; exit 1 )

ifndef ASSUME_PKGS
ifdef EXT_PKG_VERSIONS
	pkg-config --print-errors --exists '$(EXT_PKG_VERSIONS)'
else ifdef EXT_PKGS
	pkg-config --print-errors --exists $(EXT_PKGS)
endif
endif

	@ type msgfmt > /dev/null || ( echo 'msgfmt (usually found in the gettext package) is missing and is required to build gnonograms. ' ; exit 1 )
	mkdir -p $(BUILD_DIR)
	$(VALAC) --ccode --directory=$(BUILD_DIR) --basedir=src $(VALAFLAGS) \
	$(foreach pkg,$(PKGS),--pkg=$(pkg)) \
	$(foreach def,$(DEFINES),-X -D$(def)) \
	$(VALA_DEFINES) \
	$(EXPANDED_SRC_FILES)
	touch $@
endif

clean:
####
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
#######
	rm -f $(EXPANDED_C_FILES)
	rm -f $(EXPANDED_SAVE_TEMPS_FILES)
	rm -f $(EXPANDED_OBJ_FILES)
	rm -f $(VALA_STAMP)
	rm -f $(LANG_STAMP)


dist: $(DIST_FILES)
###################
	mkdir -p $(PROGRAM)-$(VERSION)
	cp --parents $(DIST_FILES) $(PROGRAM)-$(VERSION)
	tar --gzip -cvf $(DIST_TAR_GZ) $(PROGRAM)-$(VERSION)
	rm -rf $(PROGRAM)-$(VERSION)

dist_with_c: $(DIST_FILES)
##########################
	mkdir -p $(PROGRAM)-$(VERSION)c
	cp --parents $(DIST_FILES) $(PROGRAM)-$(VERSION)c
	cp --parents $(EXPANDED_C_FILES) $(PROGRAM)-$(VERSION)c
	tar --gzip -cvf $(DIST_WITH_C_TAR_GZ) $(PROGRAM)-$(VERSION)c
	rm -rf $(PROGRAM)-$(VERSION)c

distclean: clean
##########
	rm -f configure.mk

install:
#######
	cp misc/gnonograms.desktop.head misc/gnonograms.desktop
	$(foreach lang,$(SUPPORTED_LANGUAGES), \
		TEXTDOMAINDIR=locale; \
		LANGUAGE=$(lang); \
		echo Name[$(lang)]=`gettext --domain=gnonograms $(DESKTOP_APPLICATION_NAME)` >>  misc/gnonograms.desktop ; \
		echo GenericName[$(lang)]=`gettext --domain=gnonograms $(DESKTOP_APPLICATION_CLASS)` >>  misc/gnonograms.desktop ; \
		echo Comment[$(lang)]=`gettext --domain=gnonograms $(DESKTOP_APPLICATION_COMMENT)` >> misc/gnonograms.desktop;)

	touch $(LANG_STAMP)

	$(INSTALL_PROGRAM) $(PROGRAM) $(DESTDIR)$(PREFIX)/games

	mkdir -p $(DESTDIR)$(PREFIX)/share/gnonograms/icons
	$(INSTALL_DATA) icons/* $(DESTDIR)$(PREFIX)/share/gnonograms/icons

	mkdir -p $(DESTDIR)$(PREFIX)/share/gnonograms/games
	mkdir -p $(DESTDIR)$(PREFIX)/share/gnonograms/games/easy
	$(INSTALL_DATA) games/easy/* $(DESTDIR)$(PREFIX)/share/gnonograms/games/easy
	mkdir -p $(DESTDIR)$(PREFIX)/share/gnonograms/games/moderately\ easy
	$(INSTALL_DATA) games/moderately\ easy/* $(DESTDIR)$(PREFIX)/share/gnonograms/games/moderately\ easy
	mkdir -p $(DESTDIR)$(PREFIX)/share/gnonograms/games/moderately\ hard
	$(INSTALL_DATA) games/moderately\ hard/* $(DESTDIR)$(PREFIX)/share/gnonograms/games/moderately\ hard
	mkdir -p $(DESTDIR)$(PREFIX)/share/gnonograms/games/hard
	$(INSTALL_DATA) games/hard/* $(DESTDIR)$(PREFIX)/share/gnonograms/games/hard
	mkdir -p $(DESTDIR)$(PREFIX)/share/gnonograms/games/very\ hard
	$(INSTALL_DATA) games/very\ hard/* $(DESTDIR)$(PREFIX)/share/gnonograms/games/very\ hard
	mkdir -p $(DESTDIR)$(PREFIX)/share/gnonograms/games/almost\ impossible
	$(INSTALL_DATA) games/almost\ impossible/* $(DESTDIR)$(PREFIX)/share/gnonograms/games/almost\ impossible

	mkdir -p $(DESTDIR)$(PREFIX)/share/gnonograms/html
	mkdir -p $(DESTDIR)$(PREFIX)/share/gnonograms/html/media
	$(INSTALL_DATA) html/*.* $(DESTDIR)$(PREFIX)/share/gnonograms/html
	$(INSTALL_DATA) html/media/*.* $(DESTDIR)$(PREFIX)/share/gnonograms/html/media

	mkdir -p $(DESTDIR)$(PREFIX)/share/icons/hicolor/48x48/apps
	$(INSTALL_DATA) icons/gnonograms48.png $(DESTDIR)$(PREFIX)/share/icons/hicolor/48x48/apps/gnonograms.png

	mkdir -p $(DESTDIR)$(PREFIX)/share/icons/hicolor/48x48/mimetypes
	$(INSTALL_DATA) icons/gnonogram-puzzle.png $(DESTDIR)$(PREFIX)/share/icons/hicolor/48x48/mimetypes/application-x-gnonogram-puzzle.png

	mkdir -p $(DESTDIR)$(PREFIX)/share/icons/hicolor/scalable/apps
	$(INSTALL_DATA) icons/gnonograms.svg $(DESTDIR)$(PREFIX)/share/icons/hicolor/scalable/apps/gnonograms.svg

	$(foreach lang,$(SUPPORTED_LANGUAGES),`mkdir -p $(SYSTEM_LANG_DIR)/$(lang)/LC_MESSAGES ; \
        $(INSTALL_DATA) $(LOCAL_LANG_DIR)/$(lang)/LC_MESSAGES/gnonograms.mo \
            $(SYSTEM_LANG_DIR)/$(lang)/LC_MESSAGES/gnonograms.mo`)

	mkdir -p $(DESTDIR)$(PREFIX)/share/mime/packages
	$(INSTALL_DATA) misc/x-gnonogram-puzzle.xml $(DESTDIR)$(PREFIX)/share/mime/packages

	mkdir -p $(DESTDIR)$(PREFIX)/share/applications
	$(INSTALL_DATA) misc/gnonograms.desktop $(DESTDIR)$(PREFIX)/share/applications/gnonograms-1.desktop

ifndef DISABLE_DESKTOP_UPDATE
	-gtk-update-icon-cache -t -f $(DESTDIR)$(PREFIX)/share/icons/hicolor || :
	-update-mime-database $(DESTDIR)$(PREFIX)/share/mime || :
	-update-desktop-database || :
endif


uninstall:
##########
	rm -f $(DESTDIR)$(PREFIX)/games/$(PROGRAM)
	rm -fr $(DESTDIR)$(PREFIX)/share/gnonograms
	rm -fr $(DESTDIR)$(PREFIX)/share/gnonograms/html/media
	rm -fr $(DESTDIR)$(PREFIX)/share/gnonograms/html

	rm -fr $(DESTDIR)$(PREFIX)/share/icons/hicolor/scalable/apps/gnonograms.png
	rm -fr $(DESTDIR)$(PREFIX)/share/icons/hicolor/48x48/apps/gnonograms.png
	rm -fr $(DESTDIR)$(PREFIX)/share/icons/hicolor/48x48/mimetypes/application-x-gnonogram-puzzle.png

	rm -f $(DESTDIR)$(PREFIX)/share/applications/gnonograms-1.desktop
	rm -f misc/gnonograms.desktop

	rm -f $(DESTDIR)$(PREFIX)/share/mime/packages/x-gnonogram-puzzle.xml

ifndef DISABLE_DESKTOP_UPDATE
	update-mime-database $(DESTDIR)$(PREFIX)/share/mime || :
	update-desktop-database || :
endif

	$(foreach lang,$(SUPPORTED_LANGUAGES),`rm -f $(SYSTEM_LANG_DIR)/$(lang)/LC_MESSAGES/gnonograms.mo`)

