cmake-avr - a cmake toolchain for AVR projects
----------------------------------------------

JetBrain Clion use, and without

## Supported system

    Linux
    Windows 7
    Windows XP
    OS X

## Features

    build only hex file
    build only eeprom file
    build hex and eeprom files
    disassemble hex file
    get osc. colibration
    get fuse
    get status
    set osc. calibration
    set fuse
    upload hex
    upload eeprom
    
## Install

```bash
    git clone https://github.com/e154/cmake-avr.git /path/to/clone   
```

use with clion:

```
    File -> import Project
    
    or
    
    Import project from source
```

or console:
```bash

    cd cmake-avr
    mkdir build
    cd build
    cmake ..
    make
    #it's all
    
```

#### LICENSE

cmake-avr is licensed under the [MIT License (MIT)](https://github.com/e154/cmake-avr/blob/dev/LICENSE)
