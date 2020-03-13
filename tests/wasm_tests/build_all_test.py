import os
import sys
dir ="../../tests"
filelist = os.listdir(dir)
size = len(filelist)
start = int(sys.argv[1])
cnt = 0
def parse(filename):
  sig2def = { "f_v(" : 0, "f_f(" : 1, "f_fu(" : 2, "f_fi(" : 3,
                    "f_du(" : 4, "f_duf(" : 5, "f_di(" : 6, "f_sz" : 7 }
  file = open(filename, 'r')
  match = -1
  for line in file:
    # look for lines with 'export'...
    if line.find("export") == -1:
        continue
    # one of them should have a function with one of the
    # declarations in sig2def
    for pattern, ident in list(sig2def.items()):
      if line.find(pattern) != -1:
        match = ident
        break
  file.close()
  return match
for file in filelist:
  if file.endswith(".ispc"):
    cnt += 1
    if cnt < start:
      continue
    import subprocess
    fullpath = dir + "/" + file
    print("processing " + " " + str(cnt) + "/" + str(size) + " \t" + fullpath)
    match = parse(fullpath)
    if match < 0:
      raise "match < 0"
    cmds = [
      'cp ' + fullpath + ' wasm_test.ispc',
      'make TEST_SIG={}'.format(match),
      # 'bin/ispc ' + fullpath + '--target=wasm-i32x4 --emit-llvm-text -o dummy.ll',
    ];
    for cmd in cmds:
      # process = subprocess.Popen(['bin/ispc', fullpath, '--target=wasm-i32x4', '--emit-llvm-text', '-o', 'dummy.ll'])
      process = subprocess.Popen(cmd.split(' '))
      stdout, stderr = process.communicate()
      
      if process.returncode != 0:
        exit(-1)
    