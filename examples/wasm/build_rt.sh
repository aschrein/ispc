bin/ispc ../examples/rt/rt.ispc --opt=fast-masked-vload --opt=fast-math --opt=force-aligned-memory --emit-c++ -h rt_ispc.h -O3 --target=wasm-i32x4 --emit-llvm-text -o rt.ispc.ll
emcc -DWASM ../examples/rt/rt_serial.cpp  -I./ -O3 -s EXPORTED_FUNCTIONS='["_main"]' -c -o rt_serial.o
emcc -DWASM ../examples/rt/rt.cpp -I./  -O3 -s EXPORTED_FUNCTIONS='["_main"]' -c -o rt.o
emcc -DWASM_IMPLEMENTATION ../builtins/builtins.c -O3 -s EXPORTED_FUNCTIONS='["___wasm_do_print", "___wasm_clock"]' -c builtins.o
emcc -DWASM -DISPC_USE_PTHREADS -s USE_PTHREADS=1 ../examples/tasksys.cpp   -I./  -O2 -s EXPORTED_FUNCTIONS='["_main"]' -c -o tasksys.o
llc -filetype=obj rt.ispc.ll -o rt.ispc.o
emcc -O3 rt.o rt.ispc.o builtins.o rt_serial.o tasksys.o -s USE_PTHREADS=1 \
                    -s PTHREAD_POOL_SIZE=12 \
                    --preload-file ../examples/rt/sponza.bvh@/home/dummy/sponza.bvh \
                    --preload-file ../examples/rt/sponza.camera@/home/dummy/sponza.camera -s TOTAL_MEMORY=268435456 -o index.html