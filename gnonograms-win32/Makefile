#  Make file for Gnonograms-win32
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

# Intended for cross-compilation on Linux using mingw32
# Must add [location of mingw root directory]/usr/bin to PATH
# Must add environment variable PKG_CONFIG_PATH_i686_pc_mingw32 = [location of mingw root directory]/usr/i686-pc-mingw32/lib/pkg-config
# Run make from terminal, not within IDE.


PROGRAM=gnonograms-win32
CC=i686-w64-mingw32-gcc
LD=i686-w64-mingw32-ld
AR=i686-w64-mingw32-ar
PKG_CONFIG_PATH=/usr/i686-pc-mingw32/lib/pkgconfig
LD_LIBRARY_PATH=/usr/i686-pc-mingw32/lib


VERSION=0.9.9-beta
GETTEXT_PACKAGE=$(PROGRAM)
BUILD_ROOT=1

VALAC=valac
MIN_VALAC_VERSION = 0.16.0
INSTALL_PROGRAM = install
INSTALL_DATA = install -m 644

#SUPPORTED_LANGUAGES=en_GB ja_JP de
#LOCAL_LANG_DIR=locale
#SYSTEM_LANG_DIR=$(DESTDIR)$(PREFIX)/share/locale
TARGET=mingw32

# defaults that may be overridden by configure.mk
PREFIX=/mingw/usr
BUILD_RELEASE=1

