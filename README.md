usage:

1. Fill the dSYM path
2. Choose an Architecture: armv7/armv7s/arm64
3. Copy crash info into left text view, the carsh info like this:
`6   MyApp                        	0x000f8f5c 0x26000 + 864092`

4. (Default no choose) Choose the left corner to show all info or no (some infos don't related to MyApp, like Apple API below.
`17  UIKit                         	0x30022c42 -[UITableView _updateVisibleCellsNow:] + 1802`

5. Click Transfer Button

TODO List:
1. Symbolize crash type file(.crash) directy.

======

使用该脚本可直接根据崩溃地址和 dSYM 解析出崩溃地址对应的代码行，用法如下：
./symbolicate.sh MyApp armv7 0x11800
第一个参数为 dSYM 文件，注：非 .dSYM 文件，而是 .dSYM 包里面的文件，右键 .dSYM 可看到 "Show Package Contents", 相应文件在 ”Contents/Resources/DWARF“ 目录下。
第二个参数是 App 在相应崩溃设备中的 arm，如 iPhone4S 是 armv7，iPhone5 是 armv7s，iPhone5s 是 arm64
第三个参数是崩溃地址

```
    #!/bin/bash
    # ./symbolicate.sh MyApp armv7 11800

    slide=`otool -arch $2 -l $1 | grep -B 3 -A 8 -m 2 "__TEXT" | grep "vmaddr" | sed -e "s/^.*vmaddr //"`

    # echo "slide = $slide"

    stack_address=$3

    # echo "stack_address(before add) = $stack_address"

    stack_address=$((${slide}+${stack_address}))

    stack_address=`echo "obase=16;${stack_address}" | bc`

    # echo "stack_address(after add) = $stack_address"

    /Applications/Xcode.app/Contents/Developer/usr/bin/atos -arch $2 -o $1 $stack_address
```

##解析崩溃地址对应的代码行 - 根据崩溃地址和 dSYM 进行解析

该脚本是老大传下来的，所以具体作者不甚清楚。
另，小弟不才，根据改脚本简单写了个 GUI 的 Mac App CrashSymbolizer，可批量解析类型友盟统计收集的崩溃日志，输入解析内容格式如下：
```
5   MyApp                            0x000760c6 0x4f000 + 159942
```
CrashSymbolizer 和 symbolicate.sh 都放在 Github 上，希望大家多多指点。
GitHub: CrashSymbolize
