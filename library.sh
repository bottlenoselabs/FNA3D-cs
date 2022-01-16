#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
echo "Started building native libraries... Directory: $DIR"
LIB_DIR="$DIR/lib"
mkdir -p $LIB_DIR
echo "Started '$0' $1 $2 $3 $4"

if [[ ! -z "$1" ]]; then
    TARGET_BUILD_OS="$1"
fi

if [[ ! -z "$2" ]]; then
    TARGET_BUILD_ARCH="$2"
fi

if [[ ! -z "$3" ]]; then
    SDL_LIBRARY_FILE_PATH="$3"
fi

if [[ ! -z "$4" ]]; then
    SDL_INCLUDE_DIRECTORY_PATH="$4"
fi

function set_target_build_os {
    if [[ -z "$TARGET_BUILD_OS" || $TARGET_BUILD_OS == "host" ]]; then
        uname_str="$(uname -a)"
        case "${uname_str}" in
            *Microsoft*)    TARGET_BUILD_OS="windows";;
            *microsoft*)    TARGET_BUILD_OS="windows";;
            Linux*)         TARGET_BUILD_OS="linux";;
            Darwin*)        TARGET_BUILD_OS="macos";;
            CYGWIN*)        TARGET_BUILD_OS="linux";;
            MINGW*)         TARGET_BUILD_OS="windows";;
            *Msys)          TARGET_BUILD_OS="windows";;
            *)              TARGET_BUILD_OS="UNKNOWN:${uname_str}"
        esac

        if [[
            "$TARGET_BUILD_OS" != "windows" &&
            "$TARGET_BUILD_OS" != "macos" &&
            "$TARGET_BUILD_OS" != "linux"
        ]]; then
            echo "Unknown target build operating system: $TARGET_BUILD_OS"
            exit 1
        fi

        echo "Target build operating system: '$TARGET_BUILD_OS' (host)"
    else
        if [[
            "$TARGET_BUILD_OS" == "windows" ||
            "$TARGET_BUILD_OS" == "macos" ||
            "$TARGET_BUILD_OS" == "linux"
            ]]; then
            echo "Target build operating system: '$TARGET_BUILD_OS' (override)"
        else
            echo "Unknown '$TARGET_BUILD_OS' passed as first argument. Use 'host' to use the host build platform or use either: 'windows', 'macos', 'linux'."
            exit 1
        fi
    fi
}

function set_target_build_arch {
    if [[ -z "$TARGET_BUILD_ARCH" || $TARGET_BUILD_ARCH == "default" ]]; then
        if [[ "$TARGET_BUILD_OS" == "macos" ]]; then
            TARGET_BUILD_ARCH="x86_64;arm64"
        else
            TARGET_BUILD_ARCH="$(uname -m)"
        fi

        echo "Target build CPU architecture: '$TARGET_BUILD_ARCH' (default)"
    else
        if [[ "$TARGET_BUILD_ARCH" == "x86_64" || "$TARGET_BUILD_ARCH" == "arm64" ]]; then
            echo "Target build CPU architecture: '$TARGET_BUILD_ARCH' (override)"
        else
            echo "Unknown '$TARGET_BUILD_ARCH' passed as second argument. Use 'default' to use the host CPU architecture or use either: 'x86_64', 'arm64'."
            exit 1
        fi
    fi
    if [[ "$TARGET_BUILD_OS" == "macos" ]]; then
        CMAKE_ARCH_ARGS="-DCMAKE_OSX_ARCHITECTURES=$TARGET_BUILD_ARCH"
    fi
}

