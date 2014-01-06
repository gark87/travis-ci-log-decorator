#! /bin/bash

dir=`dirname $0`
echo $dir
if [ -f $dir/$1.pl ]; then
  eval "$*" | perl $dir/$1.pl
else
  eval "$*" | perl $dir/default.pl
fi
