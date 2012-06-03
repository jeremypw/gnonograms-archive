#  Make file for gnonograms-java
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
PROGRAM=gnonograms-java

VERSION=0.0.1

JAVAC=javac

# VALAFLAGS = -g --enable-checking $(USER_VALAFLAGS)

SRC_FILES = \
	Cell.java \
	CellGrid.java \
	Controller.java \
	GameLoader.java \
	GameState.java \
	Gnonograms.java \
	GnonogramLabel.java \
	LabelBox.java \
	Model.java \
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
	$(JAVAC) -Xlint -d $(BUILD_DIR) $(EXPANDED_SRC_FILES)
