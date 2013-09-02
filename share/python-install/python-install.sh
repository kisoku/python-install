#!/usr/bin/env bash

shopt -s extglob

PYTHON_INSTALL_VERSION="0.0.1"
PYTHON_INSTALL_DIR="${BASH_SOURCE[0]%/*}"

PYTHONS=(python)
PATCHES=()
CONFIGURE_OPTS=()

#
# Auto-detect the package manager.
#
if   command -v apt-get >/dev/null; then PACKAGE_MANAGER="apt"
elif command -v yum     >/dev/null; then PACKAGE_MANAGER="yum"
elif command -v brew    >/dev/null; then PACKAGE_MANAGER="brew"
elif command -v pacman  >/dev/null; then PACKAGE_MANAGER="pacman"
fi

#
# Auto-detect the downloader.
#
if   command -v wget >/dev/null; then DOWNLOADER="wget"
elif command -v curl >/dev/null; then DOWNLOADER="curl"
fi

#
# Auto-detect the md5 utility.
#
if   command -v md5sum >/dev/null; then MD5SUM="md5sum"
elif command -v md5    >/dev/null; then MD5SUM="md5"
fi

#
# Only use sudo if already root.
#
if (( $UID == 0 )); then SUDO=""
else                     SUDO="sudo"
fi

#
# Prints a log message.
#
function log()
{
	if [[ -t 1 ]]; then
		echo -e "\x1b[1m\x1b[32m>>>\x1b[0m \x1b[1m\x1b[37m$1\x1b[0m"
	else
		echo ">>> $1"
	fi
}

#
# Prints a warn message.
#
function warn()
{
	if [[ -t 1 ]]; then
		echo -e "\x1b[1m\x1b[33m***\x1b[0m \x1b[1m\x1b[37m$1\x1b[0m" >&2
	else
		echo "*** $1" >&2
	fi
}

#
# Prints an error message.
#
function error()
{
	if [[ -t 1 ]]; then
		echo -e "\x1b[1m\x1b[31m!!!\x1b[0m \x1b[1m\x1b[37m$1\x1b[0m" >&2
	else
		echo "!!! $1" >&2
	fi
}

#
# Prints an error message and exists with -1.
#
function fail()
{
	error "$*"
	exit -1
}

#
# Searches a file for a key and echos the value.
# If the key cannot be found, the third argument will be echoed.
#
function fetch()
{
	local file="$PYTHON_INSTALL_DIR/$1.txt"
	local key="$2"
	local pair="$(grep -E "^$key: " "$file")"

	echo "${pair##$key:*( )}"
}

function install_packages()
{
	case "$PACKAGE_MANAGER" in
		apt)	$SUDO apt-get install -y $* ;;
		yum)	$SUDO yum install -y $*     ;;
		brew)
			local brew_owner="$(/usr/bin/stat -f %Su "$(command -v brew)")"
			sudo -u "$brew_owner" brew install $*
			;;
		pacman)
			local missing_pkgs="$(pacman -T $*)"

			if [[ -n "$missing_pkgs" ]]; then
				$SUDO pacman -S $missing_pkgs
			fi
			;;
		"")	warn "Could not determine Package Manager. Proceeding anyways." ;;
	esac
}

#
# Downloads a URL.
#
function download()
{
	local url="$1"
	local dest="$2"

	if [[ -d "$dest" ]]; then
		dest="$dest/${url##*/}"
	fi

	case "$DOWNLOADER" in
		wget) wget -c -O "$dest" "$url"      ;;
		curl) curl -L -C - -o "$dest" "$url" ;;
		"")
			error "Could not find wget or curl"
			return 1
			;;
	esac
}

#
# Verifies a file against a md5 checksum.
#
function verify()
{
	local path="$1"
	local md5="$2"

	if [[ -z "$MD5SUM" ]]; then
		error "Unable to find the md5 checksum utility"
		return 1
	fi

	if [[ -z "$md5" ]]; then
		error "No md5 checksum given"
		return 1
	fi

	if [[ "$($MD5SUM "$path")" != *$md5* ]]; then
		error "$path is invalid!"
		return 1
	fi
}

