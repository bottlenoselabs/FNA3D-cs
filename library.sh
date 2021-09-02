#!/bin/bash
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
uname_str="$(uname | tr '[:upper:]' '[:lower:]')"
echo "Started building native libraries... OS: $uname_str, Directory: $script_dir"

if [[ ! -z "$1" ]]; then
    sdl_library_file_path="$1"
elif [[ "$uname_str" == "linux" ]]; then
    sdl_library_file_path="$script_dir/lib/libSDL2-2.0.so"
elif [[ "$uname_str" == "darwin" ]]; then
    sdl_library_file_path="$script_dir/lib/libSDL2-2.0.dylib"
fi

if [[ ! -z "$2" ]]; then
    sdl_include_directory_path="$2"
elif [ ! -d "$script_dir/SDL" ]; then
    git clone https://github.com/libsdl-org/SDL $script_dir/SDL
    sdl_include_directory_path="$script_dir/SDL/include"
else
    cd $script_dir/SDL
    git pull
    cd $script_dir
    sdl_include_directory_path="$script_dir/SDL/include"
fi

if [ ! -f "$sdl_library_file_path" ]; then
    build_dir_sdl="$script_dir/cmake-build-release-sdl"
    cmake -S $script_dir/SDL -B $build_dir_sdl
    cmake --build $build_dir_sdl --config Release
    if [[ "$uname_str" == "linux" ]]; then
        shared_object_path="$(readlink -f $build_dir_sdl/libSDL2-2.0.so)"
        mv "$shared_object_path" "$sdl_library_file_path"
    elif [[ "$uname_str" == "darwin" ]]; then
        shared_object_path="$build_dir_sdl/libSDL2-2.0.dylib"
        mv "$shared_object_path" "$sdl_library_file_path"
    fi
    rm -r $build_dir_sdl
    rm -r $script_dir/SDL
fi

build_dir="$script_dir/cmake-build-release-fna3d"
lib_dir="$script_dir/lib/"

cmake -S $script_dir/ext/FNA3D -B $build_dir -DSDL2_INCLUDE_DIRS="$sdl_include_directory_path" -DSDL2_LIBRARIES="$sdl_library_file_path"
cmake --build $build_dir --config Release
mkdir -p $lib_dir

filepath="$(perl -MCwd -e 'print Cwd::abs_path shift' $build_dir/libFNA3D.dylib)"
if [[ "$uname_str" == "linux" ]]; then
    mv "$filepath" "$lib_dir/libFNA3D.so"
elif [[ "$uname_str" == "darwin" ]]; then
    mv "$filepath" "$lib_dir/libFNA3D.dylib"
    install_name_tool -delete_rpath "$script_dir/lib" "$lib_dir/libFNA3D.dylib"
fi

rm -r $build_dir
echo "Finished building native libraries."