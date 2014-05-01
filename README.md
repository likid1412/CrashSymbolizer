CrashSymbolizer
===============

symbolize iOS crash info

usage:

1. Fill the dSYM path
2. Choose an Architecture: armv7/armv7s/arm64
3. Copy crash info into left text view, the carsh info like this:

```
6   MyApp                        	0x000f8f5c 0x26000 + 864092
```
4. (Default no choose) Choose the left corner to show all info or no (some infos don't related to MyApp, like Apple API below.
```
17  UIKit                         	0x30022c42 -[UITableView _updateVisibleCellsNow:] + 1802
```
5. Click Transfer Button

