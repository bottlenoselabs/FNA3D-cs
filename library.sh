#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
uname_str="$(uname -a)"
case "${uname_str}" in
    *Microsoft*)    OS="Microsoft";;
    *microsoft*)    OS="Microsoft";;
    Linux*)         OS="Linux";;
    Darwin*)        OS="Apple";;
    CYGWIN*)        OS="Linux";;
    MINGW*)         OS="Microsoft";;
    *Msys)          OS="Microsoft";;
    *)              OS="UNKNOWN:${uname_str}"
esac
if [[ "$OS" == "Microsoft" ]]; then
    CMAKE_TOOLCHAIN_ARGS="-DCMAKE_TOOLCHAIN_FILE=$DIR/mingw-w64-x86_64.cmake"
elif [[ "$OS" == "Linux" ]]; then
    CMAKE_TOOLCHAIN_ARGS=""
elif [[ "$OS" == "Apple" ]]; then
    CMAKE_TOOLCHAIN_ARGS=""
fi

echo "Started building native libraries... OS: $OS, Directory: $DIR"

if [[ ! -z "$1" ]]; then
    echo "Using custom SDL library path: $1"
    sdl_library_file_path="$1"
elif [[ "$OS" == "Microsoft" ]]; then
    sdl_library_file_path="$DIR/lib/SDL2.dll"
elif [[ "$OS" == "Linux" ]]; then
    sdl_library_file_path="$DIR/lib/libSDL2-2.0.so"
elif [[ "$OS" == "Apple" ]]; then
    sdl_library_file_path="$DIR/lib/libSDL2-2.0.dylib"
fi

if [[ ! -z "$2" ]]; then
    echo "Using custom SDL include path: $2"
    sdl_include_directory_path="$2"
elif [ ! -d "$DIR/SDL" ]; then
    echo "Using SDL include path from clone"
    git clone https://github.com/libsdl-org/SDL $DIR/SDL
    sdl_include_directory_path="$DIR/SDL/include"
else
    echo "Using SDL include path from clone"
    cd $DIR/SDL
    git pull
    cd $DIR
    sdl_include_directory_path="$DIR/SDL/include"
fi

if [ ! -f "$sdl_library_file_path" ]; then
    build_dir_sdl="$DIR/cmake-build-release-sdl"
    cmake $CMAKE_TOOLCHAIN_ARGS -S $DIR/SDL -B $build_dir_sdl -DSDL_STATIC=OFF
    cmake --build $build_dir_sdl --config Release
    if [[ "$OS" == "Linux" ]]; then
        shared_object_path="$(readlink -f $build_dir_sdl/libSDL2-2.0.so)"
        mv "$shared_object_path" "$sdl_library_file_path"
    elif [[ "$OS" == "Apple" ]]; then
        shared_object_path="$build_dir_sdl/libSDL2-2.0.dylib"
        mv "$shared_object_path" "$sdl_library_file_path"
    elif [[ "$OS" == "Microsoft" ]]; then
        shared_object_path="$build_dir_sdl/SDL2.dll"
        mv "$shared_object_path" "$sdl_library_file_path"
    fi
    rm -r $build_dir_sdl
    rm -r $DIR/SDL
fi

build_dir="$DIR/cmake-build-release-fna3d"
lib_dir="$DIR/lib"

cmake $CMAKE_TOOLCHAIN_ARGS -S $DIR/ext/FNA3D -B $build_dir -DSDL2_INCLUDE_DIRS="$sdl_include_directory_path" -DSDL2_LIBRARIES="$sdl_library_file_path"
cmake --build $build_dir --config Release
mkdir -p $lib_dir

if [[ "$OS" == "Linux" ]]; then
    filepath="$(perl -MCwd -e 'print Cwd::abs_path shift' $build_dir/libFNA3D.so)"
    mv "$filepath" "$lib_dir/libFNA3D.so"
elif [[ "$OS" == "Apple" ]]; then
    filepath="$(perl -MCwd -e 'print Cwd::abs_path shift' $build_dir/libFNA3D.dylib)"
    mv "$filepath" "$lib_dir/libFNA3D.dylib"
    lc_rpath="$(dirname $sdl_library_file_path)"
    install_name_tool -delete_rpath "$lc_rpath" "$lib_dir/libFNA3D.dylib"
elif [[ "$OS" == "Microsoft" ]]; then
    filepath="$(perl -MCwd -e 'print Cwd::abs_path shift' $build_dir/FNA3D.dll)"
    mv "$filepath" "$lib_dir/FNA3D.dll"
fi

rm -r $build_dir
echo "Finished building native libraries."