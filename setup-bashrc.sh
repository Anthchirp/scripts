#!/bin/bash

grep -q -v "^\s*\(#\|$\)" ~/.bashrc && echo Skipping bashrc install || {
echo Installing bashrc
cp setup-bashrc.file ~/.bashrc
}
