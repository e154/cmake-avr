CMAKE_MINIMUM_REQUIRED(VERSION 2.8.4)

PROJECT(cmake-avr)

SET(MCU_SPEED "8000000")
SET(AVR_MCU "atmega8")
set(AVR_H_FUSE 0xd9)
set(AVR_L_FUSE 0xc4)

set(AVR_UPLOADTOOL avrdude)
set(AVR_PROGRAMMER stk500v2)
set(AVR_UPLOADTOOL_PORT /dev/ttyUSB0)

set(CMAKE_BUILD_TYPE Release)

SET(SOURCE_EXE

        main.c
)

SET(SOURCE_LIB


)

include_directories(../common)

##########################################################################
# compiler options for all build types
##########################################################################
add_definitions("-DF_CPU=${MCU_SPEED}")
#add_definitions("-fpack-struct")
#add_definitions("-fshort-enums")
#add_definitions("-Wall")
add_definitions("-Werror")
#add_definitions("-pedantic")
#add_definitions("-pedantic-errors")
#add_definitions("-funsigned-char")
#add_definitions("-funsigned-bitfields")
#add_definitions("-ffunction-sections")
#add_definitions("-c")
add_definitions("-std=gnu99")
add_definitions("-mmcu=${AVR_MCU}")

##########################################################################

include(avr-gcc.cmake)