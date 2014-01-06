#! /bin/bash

if [ -f $1.pl ]; then
  eval "$*" | perl $1.pl
else
  eval "$*" | perl default.pl
fi
