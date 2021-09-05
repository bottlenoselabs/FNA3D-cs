#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
LIB_DIR="$DIR/lib"
mkdir -p $LIB_DIR

if [[ ! -z "$1" ]]; then
    BUILD_PLATFORM="$1"
fi
if [[ ! -z "$2" ]]; then
    SDL_LIBRARY_FILE_PATH="$2"
fi
if [[ ! -z "$3" ]]; then
    SDL_INCLUDE_DIRECTORY_PATH="$3"
fi

echo "Started '$0'"

function set_target_build_platform_host() {
    uname_str="$(uname -a)"
    case "${uname_str}" in
        *Microsoft*)    TARGET_BUILD_PLATFORM="microsoft";;
        *microsoft*)    TARGET_BUILD_PLATFORM="microsoft";;
        Linux*)         TARGET_BUILD_PLATFORM="linux";;
        Darwin*)        TARGET_BUILD_PLATFORM="apple";;
        CYGWIN*)        TARGET_BUILD_PLATFORM="linux";;
        MINGW*)         TARGET_BUILD_PLATFORM="microsoft";;
        *Msys)          TARGET_BUILD_PLATFORM="microsoft";;
        *)              TARGET_BUILD_PLATFORM="UNKNOWN:${uname_str}"
    esac
}

function set_target_build_platform {
    if [[ ! -z "$TARGET_BUILD_PLATFORM" ]]; then
        if [[ $TARGET_BUILD_PLATFORM == "default" ]]; then
            set_target_build_platform_host
            echo "Build platform: '$TARGET_BUILD_PLATFORM' (host default)"
        else
            if [[ "$TARGET_BUILD_PLATFORM" == "microsoft" || "$TARGET_BUILD_PLATFORM" == "linux" || "$TARGET_BUILD_PLATFORM" == "apple" ]]; then
                echo "Build platform: '$TARGET_BUILD_PLATFORM' (cross-compile override)"
            else
                echo "Unknown '$TARGET_BUILD_PLATFORM' passed as first argument. Use 'default' to use the host build platform."
                exit 1
            fi
        fi
    else
        set_target_build_platform_host
        echo "Build platform: '$TARGET_BUILD_PLATFORM' (host default)"
    fi
}

set_target_build_platform
if [[ "$TARGET_BUILD_PLATFORM" == "microsoft" ]]; then
    CMAKE_TOOLCHAIN_ARGS="-DCMAKE_TOOLCHAIN_FILE=$DIR/mingw-w64-x86_64.cmake"
elif [[ "$TARGET_BUILD_PLATFORM" == "linux" ]]; then
    CMAKE_TOOLCHAIN_ARGS=""
elif [[ "$TARGET_BUILD_PLATFORM" == "apple" ]]; then
    CMAKE_TOOLCHAIN_ARGS=""
else
    echo "Unknown: $TARGET_BUILD_PLATFORM"
    exit 1
fi

function exit_if_last_command_failed() {
    error=$?
    if [ $error -ne 0 ]; then
        echo "Last command failed: $error"
        exit $error
    fi
}

