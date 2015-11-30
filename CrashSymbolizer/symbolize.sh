#!/bin/sh

#  symbolize.sh
#  CrashSymbolizer
#
#  Created by Likid on 11/30/15.
#  Copyright © 2015 likid1412. All rights reserved.

#!/bin/bash
# ./symbolicate.sh MyApp armv7 11800

slide=`otool -arch $2 -l $1 | grep -B 3 -A 8 -m 2 "__TEXT" | grep "vmaddr" | sed -e "s/^.*vmaddr //"`

#echo "slide = $slide"

stack_address=$3

#echo "stack_address(before add) = $stack_address"

stack_address=$((${slide}+${stack_address}))

stack_address=`echo "obase=16;${stack_address}" | bc`

#echo "stack_address(after add) = $stack_address"

/Applications/Xcode.app/Contents/Developer/usr/bin/atos -arch $2 -o $1 $stack_address