#starting with reiner zeigler's startup.gb (last edit 28-Jun-97 by Jeff Frohwein)
hoping to add the following features:- 
   -some form of cpu detection sgb/mgb/cgb??? 
   -more use of buttons e.g. A button to start game 
   -support for self flashing the amd29f040 chip.

The theory is to self erase sector SA02 (the first Gamebank if the Flash rom is connected
in MBC1M configuration with EA0 & EA1 controlling upper address lines to split the cart into 4 x 128k banks). 
The Gamboy would then attempt to copy a gameROM into Ram & then flash it to SA02. 
This would enable more than 3 Gameroms to be used on the multicart.
