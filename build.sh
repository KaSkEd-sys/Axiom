echo "Building os..."

rm -rf boot.bin
rm -rf kernel.bin


nasm src/boot.asm -f bin -o bin/boot.bin
nasm src/kernel.asm -f bin -o bin/kernel.bin
cat bin/boot.bin bin/kernel.bin > disk/kaskedos.img
qemu-system-i386 disk/kaskedos.img

