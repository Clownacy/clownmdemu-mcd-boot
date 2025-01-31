all: build/bios.bin

build/accurate-kosinski/kosinski-compress:
	@mkdir -p build
	@mkdir -p build/accurate-kosinski
	cmake -B build/accurate-kosinski tools/accurate-kosinski -DCMAKE_BUILD_TYPE=Release -DCMAKE_RUNTIME_OUTPUT_DIRECTORY=.
	cmake --build build/accurate-kosinski --config Release --target kosinski-compress

tools/clownassembler/clownassembler:
	$(MAKE) -C tools/clownassembler clownassembler

tools/clownlzss/clownlzss:
	$(MAKE) -C tools/clownlzss clownlzss

build/clownnemesis/clownnemesis-tool:
	@mkdir -p build
	@mkdir -p build/clownnemesis
	cmake -B build/clownnemesis tools/clownnemesis -DCMAKE_BUILD_TYPE=Release -DCMAKE_RUNTIME_OUTPUT_DIRECTORY=.
	cmake --build build/clownnemesis --config Release --target clownnemesis-tool

build/subbios.bin: sub/core.asm tools/clownassembler/clownassembler
	@mkdir -p build
	tools/clownassembler/clownassembler -i $< -o $@

build/subbios.kos: build/subbios.bin build/accurate-kosinski/kosinski-compress
	@mkdir -p build
	build/accurate-kosinski/kosinski-compress $< $@

main/splash/tiles.bin main/splash/map.bin:
	$(MAKE) -C main/splash

main/splash/tiles.nem: main/splash/tiles.bin build/clownnemesis/clownnemesis-tool
	build/clownnemesis/clownnemesis-tool -c $< $@

main/splash/map.eni: main/splash/map.bin tools/clownlzss/clownlzss
	tools/clownlzss/clownlzss -e $< $@

build/bios.bin: main/core.asm build/subbios.kos tools/clownassembler/clownassembler main/splash/tiles.nem main/splash/map.eni
	@mkdir -p build
	tools/clownassembler/clownassembler -i $< -o $@