set_target_build_os
set_target_build_arch

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
    elif [[ "$TARGET_BUILD_OS" == "windows" ]]; then
        SDL_LIBRARY_FILE_NAME="SDL2.lib"
        SDL_LIBRARY_FILE_PATH="$LIB_DIR/$SDL_LIBRARY_FILE_NAME"
    elif [[ "$TARGET_BUILD_OS" == "linux" ]]; then
        SDL_LIBRARY_FILE_NAME="libSDL2-2.0.so"
        SDL_LIBRARY_FILE_PATH="$LIB_DIR/$SDL_LIBRARY_FILE_NAME"
    elif [[ "$TARGET_BUILD_OS" == "apple" ]]; then
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
        rm -rf SDL_BUILD_DIR

        cmake -S $DIR/SDL -B $SDL_BUILD_DIR $CMAKE_ARCH_ARGS \
            `#Change output directories` \
            -DCMAKE_ARCHIVE_OUTPUT_DIRECTORY=$SDL_BUILD_DIR -DCMAKE_LIBRARY_OUTPUT_DIRECTORY=$SDL_BUILD_DIR -DCMAKE_RUNTIME_OUTPUT_DIRECTORY=$SDL_BUILD_DIR -DCMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE=$SDL_BUILD_DIR \
            `# project specific` \
            -DSDL_STATIC=OFF -DSDL_TEST=OFF -DSDL_LEAN_AND_MEAN=1
        
        cmake --build $SDL_BUILD_DIR --config Release

        if [[ "$TARGET_BUILD_OS" == "linux" ]]; then
            SDL_LIBRARY_FILE_PATH_BUILD="$(readlink -f $SDL_BUILD_DIR/$SDL_LIBRARY_FILE_NAME)"
        elif [[ "$TARGET_BUILD_OS" == "macos" ]]; then
            SDL_LIBRARY_FILE_PATH_BUILD="$SDL_BUILD_DIR/$SDL_LIBRARY_FILE_NAME"
        elif [[ "$TARGET_BUILD_OS" == "windows" ]]; then
            SDL_LIBRARY_FILE_PATH_BUILD="$SDL_BUILD_DIR/Release/$SDL_LIBRARY_FILE_NAME"
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
    rm -rf FNA3D_BUILD_DIR

    cmake -S $DIR/ext/FNA3D -B $FNA3D_BUILD_DIR $CMAKE_ARCH_ARGS \
        `#Change output directories` \
        -DCMAKE_ARCHIVE_OUTPUT_DIRECTORY=$FNA3D_BUILD_DIR -DCMAKE_LIBRARY_OUTPUT_DIRECTORY=$FNA3D_BUILD_DIR -DCMAKE_RUNTIME_OUTPUT_DIRECTORY=$FNA3D_BUILD_DIR -DCMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE=$FNA3D_BUILD_DIR \
        `# project specific` \
        -DSDL2_INCLUDE_DIRS="$SDL_INCLUDE_DIRECTORY_PATH" -DSDL2_LIBRARIES="$SDL_LIBRARY_FILE_PATH"
    cmake --build $FNA3D_BUILD_DIR --config Release

    if [[ "$TARGET_BUILD_OS" == "linux" ]]; then
        FNA3D_LIBRARY_FILENAME="libFNA3D.so"
        FNA3D_LIBRARY_FILE_PATH_BUILD="$(readlink -f $FNA3D_BUILD_DIR/$FNA3D_LIBRARY_FILENAME)"
    elif [[ "$TARGET_BUILD_OS" == "macos" ]]; then
        FNA3D_LIBRARY_FILENAME="libFNA3D.dylib"
        FNA3D_LIBRARY_FILE_PATH_BUILD="$(perl -MCwd -e 'print Cwd::abs_path shift' $FNA3D_BUILD_DIR/$FNA3D_LIBRARY_FILENAME)"
    elif [[ "$TARGET_BUILD_OS" == "windows" ]]; then
        FNA3D_LIBRARY_FILENAME="FNA3D.dll"
        FNA3D_LIBRARY_FILE_PATH_BUILD="$FNA3D_BUILD_DIR/$FNA3D_LIBRARY_FILENAME"
    fi
    FNA3D_LIBRARY_FILE_PATH="$LIB_DIR/$FNA3D_LIBRARY_FILENAME"

    if [[ ! -f "$FNA3D_LIBRARY_FILE_PATH_BUILD" ]]; then
        echo "The file '$FNA3D_LIBRARY_FILE_PATH_BUILD' does not exist!"
        exit 1
    fi

    if [[ "$TARGET_BUILD_OS" == "macos" ]]; then
        install_name_tool -delete_rpath "$(dirname $SDL_LIBRARY_FILE_PATH)" $FNA3D_LIBRARY_FILE_PATH_BUILD
        install_name_tool -change @rpath/libSDL2-2.0.dylib @executable_path/libSDL2.dylib $FNA3D_LIBRARY_FILE_PATH_BUILD
    fi

    mv "$FNA3D_LIBRARY_FILE_PATH_BUILD" "$FNA3D_LIBRARY_FILE_PATH"
    exit_if_last_command_failed
    echo "Copied '$FNA3D_LIBRARY_FILE_PATH_BUILD' to '$FNA3D_LIBRARY_FILE_PATH'"
`
    rm -rf $FNA3D_BUILD_DIR`
    exit_if_last_command_failed
    echo "Building FNA3D finished!"
}

build_sdl
build_fna3d
ls -d "$LIB_DIR"/*

echo "Finished '$0'!"