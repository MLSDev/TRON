#!/bin/bash

set -eo pipefail

# Install gems in the user directory because the default install directory
# is in a read-only location.
export GEM_HOME=$HOME/.gem
export PATH=$GEM_HOME/bin:$PATH

python3 -m pip install git+https://github.com/googleapis/releasetool
python3 -m pip install gcp-docuploader
gem install --no-document toys
bundle install

python3 -m releasetool publish-reporter-script > /tmp/publisher-script; source /tmp/publisher-script

toys kokoro publish-gem < /dev/null
toys kokoro publish-docs < /dev/null