-include configure.mk

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
	Range.vala \
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
	html/figures/*.*

TEXT_FILES = \
	AUTHORS \
	COPYING \
	INSTALL \
	MAINTAINERS \
	NEWS \
	README \
	THANKS

EXT_PKGS = gtk+-2.0
EXT_PKG_VERSIONS = gtk+-2.0 >= 2.24.0

PKGS = $(EXT_PKGS) $(LOCAL_PKGS)

ifndef BUILD_DIR
BUILD_DIR=build
endif

#EXPANDED_PO_FILES = $(foreach po,$(SUPPORTED_LANGUAGES),po/$(po).po)
EXPANDED_SRC_FILES = $(foreach src,$(SRC_FILES),src/$(src))
EXPANDED_C_FILES = $(foreach src,$(SRC_FILES),$(BUILD_DIR)/$(src:.vala=.c))
EXPANDED_SAVE_TEMPS_FILES = $(foreach src,$(SRC_FILES),$(BUILD_DIR)/$(src:.vala=.vala.c))
EXPANDED_OBJ_FILES = $(foreach src,$(SRC_FILES),$(BUILD_DIR)/$(src:.vala=.o))

VALA_STAMP = $(BUILD_DIR)/.stamp
#LANG_STAMP = $(LOCAL_LANG_DIR)/.langstamp

DIST_FILES = Makefile configure minver
DIST_FILES+= $(TEXT_FILES) $(EXPANDED_PO_FILES)
DIST_FILES+= $(EXPANDED_SRC_FILES)
DIST_FILES+= $(RESOURCE_FILES)
DIST_FILES+= $(PROGRAM).exe

DIST_ZIP = $(PROGRAM)-$(VERSION).zip

# VALAFLAGS = -g --enable-checking $(USER_VALAFLAGS)
VALAFLAGS =  $(USER_VALAFLAGS)

#INCLUDE_ROOT=/usr/i686-pc-mingw32/
INCLUDE_ROOT=/usr/

#	$(INCLUDE_ROOT)lib/i386-linux-gnu/gtk-2.0/include \
#	$(INCLUDE_ROOT)lib/i386-linux-gnu/glib-2.0/include \
#	$(INCLUDE_ROOT)lib/i386-linux-gnu/bits \
#	$(INCLUDE_ROOT)lib/i386-linux-gnu \


HEADER_DIRS = \
	$(INCLUDE_ROOT)lib/i386-linux-gnu/glib-2.0/include \
	$(INCLUDE_ROOT)include/i386-linux-gnu \
	$(INCLUDE_ROOT)include/gtk-2.0 \
	$(INCLUDE_ROOT)include/gtk-2.0/gdk \
	$(INCLUDE_ROOT)include/atk-1.0 \
	$(INCLUDE_ROOT)include/cairo \
	$(INCLUDE_ROOT)include/gdk-pixbuf-2.0 \
	$(INCLUDE_ROOT)include/pango-1.0 \
	$(INCLUDE_ROOT)include/gio-unix-2.0/ \
	$(INCLUDE_ROOT)include/glib-2.0 \
	$(INCLUDE_ROOT)include/pixman-1 \
	$(INCLUDE_ROOT)include/freetype2 \
	$(INCLUDE_ROOT)include/libpng12 \
	$(INCLUDE_ROOT)include \

DEFINES= \
	_PREFIX='"$(PREFIX)"' \
	_VERSION='"$(VERSION)"' \
	GETTEXT_PACKAGE='"$(GETTEXT_PACKAGE)"' \
	_OS='"$(TARGET)"' \
	_GNOME_DOC='0'
#	_LANG_SUPPORT_DIR='"$(SYSTEM_LANG_DIR)"' \

VALA_CFLAGS = \
		$(foreach hdir,$(HEADER_DIRS),-I$(hdir)) \
		$(foreach def,$(DEFINES),-D$(def))
#		`$(PKG_CONFIG) --cflags $(EXT_PKGS)` \

VALA_LDFLAGS = `$(PKG_CONFIG) --libs $(EXT_PKGS)`

# setting CFLAGS in configure.mk overrides build type
CFLAGS = -mms-bitfields -O0 -g -pipe -Wall
#CFLAGS = -lpthread -O2 -Wall

#-----------------------------------TARGETS----------------------------------------------
all: $(PROGRAM)
###############

$(PROGRAM): $(EXPANDED_OBJ_FILES) $(RESOURCES)
#$(LANG_STAMP)
############################################################
	#$(CC) $(EXPANDED_OBJ_FILES) $(CFLAGS) $(RESOURCES) $(VALA_LDFLAGS) -o $@.exe

$(EXPANDED_OBJ_FILES): %.o: %.c $(CONFIG_IN) Makefile
#####################################################
	$(CC) -c $(VALA_CFLAGS) $(CFLAGS) -o $@ $<

# Do not remove hard tab or at symbol; necessary for dependencies to complete.
$(EXPANDED_C_FILES): $(VALA_STAMP)
###################################
	@

#$(LANG_STAMP): $(EXPANDED_PO_FILES)
#####################################
#	$(foreach po,$(SUPPORTED_LANGUAGES), \
#		`mkdir -p $(LOCAL_LANG_DIR)/$(po)/LC_MESSAGES ; \
#       msgfmt -o $(LOCAL_LANG_DIR)/$(po)/LC_MESSAGES/gnonograms.mo po/$(po).po` \
#    )
#	touch $(LANG_STAMP)

$(VALA_STAMP): $(EXPANDED_SRC_FILES) Makefile	$(CONFIG_IN)
#####################################################################

	@ ./minver `valac --version | awk '{print $$2}'` $(MIN_VALAC_VERSION) || ( echo 'gnonograms requires Vala compiler $(MIN_VALAC_VERSION) or greater.  You are running' `valac --version` '\b.'; exit 1 )

ifndef ASSUME_PKGS
ifdef EXT_PKG_VERSIONS
	pkg-config --print-errors --exists '$(EXT_PKG_VERSIONS)'
else ifdef EXT_PKGS
	pkg-config --print-errors --exists $(EXT_PKGS)
endif
endif

#	@ type msgfmt > /dev/null || ( echo 'msgfmt (usually found in the gettext package) is missing and is required to build gnonograms. ' ; exit 1 )

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
#	rm -rf $(LOCAL_LANG_DIR)
#	rm -f $(LANG_STAMP)

cleantemps:
###########
	rm -f $(EXPANDED_C_FILES)
	rm -f $(EXPANDED_SAVE_TEMPS_FILES)
	rm -f $(EXPANDED_OBJ_FILES)
	rm -f $(VALA_STAMP)
#	rm -f $(LANG_STAMP)

dist: $(PROGRAM) $(DIST_FILES)
#############################
	mkdir -p $(PROGRAM)-$(VERSION)
	cp --parents $(DIST_FILES) $(PROGRAM)-$(VERSION)
	rm -f $(DIST_ZIP)
	zip -r $(DIST_ZIP) $(PROGRAM)-$(VERSION)
	rm -rf $(PROGRAM)-$(VERSION)

distclean: clean
##########
	rm -f configure.mk
