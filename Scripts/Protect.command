# Protect the copied header files from being modified. This is done in an attempt to avoid
# accidentally editing the copied headers.

# Ignore whitespace characters in paths
IFS=$'\n'

cd ${CONFIGURATION_BUILD_DIR}/${PUBLIC_HEADERS_FOLDER_PATH}

find * -name '*.h' | xargs chmod a-w

exit 0
