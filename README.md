# gnonograms
###Gnonograms. Nonogram puzzle generator and solver

####Introduction
Gnonograms is an implementation of the Japanese logic puzzle "Nonograms", also known as "Tsunami", "Griddlers" .....".  
The object of the game is to discover the pattern in the grid which is encoded by the clues which are give for each row and column. Each clue is a series of numbers which represent blocks of filled in cells in the corresponding row or column. Each number indicates how many cells are in the block it represents. Each block must be separated by at least one empty cell from neighbouring blocks. The order of the numbers in the clue shows the order in which the blocks appear in the row or column.  

#####Main Features
* Design nonogram puzzles manually by painting
* Enter puzzles from clues
* Automatically generate puzzles
* Import image file and convert to nonogram
* Solve puzzles manually
* Undo, redo moves
* Undo to last correct position
* Mark cell, return to marked position
* Solve puzzles by computer
* Save puzzles and partially completed puzzles
* Handles puzzle grids up to 100x100 (practical limit depends on screen size)  

Software to convert gnonogram puzzle files (.gno files) to SVG for printing can be found here:
https://github.com/jandechent/gnonogram2svg

#####Contact
Please send your bug reports, feature requests, bouquets or brickbats to jeremywootten@gmail.com

#####Platforms
######Java
Requires Java runtime version 6 or greater to be installed. Mostly tested on Linux, some testing on Windows 7 and Vista. Should run on other systems supporting Java 6. This is now the most recent version and has a better image to puzzle converter.

![Screenshot (Java version)](https://github.com/jeremypw/gnonograms/blob/master/Screenshot-Gnonograms%20for%20Java.png)

######GNU/Linux
Versions for the Gnome2 and Gnome3 desktop environments are available, either as source code or pre-compiled on Ubuntu 11.10. Differences from the Java version: 1) Inbuilt manual 2) Optional time penalty for checking for errors during solving 3) Simpler image to puzzle converter 4) Integration with the Linux desktop

![Screenshot (Gtk version)](https://github.com/jeremypw/gnonograms/blob/master/Screenshot-Gnonograms3-30-12-12.png)

#####Windows
A beta version cross-compiled for Windows (XP or later) is available for download as an executable. No installation required.
