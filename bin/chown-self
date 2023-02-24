#!/usr/bin/env bash
#
# Change ownership of files to self.
#
# Example usage: 
# > chown-self.sh -R .
# In this example, we are changing the ownership of the current directory and all it's descendants to the current user.

set -e

sudo chown "$(id -u):$(id -g)" $*
