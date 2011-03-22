# Protect the copied header files from being modified. This is done in an attempt to avoid
# accidentally editing the copied headers.

# Ignore whitespace characters in paths
IFS=$'\n'

if [ -d "${CONFIGURATION_BUILD_DIR}/include/RestKit" ]; then
    cd ${CONFIGURATION_BUILD_DIR}/include/RestKit

    find * -name '*.h' | xargs chmod a-w    
else
    echo "Configuration include path does not exist, likely perform a Build & Archive operation..."
fi

exit 0
