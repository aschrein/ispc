all: wasm_test

tmp_folder:
	mkdir tmp_folder

tmp_folder/builtins.o: $(ISPC_HOME)/../../builtins/builtins.c
	emcc -DWASM_IMPLEMENTATION $(ISPC_HOME)/../../builtins/builtins.c -O2 -s EXPORTED_FUNCTIONS='["___wasm_do_print", "___wasm_clock"]' -c -o tmp_folder/builtins.o

wasm_test: wasm_test.cpp tmp_folder/wasm_test.ispc tmp_folder/builtins.o tmp_folder
	cd tmp_folder && $(ISPC_HOME)/ispc --math-lib=system wasm_test.ispc --emit-c++ -h wasm_test.h -O2 --target=wasm-i32x4 --emit-llvm-text -o wasm_test.ispc.ll
	cd tmp_folder && emcc -DTEST_SIG=$(TEST_SIG) -DTEST_HEADER="\"tmp_folder/wasm_test.h\"" ../wasm_test.cpp -O2 -s EXPORTED_FUNCTIONS='["_main"]' -c -o wasm_test.o
	cd tmp_folder && llc -filetype=obj wasm_test.ispc.ll -o wasm_test.ispc.o
	cd tmp_folder && emcc wasm_test.o wasm_test.ispc.o builtins.o -o index.html
	# cd tmp_folder && wasm-dis wasm_test.o -o wasm_test.o.wat
	# cd tmp_folder && wasm-dis wasm_test.ispc.o -o wasm_test.ispc.o.wat
	# cd tmp_folder && wasm-dis builtins.o -o builtins.o.wat
	cd tmp_folder && /home/aschrein/dev/cpp/v8/out/x64.debug/d8 --experimental-wasm-simd index.js

clean:
	rm -rf tmp_folder