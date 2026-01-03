clear

echo "Building Axiom OS"
rm -rf bin/boot.bin
rm -rf bin/kernel.bin

nasm src/boot.asm -f bin -o bin/boot.bin
nasm src/kernel.asm -f bin -o bin/kernel.bin -I src/

cat bin/boot.bin bin/kernel.bin > disk/axiom.img
qemu-system-i386 -machine pcspk-audiodev=audio0 -audiodev driver=pa,id=audio0 disk/axiom.img