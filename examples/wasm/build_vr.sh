mkdir -p tmp_dir && \
cd tmp_dir && \
../../../build/bin/ispc ../../volume_rendering/volume.ispc --math-lib=system  --opt=fast-masked-vload --opt=fast-math --opt=force-aligned-memory \
                                                       --emit-c++ -h volume_ispc.h -O3 --target=wasm-i32x4 --emit-llvm-text -o volume.ispc.ll && \
emcc -DWASM ../../volume_rendering/volume_serial.cpp  -I./ -O3 -s EXPORTED_FUNCTIONS='["_main"]' -c -o volume_serial.o && \
emcc -DWASM ../../volume_rendering/volume.cpp -I./  -O3 -s EXPORTED_FUNCTIONS='["_main"]' -c -o volume.o && \
emcc -DWASM -DISPC_USE_PTHREADS -s USE_PTHREADS=1 ../../tasksys.cpp   -I./  -O2 -s EXPORTED_FUNCTIONS='["_main"]' -c -o tasksys.o && \
llc -filetype=obj volume.ispc.ll -o volume.ispc.o && \
emcc -O3 volume.o volume.ispc.o volume_serial.o tasksys.o -s USE_PTHREADS=1 \
                    -s PTHREAD_POOL_SIZE=12 \
                    --preload-file ../../volume_rendering/camera.dat@/home/dummy/camera.dat \
                    --preload-file ../../volume_rendering/density_highres.vol@/home/dummy/density_highres.vol \
                    -s TOTAL_MEMORY=268435456 -o index.html && \
cp ../vr.html index.html && \
python3 -m http.server
exit
emcc -DWASM_IMPLEMENTATION ../../../builtins/builtins.c -O3 -s EXPORTED_FUNCTIONS='["___wasm_do_print", "___wasm_clock"]' -c -o builtins.o && \