function build_sdl() {
    echo "Building SDL..."

    if [[ ! -z "$SDL_LIBRARY_FILE_PATH" ]]; then
        SDL_LIBRARY_FILE_NAME="$(dirname SDL_LIBRARY_FILE_PATH)"
        if [ ! -f "$SDL_LIBRARY_FILE_PATH" ]; then
            echo "Custom SDL library path '$SDL_LIBRARY_FILE_PATH' does not exist!"
        else
            echo "Using custom SDL library path: $SDL_LIBRARY_FILE_PATH"
        fi
    elif [[ "$TARGET_BUILD_PLATFORM" == "microsoft" ]]; then
        SDL_LIBRARY_FILE_NAME="SDL2.dll"
        SDL_LIBRARY_FILE_PATH="$LIB_DIR/$SDL_LIBRARY_FILE_NAME"
    elif [[ "$TARGET_BUILD_PLATFORM" == "linux" ]]; then
        SDL_LIBRARY_FILE_NAME="libSDL2-2.0.so"
        SDL_LIBRARY_FILE_PATH="$LIB_DIR/$SDL_LIBRARY_FILE_NAME"
    elif [[ "$TARGET_BUILD_PLATFORM" == "apple" ]]; then
        SDL_LIBRARY_FILE_NAME="libSDL2-2.0.dylib"
        SDL_LIBRARY_FILE_PATH="$LIB_DIR/$SDL_LIBRARY_FILE_NAME"
    fi

    if [[ ! -z "$SDL_INCLUDE_DIRECTORY_PATH" ]]; then
        if [ ! -d "$SDL_INCLUDE_DIRECTORY_PATH" ]; then
            echo "Custom SDL include path '$SDL_INCLUDE_DIRECTORY_PATH' does not exist!"
        else
            echo "Using custom SDL include path: $SDL_INCLUDE_DIRECTORY_PATH"
        fi
    elif [ ! -d "$DIR/SDL" ]; then
        git clone https://github.com/libsdl-org/SDL $DIR/SDL
        SDL_INCLUDE_DIRECTORY_PATH="$DIR/SDL/include"
        echo "Using SDL include path from clone: $SDL_INCLUDE_DIRECTORY_PATH"
    else
        cd $DIR/SDL
        git pull
        cd $DIR
        SDL_INCLUDE_DIRECTORY_PATH="$DIR/SDL/include"
        echo "Using SDL include path from clone: $SDL_INCLUDE_DIRECTORY_PATH"
    fi

    if [ ! -f "$SDL_LIBRARY_FILE_PATH" ]; then
        SDL_BUILD_DIR="$DIR/cmake-build-release-sdl"
        cmake $CMAKE_TOOLCHAIN_ARGS -S $DIR/SDL -B $SDL_BUILD_DIR -DSDL_STATIC=OFF -DSDL_TEST=OFF
        cmake --build $SDL_BUILD_DIR --config Release

        if [[ "$TARGET_BUILD_PLATFORM" == "linux" ]]; then
            SDL_LIBRARY_FILE_PATH_BUILD="$(readlink -f $SDL_BUILD_DIR/$SDL_LIBRARY_FILE_NAME)"
        elif [[ "$TARGET_BUILD_PLATFORM" == "apple" ]]; then
            SDL_LIBRARY_FILE_PATH_BUILD="$SDL_BUILD_DIR/$SDL_LIBRARY_FILE_NAME"
        elif [[ "$TARGET_BUILD_PLATFORM" == "microsoft" ]]; then
            SDL_LIBRARY_FILE_PATH_BUILD="$SDL_BUILD_DIR/$SDL_LIBRARY_FILE_NAME"
        fi

        if [[ ! -f "$SDL_LIBRARY_FILE_PATH_BUILD" ]]; then
            echo "The file '$SDL_LIBRARY_FILE_PATH_BUILD' does not exist!"
            exit 1
        fi

        mv "$SDL_LIBRARY_FILE_PATH_BUILD" "$SDL_LIBRARY_FILE_PATH"
        exit_if_last_command_failed
        echo "Copied '$SDL_LIBRARY_FILE_PATH_BUILD' to '$SDL_LIBRARY_FILE_PATH'"

        rm -rf $SDL_BUILD_DIR
        exit_if_last_command_failed
    fi

    echo "Building SDL complete!"
}

function build_fna3d() {
    echo "Building FNA3D..."
    FNA3D_BUILD_DIR="$DIR/cmake-build-release-fna3d"
    cmake $CMAKE_TOOLCHAIN_ARGS -S $DIR/ext/FNA3D -B $FNA3D_BUILD_DIR -DSDL2_INCLUDE_DIRS="$SDL_INCLUDE_DIRECTORY_PATH" -DSDL2_LIBRARIES="$SDL_LIBRARY_FILE_PATH"
    cmake --build $FNA3D_BUILD_DIR --config Release

    if [[ "$TARGET_BUILD_PLATFORM" == "linux" ]]; then
        FNA3D_LIBRARY_FILENAME="libFNA3D.so"
        FNA3D_LIBRARY_FILE_PATH_BUILD="$(readlink -f $FNA3D_BUILD_DIR/$FNA3D_LIBRARY_FILENAME)"
    elif [[ "$TARGET_BUILD_PLATFORM" == "apple" ]]; then
        FNA3D_LIBRARY_FILENAME="libFNA3D.dylib"
        FNA3D_LIBRARY_FILE_PATH_BUILD="$FNA3D_BUILD_DIR/$FNA3D_LIBRARY_FILENAME"
    elif [[ "$TARGET_BUILD_PLATFORM" == "microsoft" ]]; then
        FNA3D_LIBRARY_FILENAME="FNA3D.dll"
        FNA3D_LIBRARY_FILE_PATH_BUILD="$FNA3D_BUILD_DIR/$FNA3D_LIBRARY_FILENAME"
    fi
    FNA3D_LIBRARY_FILE_PATH="$LIB_DIR/$FNA3D_LIBRARY_FILENAME"

    if [[ ! -f "$FNA3D_LIBRARY_FILE_PATH_BUILD" ]]; then
        echo "The file '$FNA3D_LIBRARY_FILE_PATH_BUILD' does not exist!"
        exit 1
    fi

    mv "$FNA3D_LIBRARY_FILE_PATH_BUILD" "$FNA3D_LIBRARY_FILE_PATH"
    exit_if_last_command_failed
    echo "Copied '$FNA3D_LIBRARY_FILE_PATH_BUILD' to '$FNA3D_LIBRARY_FILE_PATH'"

    rm -r $FNA3D_BUILD_DIR
    exit_if_last_command_failed
    echo "Building FNA3D finished!"
}

build_sdl
build_fna3d
ls -d "$LIB_DIR"/*

echo "Finished '$0'!"