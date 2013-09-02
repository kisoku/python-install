if (( $UID == 0 )); then
	SRC_DIR="${SRC_DIR:-/usr/local/src}"
	INSTALL_DIR="${INSTALL_DIR:-/opt/pythons/$PYTHON-$PYTHON_VERSION}"
else
	SRC_DIR="${SRC_DIR:-$HOME/src}"
	INSTALL_DIR="${INSTALL_DIR:-$HOME/.pythons/$PYTHON-$PYTHON_VERSION}"
fi

#
# Pre-install tasks
#
function pre_install()
{
	mkdir -p "$SRC_DIR"
	mkdir -p "${INSTALL_DIR%/*}"
}

#
# Install Python Dependencies
#
function install_deps()
{
	local packages="$(fetch "$PYTHON/dependencies" "$PACKAGE_MANAGER")"

	if [[ -n "$packages" ]]; then
		log "Installing dependencies for $PYTHON $PYTHON_VERSION ..."
		install_packages $packages
	fi

	install_optional_deps
}

#
# Install any optional dependencies.
#
function install_optional_deps() { return; }

#
# Download the Python archive
#
function download_python()
{
	log "Downloading $PYTHON_URL into $SRC_DIR ..."
	download "$PYTHON_URL" "$SRC_DIR/$PYTHON_ARCHIVE"
}

#
# Verifies the Python archive matches a checksum.
#
function verify_python()
{
	if [[ -n "$PYTHON_MD5" ]]; then
		log "Verifying $PYTHON_ARCHIVE ..."
		verify "$SRC_DIR/$PYTHON_ARCHIVE" "$PYTHON_MD5"
	else
		warn "No checksum for $PYTHON_ARCHIVE. Proceeding anyways"
	fi
}

#
# Extract the Python archive
#
function extract_python()
{
	log "Extracting $PYTHON_ARCHIVE ..."
	extract "$SRC_DIR/$PYTHON_ARCHIVE" "$SRC_DIR"
}

#
# Download any additional patches
#
function download_patches()
{
	local dest
	for patch in "${PATCHES[@]}"; do
		if [[ "$patch" == http:\/\/* || "$patch" == https:\/\/* ]]; then
			log "Downloading patch $patch ..."
			dest="$SRC_DIR/$PYTHON_SRC_DIR/${patch##*/}"
			download "$patch" "$dest"
		fi
	done
}

#
# Apply any additional patches
#
function apply_patches()
{
	local name

	for patch in "${PATCHES[@]}"; do
		name="${patch##*/}"
		log "Applying patch $name ..."

		if [[ "$patch" == http:\/\/* || "$patch" == https:\/\/* ]]; then
			patch="$SRC_DIR/$PYTHON_SRC_DIR/$name"
		fi

		patch -p1 -d "$SRC_DIR/$PYTHON_SRC_DIR" < "$patch"
	done
}

#
# Place holder function for configuring Python.
#
function configure_python() { return; }

#
# Place holder function for compiling Python.
#
function compile_python() { return; }

#
# Place holder function for installing Python.
#
function install_python() { return; }

#
# Place holder function for post-install tasks.
#
function post_install() { return; }
