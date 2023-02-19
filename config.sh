#!/bin/bash


# mirror_store is the location where all mirrors are stored.
# it is created if it doesn't exist.
# the mirrors are stored in a repo named after the name set above.
# The Path should end without a slash.
#mirror_store="/tmp/tmp.YGxnWmAoIw/mirror"

# set the git path
git_path=git

# active must contain all mirror configs that should be mirrored.
# the name doesn't need to be the repo name.
# names are separated by space.
# only characters allowed that can be used as bash variable
active=("gitmirror")

# the origin must start with the name specified above followed by
# _origin.
# test_origin for example would be mirrored if test is set as
# active.
gitmirror_origin="git@codeberg.org:FlorianKutzer/gitmirror.git"

# test_clone specifies the desination repos.
# repos are separated by space.
gitmirror_clones=("git@github.com:FlorianKutzer/gitmirror.git")
