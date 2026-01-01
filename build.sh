clear

echo "Building os..."
rm -rf bin/boot.bin
rm -rf bin/kernel.bin


nasm src/boot.asm -f bin -o bin/boot.bin
nasm src/kernel.asm -f bin -o bin/kernel.bin
cat bin/boot.bin bin/kernel.bin > disk/axiom.img
qemu-system-i386 disk/axiom.img