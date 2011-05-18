PROGRAM = gnonograms

VERSION = 0.1.0--
GETTEXT_PACKAGE = $(PROGRAM)
BUILD_ROOT = 1

VALAC = valac
MIN_VALAC_VERSION = 0.7.10
INSTALL_PROGRAM = install
INSTALL_DATA = install -m 644

# defaults that may be overridden by configure.mk
PREFIX=/usr/local
SCHEMA_FILE_DIR=/etc/gconf/schemas
BUILD_RELEASE=1

-include configure.mk

VALAFLAGS = -g --enable-checking $(USER_VALAFLAGS)

DEFINES=_PREFIX='"$(PREFIX)"' _VERSION='"$(VERSION)"' GETTEXT_PACKAGE='"$(GETTEXT_PACKAGE)"' _LANG_SUPPORT_DIR='"$(SYSTEM_LANG_DIR)"'

SUPPORTED_LANGUAGES=en_GB ja_JP
LOCAL_LANG_DIR=locale
SYSTEM_LANG_DIR=$(DESTDIR)$(PREFIX)/share/locale

SRC_FILES = \
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
	

SRC_HEADER_FILES = 

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
DESKTOP_APPLICATION_COMMENT="Solve and design Gnonogram puzzles"
DESKTOP_APPLICATION_CLASS="Games"
DIRECT_EDIT_DESKTOP_APPLICATION_NAME="Gnonograms"
DIRECT_EDIT_DESKTOP_APPLICATION_CLASS="Games"
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
DIST_FILES+= po/gnonogram.pot icons/*

PACKAGE_ORIG_GZ = $(PROGRAM)_`parsechangelog | grep Version | sed 's/.*: //'`.orig.tar.gz

VALA_CFLAGS = `pkg-config --cflags $(EXT_PKGS)` $(foreach hdir,$(HEADER_DIRS),-I$(hdir)) \
	$(foreach def,$(DEFINES),-D$(def))

VALA_LDFLAGS = `pkg-config --libs $(EXT_PKGS)`

# setting CFLAGS in configure.mk overrides build type
ifndef CFLAGS
ifdef BUILD_DEBUG
CFLAGS = -O0 -g -pipe
else
CFLAGS = -O2 -g -pipe
endif
endif

# Required for gudev-1.0
#CFLAGS += -DG_UDEV_API_IS_SUBJECT_TO_CHANGE

#-----------------------------------TARGETS----------------------------------------------
all: $(PROGRAM)
###########

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
##########################
	$(foreach po,$(SUPPORTED_LANGUAGES),`mkdir -p $(LOCAL_LANG_DIR)/$(po)/LC_MESSAGES ; \
        msgfmt -o $(LOCAL_LANG_DIR)/$(po)/LC_MESSAGES/gnonograms.mo po/$(po).po`)
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
	$(foreach vapidir,$(VAPI_DIRS),--vapidir=$(vapidir)) \
	$(foreach def,$(DEFINES),-X -D$(def)) \
	$(foreach hdir,$(HEADER_DIRS),-X -I$(hdir)) \
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

package:
######
	$(MAKE) dist
	cp $(DIST_TAR_GZ) $(PACKAGE_ORIG_GZ)
	rm -f $(DIST_TAR_GZ)
	rm -f $(DIST_TAR_BZ2)

dist: $(DIST_FILES)
############
	mkdir -p $(PROGRAM)-$(VERSION)
	mkdir -p $(PROGRAM)-$(VERSION)/games
	cp --parents $(DIST_FILES) $(PROGRAM)-$(VERSION)
	tar --gzip -cvf $(PROGRAM)-$(VERSION).tar.gz $(PROGRAM)-$(VERSION)
	rm -rf $(PROGRAM)-$(VERSION)

dist_with_c:
###########
	mkdir -p $(PROGRAM)-$(VERSION)c
	mkdir -p $(PROGRAM)-$(VERSION)c/games
	cp --parents $(DIST_FILES) $(PROGRAM)-$(VERSION)c
	cp --parents $(EXPANDED_C_FILES) $(PROGRAM)-$(VERSION)c
	tar --gzip -cvf $(PROGRAM)-$(VERSION)c.tar.gz $(PROGRAM)-$(VERSION)c
	rm -rf $(PROGRAM)-$(VERSION)c
	
distclean: clean
##########
	rm -f configure.mk

install:
####
	cp misc/gnonogram.desktop.head misc/gnonograms.desktop
	$(foreach lang,$(SUPPORTED_LANGUAGES), echo Name[$(lang)]=`TEXTDOMAINDIR=locale \
     LANGUAGE=$(lang) gettext --domain=gnonograms $(DESKTOP_APPLICATION_NAME)` \
    >> misc/gnonograms.desktop ; \
        echo GenericName[$(lang)]=`TEXTDOMAINDIR=locale LANGUAGE=$(lang) \
        gettext --domain=gnonograms $(DESKTOP_APPLICATION_CLASS)` >> misc/gnonograms.desktop ; \
        echo Comment[$(lang)]=`TEXTDOMAINDIR=locale LANGUAGE=$(lang) gettext \
        --domain=gnonogram $(DESKTOP_APPLICATION_COMMENT)` >> misc/gnonograms.desktop ; 
	touch $(LANG_STAMP)
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	$(INSTALL_PROGRAM) $(PROGRAM) $(DESTDIR)$(PREFIX)/bin
	mkdir -p $(DESTDIR)$(PREFIX)/share/gnonograms/icons
	$(INSTALL_DATA) icons/* $(DESTDIR)$(PREFIX)/share/gnonograms/icons
	mkdir -p $(DESTDIR)$(PREFIX)/share/gnonogram/games
	$(INSTALL_DATA) games/* $(DESTDIR)$(PREFIX)/share/gnonograms/games
	mkdir -p $(DESTDIR)$(PREFIX)/share/icons/hicolor/scalable/apps
	$(INSTALL_DATA) icons/gnonograms.svg $(DESTDIR)$(PREFIX)/share/icons/hicolor/scalable/apps
ifndef DISABLE_ICON_UPDATE
	-gtk-update-icon-cache -t -f $(DESTDIR)$(PREFIX)/share/icons/hicolor || :
endif
	mkdir -p $(DESTDIR)$(PREFIX)/share/applications
	$(INSTALL_DATA) misc/gnonograms.desktop $(DESTDIR)$(PREFIX)/share/applications
	$(INSTALL_DATA) gnonogramLINGUAS $(DESTDIR)$(PREFIX)/share/gnonograms
	
ifndef DISABLE_DESKTOP_UPDATE
	-update-desktop-game || :
endif

#ifndef DISABLE_SCHEMAS_INSTALL
#	GCONF_CONFIG_SOURCE=`gconftool-2 --get-default-source` gconftool-2 --makefile-install-rule misc/gnonogram.schemas
#else
#	mkdir -p $(DESTDIR)$(SCHEMA_FILE_DIR)
#	$(INSTALL_DATA) misc/gnonogram.schemas $(DESTDIR)$(SCHEMA_FILE_DIR)
#endif

	-$(foreach lang,$(SUPPORTED_LANGUAGES),`mkdir -p $(SYSTEM_LANG_DIR)/$(lang)/LC_MESSAGES ; \
        $(INSTALL_DATA) $(LOCAL_LANG_DIR)/$(lang)/LC_MESSAGES/gnonograms.mo \
            $(SYSTEM_LANG_DIR)/$(lang)/LC_MESSAGES/gnonograms.mo`)

uninstall:
######
	rm -f $(DESTDIR)$(PREFIX)/bin/$(PROGRAM)
	rm -fr $(DESTDIR)$(PREFIX)/share/gnonograms
	rm -fr $(DESTDIR)$(PREFIX)/share/icons/hicolor/scalable/apps/gnonograms.svg
	rm -f $(DESTDIR)$(PREFIX)/share/applications/gnonograms.desktop
	rm -f misc/gnonograms.desktop
	
ifndef DISABLE_DESKTOP_UPDATE
	-update-desktop-game || :
endif

#ifndef DISABLE_SCHEMAS_INSTALL
#	GCONF_CONFIG_SOURCE=`gconftool-2 --get-default-source` gconftool-2 --makefile-uninstall-rule misc/gnonogram.schemas
#else
#	rm -f $(DESTDIR)$(SCHEMA_FILE_DIR)/gnonogram.schemas
#endif

	$(foreach lang,$(SUPPORTED_LANGUAGES),`rm -f $(SYSTEM_LANG_DIR)/$(lang)/LC_MESSAGES/gnonograms.mo`)

