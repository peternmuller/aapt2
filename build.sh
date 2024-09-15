#!/usr/bin/env bash

env

msg () { printf "%s\n" "$@" >&2; }

if [[ -z $ANDROID_NDK_ROOT ]]; then
    msg "Please specify the Android NDK environment variable \"ANDROID_NDK_ROOT\"."
    exit 1
fi

TOOLCHAIN=$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64
STRIP=$TOOLCHAIN/bin/llvm-strip
CLEAN=termux-elf-cleaner
BUILDDIR="$(pwd)/build"

ARCH=$1
API=24
[ -z $ARCH ] && ARCH=aarch64

case $ARCH in
    arm64|aarch64) ARCH=aarch64; ABI=arm64-v8a;;
    arm) ARCH=arm; ABI=armeabi-v7a;;
    x64|x86_64) ARCH=x86_64; ABI=x86_64;;
    x86|i686) ARCH=i686; ABI=x86;;
    *) msg "Invalid arch: $ARCH!"; exit 1;;
esac
msg "Compiling for arch: $ARCH, api: $API"

msg "Configuring"
cmake -GNinja -B $BUILDDIR \
    -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_ROOT/build/cmake/android.toolchain.cmake \
    -DANDROID_ABI=$ABI \
    -DANDROID_NATIVE_API_LEVEL=$API \
    -DANDROID_PLATFORM="android-$API" \
    -DCMAKE_SYSTEM_NAME="Android" \
    -DCMAKE_BUILD_TYPE="Release" \
    -DANDROID_STL="c++_static" \
    -DPROTOC_PATH="$(find $TOOLS_PATH -name protoc-3.9.*)"
[ $? -eq 0 ] || { msg "Configure failed!"; exit 1; }

msg "Building"
ninja -C $BUILDDIR -j$(nproc) || exit 1
[ $? -eq 0 ] || { msg "Building failed!"; exit 1; }

AAPT2=$BUILDDIR/bin/aapt2
ZIPALIGN=$BUILDDIR/bin/zipalign

$CLEAN --api-level $API $AAPT2
$CLEAN --api-level $API $ZIPALIGN
$STRIP --strip-all $AAPT2
$STRIP --strip-all $ZIPALIGN

[ $? -eq 0 ] && { msg "aapt2 and zipalign binary built sucessfully"; }