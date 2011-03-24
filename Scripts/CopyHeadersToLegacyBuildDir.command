# This script copies the headers from the configuration
# build directory to their legacy location at Build/RestKit
# under the project root. This is the include path for Xcode
# 3 projects and Xcode 4 projects not using derived data

IFS=$'\n'
if [ -d "${TARGET_BUILD_DIR}/include/RestKit" ]; then
    rsync -av --delete "${TARGET_BUILD_DIR}/include/RestKit" "${SOURCE_ROOT}/Build"
else
    echo "Target Build Directory '${TARGET_BUILD_DIR}' do not exist, skipping..."
fi
