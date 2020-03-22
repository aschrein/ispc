mkdir -p tmp_dir && \
cd tmp_dir && \
../../../build/bin/ispc ../../deferred/kernels.ispc --math-lib=system  --opt=fast-masked-vload --opt=fast-math --opt=force-aligned-memory \
                                                       --emit-c++ -h kernels_ispc.h -O3 --target=wasm-i32x4 --emit-llvm-text -o kernels.ispc.ll && \
emcc -DWASM ../../deferred/main.cpp  -I./ -O3 -s EXPORTED_FUNCTIONS='["_main"]' -c -o main.o && \
emcc -DWASM ../../deferred/common.cpp  -I./ -O3 -s EXPORTED_FUNCTIONS='["_main"]' -c -o common.o && \
emcc -DWASM ../../deferred/dynamic_c.cpp  -I./ -O3 -s EXPORTED_FUNCTIONS='["_main"]' -c -o dynamic_c.o && \
emcc -DWASM -DISPC_USE_PTHREADS -s USE_PTHREADS=1 ../../tasksys.cpp   -I./  -O2 -s EXPORTED_FUNCTIONS='["_main"]' -c -o tasksys.o && \
llc -filetype=obj kernels.ispc.ll -o kernels.ispc.o && \
emcc -O3 main.o kernels.ispc.o common.o dynamic_c.o tasksys.o -s USE_PTHREADS=1 \
                    -s PTHREAD_POOL_SIZE=12 \
                    --preload-file /home/aschrein/dev/cpp/ispc/examples/deferred/data/pp1280x720.bin@/home/dummy/pp1280x720.bin \
                    -s TOTAL_MEMORY=268435456 -o index.html && \
cp ../def.html index.html && \
python3 -m http.server
exit
emcc -DWASM_IMPLEMENTATION ../../../builtins/builtins.c -O3 -s EXPORTED_FUNCTIONS='["___wasm_do_print", "___wasm_clock"]' -c -o builtins.o && \