all: out/bios.bin

out/accurate-kosinski/kosinski-compress:
	@mkdir -p out
	@mkdir -p out/accurate-kosinski
	cmake -B out/accurate-kosinski bin/accurate-kosinski -DCMAKE_BUILD_TYPE=Release -DCMAKE_RUNTIME_OUTPUT_DIRECTORY=.
	cmake --build out/accurate-kosinski --config Release --target kosinski-compress

out/clownassembler/clownassembler:
	@mkdir -p out
	@mkdir -p out/clownassembler
	cmake -B out/clownassembler bin/clownassembler -DCMAKE_BUILD_TYPE=Release -DCMAKE_RUNTIME_OUTPUT_DIRECTORY=.
	cmake --build out/clownassembler --config Release --target clownassembler

out/clownlzss/clownlzss-tool:
	@mkdir -p out
	@mkdir -p out/clownlzss
	cmake -B out/clownlzss bin/clownlzss -DCMAKE_BUILD_TYPE=Release -DCMAKE_RUNTIME_OUTPUT_DIRECTORY=.
	cmake --build out/clownlzss --config Release --target clownlzss-tool

out/clownnemesis/clownnemesis-tool:
	@mkdir -p out
	@mkdir -p out/clownnemesis
	cmake -B out/clownnemesis bin/clownnemesis -DCMAKE_BUILD_TYPE=Release -DCMAKE_RUNTIME_OUTPUT_DIRECTORY=.
	cmake --build out/clownnemesis --config Release --target clownnemesis-tool

out/sub_bios.bin: src/sub/core.asm out/clownassembler/clownassembler
	@mkdir -p out
	out/clownassembler/clownassembler -i $< -o $@

out/sub_bios.kos: out/sub_bios.bin out/accurate-kosinski/kosinski-compress
	@mkdir -p out
	out/accurate-kosinski/kosinski-compress $< $@

src/splash/tiles.bin src/splash/map.bin:
	$(MAKE) -C src/splash

src/splash/tiles.nem: src/splash/tiles.bin out/clownnemesis/clownnemesis-tool
	out/clownnemesis/clownnemesis-tool -c $< $@

src/splash/map.eni: src/splash/map.bin out/clownlzss/clownlzss-tool
	out/clownlzss/clownlzss-tool -e $< $@

out/bios.bin: src/main/core.asm out/sub_bios.kos out/clownassembler/clownassembler src/splash/tiles.nem src/splash/map.eni
	@mkdir -p out
	out/clownassembler/clownassembler -i $< -o $@
