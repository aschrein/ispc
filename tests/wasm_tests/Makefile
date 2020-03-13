all: wasm_test

tmp_folder:
	mkdir tmp_folder

wasm_test: wasm_test.cpp wasm_test.ispc ../../builtins/builtins.c tmp_folder
	../bin/ispc wasm_test.ispc --emit-c++ -h wasm_test.h -O2 --target=wasm-i32x4 --emit-llvm-text -o tmp_folder/wasm_test.ispc.ll
	emcc -DTEST_SIG=$(TEST_SIG) -DTEST_HEADER="<wasm_test.h>" wasm_test.cpp -O2 -s EXPORTED_FUNCTIONS='["_main"]' -c -o tmp_folder/wasm_test.o
	emcc -DWASM_IMPLEMENTATION ../../builtins/builtins.c -O2 -s EXPORTED_FUNCTIONS='["___wasm_do_print"]' -c -o tmp_folder/builtins.o
	cd tmp_folder && llc -filetype=obj wasm_test.ispc.ll -o wasm_test.ispc.o
	cd tmp_folder && emcc wasm_test.o wasm_test.ispc.o builtins.o -o index.html
	cd tmp_folder && wasm-dis wasm_test.o -o wasm_test.o.wat
	cd tmp_folder && wasm-dis wasm_test.ispc.o -o wasm_test.ispc.o.wat
	cd tmp_folder && wasm-dis builtins.o -o builtins.o.wat
	cd tmp_folder && /home/aschrein/dev/cpp/v8/out/x64.debug/d8 --experimental-wasm-simd index.js

clean:
	rm -rf tmp_folder