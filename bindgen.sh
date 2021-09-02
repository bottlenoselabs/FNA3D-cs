#!/bin/bash

function exit_if_last_command_failed() {
    error=$?
    if [ $error -ne 0 ]; then
        exit $error
    fi
}

function download_C2CS_ubuntu() {
    if [ ! -f "./C2CS" ]; then
        wget https://nightly.link/lithiumtoast/c2cs/workflows/build-test-deploy/develop/ubuntu.20.04-x64.zip
        unzip ./ubuntu.20.04-x64.zip
        rm ./ubuntu.20.04-x64.zip
        chmod +x ./C2CS
    fi
}

function download_C2CS_osx() {
    if [ ! -f "./C2CS" ]; then
        wget https://nightly.link/lithiumtoast/c2cs/workflows/build-test-deploy/develop/osx-x64.zip
        unzip ./osx-x64.zip
        rm ./osx-x64.zip
        chmod +x ./C2CS
    fi
}

function bindgen {
    ./C2CS ast -i ./ext/FNA3D/include/FNA3D.h -o ./ast/FNA3D.json -s ./ext/FNA3D/include
    exit_if_last_command_failed
    ./C2CS cs -i ./ast/FNA3D.json -o ./src/cs/production/FNA3D-cs/FNA3D.cs -l "FNA3D" -c "FNA3D"
    exit_if_last_command_failed
    ./C2CS ast -i ./ext/FNA3D/include/FNA3D_Image.h -o ./ast/FNA3D_Image.json -s ./ext/FNA3D/include
    exit_if_last_command_failed
    ./C2CS cs -i ./ast/FNA3D_Image.json -o ./src/cs/production/FNA3D-cs/FNA3D_Image.cs -l "FNA3D" -c "FNA3D_Image"
    exit_if_last_command_failed
}

unamestr="$(uname | tr '[:upper:]' '[:lower:]')"
if [[ "$unamestr" == "linux" ]]; then
    download_C2CS_ubuntu
    bindgen
elif [[ "$unamestr" == "darwin" ]]; then
    download_C2CS_osx
    bindgen
else
    echo "Unknown platform: '$unamestr'."
fi
