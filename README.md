*Looking to play? Download the latest release [here](https://github.com/AnthonyBongers/GhostsAndGraves/releases/tag/release_1.0.3)!*

**NOTE: If you're updating to 1.0.3 from a previous version, don't! This will overwrite existing save data.**

Flash carts can have garbage data in SRAM on first launch, which was messing up the state of the game when launching it for the first time.

Emulators usually have zero'd out SRAM, so wouldn't have been affected.

<img src="https://github.com/AnthonyBongers/GhostsAndGraves/blob/main/reference/cart.png?raw=true" width="450">

Ghosts And Graves is a 6502 assembly NES demake of the puzzle game Tents And Trees!

Complete 25 worlds (700 levels in total) of mind-bending puzzles. 

- Dig around graves to reveal ghosts in the cemetary.
- Each grave can only have one ghost adjacent to it. 
- Each ghost is connected to only one grave.
- Make sure the ghosts don't touch (not even diagonally)!

Play four different game modes!

- Standard gameplay.
- Shy Ghost mode, where some lanes hide how many ghosts are there.
- No Shovel mode, where you can't use dig actions to narrow down where the ghosts could be.
- Time Attack mode, where you race to complete the level against the timer.

![level select image](https://github.com/AnthonyBongers/GhostsAndGraves/blob/main/reference/level_select.png?raw=true)
![gameplay image](https://github.com/AnthonyBongers/GhostsAndGraves/blob/main/reference/gameplay.gif?raw=true)

## Development

### Setup

I used [cc65](https://cc65.github.io/) as the assembler for this project. 

For C++ utilities, I used GNU g++ with clang-format to keep things neat-ish.

To automatically create NES ROMs as I was developing, I used `watchman-make`.

To install these utilities on your mac, run this command:
```
./setup.sh
```

This will also download nlohmann json for C++ utility usage to `./utils/src/shared/json.hpp`.

### The Dev Server

![devserver image](https://github.com/AnthonyBongers/GhostsAndGraves/blob/main/reference/devserver.png?raw=true)

To auto-generate the NES ROM as I'm developing, I wrapped `watchman-make` in the script:
```
./startdevserver.sh
```

This will kick off different Make commands depending on which files were changed.

If any errors occur during the ROM creation, you'll see a red error message. 

Have this running in the background while developing to make things a bit faster :) 

### Updating Graphics

All graphics were done in GIMP using lossless BMP formats, located in the `./raw/images/` folder.

The top portion of the BMP is for background tiles, and the bottom portion is for sprite tiles.

![nes image](https://github.com/AnthonyBongers/GhostsAndGraves/blob/main/raw/images/game.bmp?raw=true)

Each BMP has a config file alongside it. 
This file lets the conversion script know which colours in a given 8x8 tile correlate to which colour attribute in the resulting raw NES image data.

The `bmp2chr` utility in the `utils` folder will read these two files, and output the raw NES image data in the `./assets/chr/` folder.

### Updating Nametables

For nametable generation, I used NES Lightbox. 

I save these to `./raw/nametables/`, and then hook these up to the rle script in the Makefile.

These are then loaded from the `./assets/nametables/` folder in the source.

### Music and Sound Effects

I used Famistudio for music and sounds in the game. 

There aren't any cli tools available for auto-generating the asm out of the project files, so they are manually generated into the `./assets/sound/` folder.

### The Source

All the assembly can be found in the `./src/` folder.

If you're looking for the meat of the game code, you'll likely find what you're lookin for in the `./src/screens/` folder. 

I was learning as I was making this, so there's some inconsistency and weirdness, but I commented along the way to hopefully clear up any strange decisions.

The level and sfx assembly is in the `./assets/` folder, since I considered them as more of an asset than source code.

## Thanks To

### Gustavo Pezzi @ Pikuma.com

I started [this course](https://pikuma.com/courses/nes-game-programming-tutorial) earlier in the year.

For anyone looking to learn 6502 assembly and NES development, this is THE course to take.

### Contributors @ nesdev.org

For all the weird quirks of the NES -- and there are LOTS -- this is the best reference.
