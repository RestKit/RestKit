# This script copies the headers from the configuration
# build directory to their legacy location at Build/RestKit
# under the project root. This is the include path for Xcode
# 3 projects and Xcode 4 projects not using derived data

IFS=$'\n'
if [ -d "${CONFIGURATION_BUILD_DIR}/include/RestKit" ]; then
    rsync -av --delete "${CONFIGURATION_BUILD_DIR}/include/RestKit" "${SOURCE_ROOT}/Build"
else
    echo "Configuration include path does not exist, likely perform a Build & Archive operation..."
fi
