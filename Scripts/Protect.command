# Protect the copied header files from being modified. This is done in an attempt to avoid
# accidentally editing the copied headers.

# Ignore whitespace characters in paths
IFS=$'\n'

if [ -d "${TARGET_BUILD_DIR}/include/RestKit" ]; then
    cd ${TARGET_BUILD_DIR}/include/RestKit

    find * -name '*.h' | xargs chmod a-w    
else
    echo "Target Build Directory '${TARGET_BUILD_DIR}' do not exist, skipping..."
fi

exit 0
