#!/usr/bin/env bash

PYTHON_VERSION_FAMILY="${PYTHON_VERSION:0:3}"
PYTHON_ARCHIVE="Python-$PYTHON_VERSION.tgz"
PYTHON_SRC_DIR="Python-$PYTHON_VERSION"
PYTHON_MIRROR="${PYTHON_MIRROR:-http://python.org/ftp/python}"
PYTHON_URL="${PYTHON_URL:-$PYTHON_MIRROR/$PYTHON_VERSION/$PYTHON_ARCHIVE}"

SETUPTOOLS_VERSION="3.3"
SETUPTOOLS_ARCHIVE="setuptools-$SETUPTOOLS_VERSION.tar.gz"
SETUPTOOLS_SRC_DIR="setuptools-$SETUPTOOLS_VERSION"
SETUPTOOLS_URL="https://pypi.python.org/packages/source/s/setuptools/setuptools-${SETUPTOOLS_VERSION}.tar.gz"
SETUPTOOLS_MD5="$(fetch "$PYTHON/md5" "$SETUPTOOLS_ARCHIVE")"

PIP_VERSION="1.5.4"
PIP_ARCHIVE="pip-$PIP_VERSION.tar.gz"
PIP_SRC_DIR="pip-$PIP_VERSION"
PIP_URL="https://pypi.python.org/packages/source/p/pip/pip-${PIP_VERSION}.tar.gz"
PIP_MD5="$(fetch "$PYTHON/md5" "$PIP_ARCHIVE")"

if [[ -d "$PYTHON_DIR"/patches/"$PYTHON_VERSION" ]]; then
#	for patch in `find "$PYTHON_DIR"/patches/"$PYTHON_VERSION" -type f -name "*.patch"`; do
#		PATCHES+=("$patch")
#	done
	PATCHES+=(`find "$PYTHON_DIR"/patches/"$PYTHON_VERSION" -type f -name "*.patch"`)
fi

#
# Configures Python.
#
function configure_python()
{
	log "Configuring python $PYTHON_VERSION ..."

	if [[ "$PACKAGE_MANAGER" == "brew" ]]; then
		./configure --prefix="$INSTALL_DIR" \
			    --with-opt-dir="$(brew --prefix openssl):$(brew --prefix readline):$(brew --prefix libyaml):$(brew --prefix gdbm):$(brew --prefix libffi)" \
			    "${CONFIGURE_OPTS[@]}"
	else
		./configure --prefix="$INSTALL_DIR" \
			    "${CONFIGURE_OPTS[@]}"
	fi
}

#
# Compiles Python.
#
function compile_python()
{
	log "Compiling python $PYTHON_VERSION ..."
	make
}

#
# Installs Python into $INSTALL_DIR
#
function install_python()
{
	log "Installing python $PYTHON_VERSION ..."
	make install
}

function post_install()
{
	if [[ -n "$DESTDIR" ]]; then
		log "detected DESTDIR: $DESTDIR"
		PYTHON_INSTALL_DIR=$DESTDIR$INSTALL_DIR
	else
		PYTHON_INSTALL_DIR=$INSTALL_DIR
	fi

	# work around the lack of bin/python in python 3 installs
	if [ ! -f $PYTHON_INSTALL_DIR/bin/python -a -f $PYTHON_INSTALL_DIR/bin/python3 ]; then
		ln -s $PYTHON_INSTALL_DIR/bin/python3 $PYTHON_INSTALL_DIR/bin/python
	fi

	log "Downloading $SETUPTOOLS_URL into $SRC_DIR ..."
	download "$SETUPTOOLS_URL" "$SRC_DIR"

	log "Verifying $SETUPTOOLS_ARCHIVE" "$SETUPTOOLS_MD5"
	verify "$SRC_DIR/$SETUPTOOLS_ARCHIVE" "$SETUPTOOLS_MD5"

	log "Extracting $SETUPTOOLS_ARCHIVE ..."
	extract "$SRC_DIR/$SETUPTOOLS_ARCHIVE"

	log "Installing setuptools $SETUPTOOLS_VERSION"
	cd "$SRC_DIR/$SETUPTOOLS_SRC_DIR"
	$PYTHON_INSTALL_DIR/bin/python ./setup.py build
	$PYTHON_INSTALL_DIR/bin/python ./setup.py install

	log "Downloading $PIP_URL into $SRC_DIR ..."
	download "$PIP_URL" "$SRC_DIR"

	log "Verifying $PIP_ARCHIVE" "$PIP_MD5"
	verify "$SRC_DIR/$PIP_ARCHIVE" "$PIP_MD5"

	log "Extracting $PIP_ARCHIVE ..."
	extract "$SRC_DIR/$PIP_ARCHIVE"

	log "Installing pip $PIP_VERSION"
	cd "$SRC_DIR/$PIP_SRC_DIR"
	$PYTHON_INSTALL_DIR/bin/python ./setup.py build
	$PYTHON_INSTALL_DIR/bin/python ./setup.py install
}