#
# Extracts an archive.
#
function extract()
{
	local archive="$1"
	local dest="${2:-${archive%/*}}"

	case "$archive" in
		*.tgz|*.tar.gz)		tar -xzf "$archive" -C "$dest" ;;
		*.tbz|*.tbz2|*.tar.bz2)	tar -xjf "$archive" -C "$dest" ;;
		*.zip)			unzip "$archive" -d "$dest" ;;
		*)
			error "Unknown archive format: $archive"
			return 1
			;;
	esac
}

#
# Loads function.sh for the given Python.
#
function load_python()
{
	PYTHON_DIR="$PYTHON_INSTALL_DIR/$PYTHON"

	if [[ ! -d "$PYTHON_DIR" ]]; then
		echo "python-install: unsupported python: $PYTHON" >&2
		return 1
	fi

	local expanded_version="$(fetch "$PYTHON/versions" "$PYTHON_VERSION")"
	PYTHON_VERSION="${expanded_version:-$PYTHON_VERSION}"

	source "$PYTHON_INSTALL_DIR/functions.sh"
	source "$PYTHON_DIR/functions.sh"

	PYTHON_MD5="${PYTHON_MD5:-$(fetch "$PYTHON/md5" "$PYTHON_ARCHIVE")}"
}

#
# Prints Pythons supported by python-install.
#
function known_pythons()
{
	echo "Known python versions:"

	for python in ${PYTHONS[@]}; do
		echo "  $python:"
		cat "$PYTHON_INSTALL_DIR/$python/versions.txt" | sed -e 's/^/    /'
	done
}

#
# Prints usage information for python-install.
#
function usage()
{
	cat <<USAGE
usage: python-install [OPTIONS] [PYTHON [VERSION]] [-- CONFIGURE_OPTS ...]

Options:

	-s, --src-dir DIR	Directory to download source-code into
	-i, --install-dir DIR	Directory to install Python into
	-p, --patch FILE	Patch to apply to the Python source-code
	-M, --mirror URL	Alternate mirror to download the Python archive from
	-u, --url URL		Alternate URL to download the Python archive from
	-m, --md5 MD5		MD5 checksum of the Python archive
	--no-download		Use the previously downloaded Python archive
	--no-verify		Do not verify the downloaded Python archive
	--no-install-deps	Do not install build dependencies before installing Python
	--no-reinstall  	Skip installation if another Python is detected in same location
	-V, --version		Prints the version
	-h, --help		Prints this message

Examples:

	$ python-install python
	$ python-install python 2.7.5

USAGE
}

#
# Parses command-line options for python-install.
#
function parse_options()
{
	local argv=()

	while [[ $# -gt 0 ]]; do
		case $1 in
			-i|--install-dir)
				INSTALL_DIR="$2"
				shift 2
				;;
			-s|--src-dir)
				SRC_DIR="$2"
				shift 2
				;;
			-p|--patch)
				PATCHES+=("$2")
				shift 2
				;;
			-M|--mirror)
				PYTHON_MIRROR="$2"
				shift 2
				;;
			-u|--url)
				PYTHON_URL="$2"
				shift 2
				;;
			-m|--md5)
				PYTHON_MD5="$2"
				shift 2
				;;
			--no-download)
				NO_DOWNLOAD=1
				shift
				;;
			--no-verify)
				NO_VERIFY=1
				shift
				;;
			--no-install-deps)
				NO_INSTALL_DEPS=1
				shift
				;;
			--no-reinstall)
				NO_REINSTALL=1
				shift
				;;
			-V|--version)
				echo "python-install: $PYTHON_INSTALL_VERSION"
				exit
				;;
			-h|--help)
				usage
				exit
				;;
			--)
				shift
				CONFIGURE_OPTS=("$@")
				break
				;;
			-*)
				echo "python-install: unrecognized option $1" >&2
				return 1
				;;
			*)
				argv+=($1)
				shift
				;;
		esac
	done

	case ${#argv[*]} in
		2)
			PYTHON="${argv[0]}"
			PYTHON_VERSION="${argv[1]}"
			;;
		1)
			PYTHON="${argv[0]}"
			PYTHON_VERSION="stable"
			;;
		0)
			echo "python-install: too few arguments" >&2
			usage 1>&2
			return 1
			;;
		*)
			echo "python-install: too many arguments: ${argv[*]}" >&2
			usage 1>&2
			return 1
			;;
	esac
}
