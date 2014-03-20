# python-install

Installs [Python]

## Features

* Supports installing arbitrary versions.
* Supports installing into `/opt/pythons/` for root and `~/.pythons/` for users
  by default.
* Supports installing into arbitrary directories.
* Supports downloading from mirrors.
* Supports downloading/applying patches.
* Supports applying arbitrary patches.
* Supports specifying arbitrary `./configure` options.
* Supports downloading archives using `wget` or `curl`.
* Supports verifying downloaded archives using `md5sum` or `md5`.
* Supports installing build dependencies via the package manager:
  * [apt]
  * [yum]
  * [pacman]
  * [brew]
* Has tests.

## Anti-Features

* Does not require updating every time a new Python version comes out.
* Does not require recipes for each individual Python version or configuration.

## Requirements

* [bash]
* [wget] or [curl]
* `md5sum` or `md5`
* `tar`

## Synopsis

Install the current stable version of Python:

    $ python-install python

Install a latest version of Python:

    $ python-install python 2

Install a specific version of Python:

    $ python-install python 2.7.8

Install a Python into a specific directory:

    $ python-install -i /usr/local/ python 2.7.8

[apt]: http://wiki.debian.org/Apt
[yum]: http://yum.baseurl.org/
[pacman]: https://wiki.archlinux.org/index.php/Pacman
[brew]: http://mxcl.github.com/homebrew/

[bash]: http://www.gnu.org/software/bash/
[wget]: http://www.gnu.org/software/wget/
[curl]: http://curl.haxx.se/

[ruby-install]: https://github.com/postmodern/ruby-install#readme
[pyenv]: https://github.com/yyuu/pyenv#readme
