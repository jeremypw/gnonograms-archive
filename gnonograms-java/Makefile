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
PROGRAM=gnonograms-java
VERSION=0.4.0

JAVAC=javac
JAR=jar

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
	Gnonograms.java \
	Model.java \
	Move.java \
	MoveList.java \
	My2DCellArray.java \
	Permutor.java \
	Region.java \
	Resource.java \
	Solver.java \
	Utils.java \
	Viewer.java \


ifndef BUILD_DIR
BUILD_DIR=build
endif

EXPANDED_SRC_FILES = $(foreach src,$(SRC_FILES),src/$(src))
#-----------------------------------TARGETS----------------------------------------------
all: $(PROGRAM)
###############

$(PROGRAM): $(EXPANDED_SRC_FILES) Makefile
############################################################
	$(JAVAC) -d  $(BUILD_DIR) $(EXPANDED_SRC_FILES)

jar: $(PROGRAM)
###############
	$(JAR) cfm Gnonograms-$(VERSION).jar Manifest.txt -C build .
