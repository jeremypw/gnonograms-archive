#  Make file for gnonograms-java
#  Copyright (C) 2012  Jeremy Wootten
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
PROGRAM=Gnonograms
VERSION=0.8.0-jre6

JAVAC=javac
JAR=jar
TAR=tar

SRC_FILES = \
	Cell.java \
	CellGrid.java \
	Config.java \
	Controller.java \
	GameEditor.java \
	GameLoader.java \
	GameSaver.java \
	GnonogramLabel.java \
	LabelBox.java \
	Main.java \
	Model.java \
	Move.java \
	MoveList.java \
	My2DCellArray.java \
	Region.java \
	Resource.java \
	Solver.java \
	Splash.java \
	Utils.java \
	Viewer.java \

BUILD_DIR=build
IMAGE_DIR=build/images

IMAGE_FILES = \
	*.png \
	*.gif \

TEXT_FILES = \
	Makefile \
	AUTHORS \
	COPYING \
	INSTALL \
	MAINTAINERS \
	NEWS \
	README \
	THANKS

EXPANDED_SRC_FILES = $(foreach src,$(SRC_FILES),src/$(src))
EXPANDED_IMAGE_FILES= $(foreach img, $(IMAGE_FILES), $(IMAGE_DIR)/$(img))

DIST_FILES = $(TEXT_FILES)
DIST_FILES+= $(EXPANDED_SRC_FILES) 
DIST_FILES+= $(EXPANDED_IMAGE_FILES)

DIST_TAR_GZ = $(PROGRAM)-$(VERSION).tar.gz

#-----------------------------------TARGETS----------------------------------------------
all: $(PROGRAM)
###############

$(PROGRAM): $(EXPANDED_SRC_FILES) Makefile
############################################################
	$(JAVAC) -d  $(BUILD_DIR) $(EXPANDED_SRC_FILES)

jar: $(PROGRAM)
###############
	$(JAR) cfe $(PROGRAM)-$(VERSION).jar Main  -C build .
	
dist: $(PROGRAM) $(DIST_FILES)
###############################
	mkdir -p $(PROGRAM)-$(VERSION)
	cp --parents $(DIST_FILES) $(PROGRAM)-$(VERSION)
	rm -f $(DIST_TAR_GZ)
	$(TAR) --gzip -cvf $(DIST_TAR_GZ) $(PROGRAM)-$(VERSION)
	rm -rf $(PROGRAM)-$(VERSION)
