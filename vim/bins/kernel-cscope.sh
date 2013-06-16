#!/bin/sh

if [ $# != 1 ]; then
    echo "Usage: $0 <sourcedir>"
    exit
fi

LNX=$(readlink -f "$1")
if [ ! -d $LNX ]; then
    echo "no such directory:$LNX"
    exit
fi

echo $LNX

find  $LNX                                                                \
    -path "$LNX/arch/*" ! -path "$LNX/arch/arm*" -prune -o               \
    -path "$LNX/arch/arm/mach-*" ! -path "$LNX/arch/arm/mach-exynos4*" -prune -o               \
    -path "$LNX/arch/arm/plat-*" ! -path "$LNX/arch/arm/plat-s5p*" ! -path "$LNX/arch/arm/plat-samsung*" -prune -o               \
    -path "$LNX/include/asm-*" ! -path "$LNX/include/asm-arm*" -prune -o \
    -path "$LNX/tmp*" -prune -o                                           \
    -path "$LNX/Documentation*" -prune -o                                 \
    -path "$LNX/scripts*" -prune -o                                       \
    -path "$LNX/samples*" -prune -o                                       \
    -path "$LNX/tools*" -prune -o                                       \
    -path "$LNX/firmware*" -prune -o                                       \
    -name "*.[chxsS]" -print > cscope.files
