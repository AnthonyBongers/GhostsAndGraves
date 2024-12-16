.SILENT:
build:
	echo "\n\033[37m\033[1m• info: \033[22m\033[39mcompiling 6502 source\n"
	rm -f ./bin/Ghosts\ And\ Graves.map
	ca65 ./src/game.asm -o ./bin/Ghosts\ And\ Graves.o --debug-info --bin-include-dir ./assets/ --include-dir ./assets/
	ld65 ./bin/Ghosts\ And\ Graves.o -o ./bin/Ghosts\ And\ Graves.nes --config nes.cfg --dbgfile ./bin/Ghosts\ And\ Graves.dbg --mapfile ./bin/Ghosts\ And\ Graves.map
	./utils/bin/romStats ./bin/Ghosts\ And\ Graves.map
	echo ""

.SILENT:
build_utils:
	echo "\n\033[37m\033[1m• info: \033[22m\033[39mcompiling utility scripts"
	g++ -std=c++17 -O2 ./utils/src/rle.cpp -o ./utils/bin/rle
	g++ -std=c++17 -O2 ./utils/src/bmp2chr.cpp -o ./utils/bin/bmp2chr
	g++ -std=c++17 -O2 ./utils/src/createPuzzles.cpp -o ./utils/bin/createPuzzles
	g++ -std=c++17 -O2 ./utils/src/romStats.cpp -o ./utils/bin/romStats
	g++ -std=c++17 -O2 ./utils/src/createWorld.cpp -o ./utils/bin/createWorld
	make generate

.SILENT:
generate:
	echo "\n\033[37m\033[1m• info: \033[22m\033[39mexecuting utility scripts\n"
	./utils/bin/bmp2chr ./raw/images/splash.bmp      ./raw/images/splash.conf      ./assets/chr/splash.chr
	./utils/bin/bmp2chr ./raw/images/title.bmp       ./raw/images/title.conf       ./assets/chr/title.chr
	./utils/bin/bmp2chr ./raw/images/levelselect.bmp ./raw/images/levelselect.conf ./assets/chr/levelselect.chr
	./utils/bin/bmp2chr ./raw/images/game.bmp        ./raw/images/game.conf        ./assets/chr/game.chr
	./utils/bin/bmp2chr ./raw/images/tutorial.bmp    ./raw/images/tutorial.conf    ./assets/chr/tutorial.chr
	./utils/bin/rle     ./raw/nametables/splash.nam      ./assets/nametables/splash.rle
	./utils/bin/rle     ./raw/nametables/title.nam       ./assets/nametables/title.rle
	./utils/bin/rle     ./raw/nametables/levelselect.nam ./assets/nametables/levelselect.rle
	./utils/bin/rle     ./raw/nametables/game.nam        ./assets/nametables/game.rle
	./utils/bin/rle     ./raw/nametables/gamecomplete.nam ./assets/nametables/gamecomplete.rle
	./utils/bin/rle     ./raw/nametables/tutorial_1.nam ./assets/nametables/tutorial_1.rle
	./utils/bin/rle     ./raw/nametables/tutorial_2.nam ./assets/nametables/tutorial_2.rle
	./utils/bin/rle     ./raw/nametables/tutorial_3.nam ./assets/nametables/tutorial_3.rle
	./utils/bin/rle     ./raw/nametables/tutorial_4.nam ./assets/nametables/tutorial_4.rle
	./utils/bin/rle     ./raw/nametables/tutorial_5.nam ./assets/nametables/tutorial_5.rle
	./utils/bin/rle     ./raw/nametables/tutorial_6.nam ./assets/nametables/tutorial_6.rle
	./utils/bin/rle     ./raw/nametables/tutorial_7.nam ./assets/nametables/tutorial_7.rle
	./utils/bin/rle     ./raw/nametables/tutorial_8.nam ./assets/nametables/tutorial_8.rle
	./utils/bin/rle     ./raw/nametables/tutorial_9.nam ./assets/nametables/tutorial_9.rle
	./utils/bin/rle     ./raw/nametables/tutorial_10.nam ./assets/nametables/tutorial_10.rle
	./utils/bin/rle     ./raw/nametables/tutorial_11.nam ./assets/nametables/tutorial_11.rle
	./utils/bin/rle     ./raw/nametables/tutorial_12.nam ./assets/nametables/tutorial_12.rle
	./utils/bin/rle     ./raw/nametables/tutorial_13.nam ./assets/nametables/tutorial_13.rle
	./utils/bin/rle     ./raw/nametables/tutorial_14.nam ./assets/nametables/tutorial_14.rle
	./utils/bin/createPuzzles ./raw/levels/world_1.conf
	./utils/bin/createPuzzles ./raw/levels/world_2.conf
	./utils/bin/createPuzzles ./raw/levels/world_3.conf
	./utils/bin/createPuzzles ./raw/levels/world_4.conf
	./utils/bin/createPuzzles ./raw/levels/world_5.conf
	./utils/bin/createPuzzles ./raw/levels/world_6.conf
	./utils/bin/createPuzzles ./raw/levels/world_7.conf
	./utils/bin/createPuzzles ./raw/levels/world_8.conf
	./utils/bin/createPuzzles ./raw/levels/world_9.conf
	./utils/bin/createPuzzles ./raw/levels/world_10.conf
	./utils/bin/createPuzzles ./raw/levels/world_11.conf
	./utils/bin/createPuzzles ./raw/levels/world_12.conf
	./utils/bin/createPuzzles ./raw/levels/world_13.conf
	./utils/bin/createPuzzles ./raw/levels/world_14.conf
	./utils/bin/createPuzzles ./raw/levels/world_15.conf
	./utils/bin/createPuzzles ./raw/levels/world_16.conf
	./utils/bin/createPuzzles ./raw/levels/world_17.conf
	./utils/bin/createPuzzles ./raw/levels/world_18.conf
	./utils/bin/createPuzzles ./raw/levels/world_19.conf
	./utils/bin/createPuzzles ./raw/levels/world_20.conf
	./utils/bin/createPuzzles ./raw/levels/world_21.conf
	./utils/bin/createPuzzles ./raw/levels/world_22.conf
	./utils/bin/createPuzzles ./raw/levels/world_23.conf
	./utils/bin/createPuzzles ./raw/levels/world_24.conf
	./utils/bin/createPuzzles ./raw/levels/world_25.conf
	echo ""

.SILENT:
format:
	echo "\n\033[37m\033[1m• info: \033[22m\033[39mformatting source code\n"
	clang-format -i ./utils/src/*.cpp

.SILENT:
clean: 
	echo "\n\033[37m\033[1m• info: \033[22m\033[39mcleaning workspace\n"
	rm -rf ./bin

.SILENT:
run: 
	/Applications/Mesen.app/Contents/MacOS/Mesen ./bin/game.nes
