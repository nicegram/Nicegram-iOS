#!/bin/python3

import os

from BazelLocation import locate_bazel

print(locate_bazel(base_path=os.getcwd()))
