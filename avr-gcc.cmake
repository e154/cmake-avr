CMAKE_MINIMUM_REQUIRED(VERSION 2.8.4)

SET(CMAKE_SYSTEM_NAME Generic)

option(WITH_MCU "Add the mCU type to the target file name." ON)

##########################################################################
# status messages
##########################################################################
message(STATUS "Current uploadtool is: ${AVR_UPLOADTOOL}")
message(STATUS "Current programmer is: ${AVR_PROGRAMMER}")
message(STATUS "Current upload port is: ${AVR_UPLOADTOOL_PORT}")
message(STATUS "Current uploadtool options are: ${AVR_UPLOADTOOL_OPTIONS}")
message(STATUS "Current MCU is set to: ${AVR_MCU}")
message(STATUS "Current H_FUSE is set to: ${AVR_H_FUSE}")
message(STATUS "Current L_FUSE is set to: ${AVR_L_FUSE}")

##########################################################################
# executables in use
##########################################################################
find_program(AVR_CC avr-gcc)
find_program(AVR_CXX avr-g++)
find_program(AVR_OBJCOPY avr-objcopy)
find_program(AVR_SIZE_TOOL avr-size)
find_program(AVR_OBJDUMP avr-objdump)

##########################################################################
# toolchain starts with defining mandatory variables
##########################################################################
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR avr)
set(CMAKE_C_COMPILER ${AVR_CC})
set(CMAKE_CXX_COMPILER ${AVR_CXX})

##########################################################################
# some necessary tools and variables for AVR builds, which may not
# defined yet
# - AVR_UPLOADTOOL
# - AVR_UPLOADTOOL_PORT
# - AVR_PROGRAMMER
# - AVR_MCU
# - AVR_SIZE_ARGS
##########################################################################

# default upload tool
if(NOT AVR_UPLOADTOOL)
    set(
            AVR_UPLOADTOOL avrdude
            CACHE STRING "Set default upload tool: avrdude"
    )
    find_program(AVR_UPLOADTOOL avrdude)
endif(NOT AVR_UPLOADTOOL)

# default upload tool port
if(NOT AVR_UPLOADTOOL_PORT)
    set(
            AVR_UPLOADTOOL_PORT usb
            CACHE STRING "Set default upload tool port: usb"
    )
endif(NOT AVR_UPLOADTOOL_PORT)

# default programmer (hardware)
if(NOT AVR_PROGRAMMER)
    set(
            AVR_PROGRAMMER avrispmkII
            CACHE STRING "Set default programmer hardware model: avrispmkII"
    )
endif(NOT AVR_PROGRAMMER)

# default MCU (chip)
if(NOT AVR_MCU)
    set(
            AVR_MCU atmega8
            CACHE STRING "Set default MCU: atmega8 (see 'avr-gcc --target-help' for valid values)"
    )
endif(NOT AVR_MCU)

#default avr-size args
if(NOT AVR_SIZE_ARGS)
    if(APPLE)
        set(AVR_SIZE_ARGS -B)
    else(APPLE)
        set(AVR_SIZE_ARGS -C;--mcu=${AVR_MCU})
    endif(APPLE)
endif(NOT AVR_SIZE_ARGS)

##########################################################################
# set build type
##########################################################################
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif(NOT CMAKE_BUILD_TYPE)

##########################################################################
# status messages for generating
##########################################################################
message(STATUS "Set CMAKE_FIND_ROOT_PATH to ${CMAKE_FIND_ROOT_PATH}")
message(STATUS "Set CMAKE_SYSTEM_INCLUDE_PATH to ${CMAKE_SYSTEM_INCLUDE_PATH}")
message(STATUS "Set CMAKE_SYSTEM_LIBRARY_PATH to ${CMAKE_SYSTEM_LIBRARY_PATH}")

##########################################################################
# set compiler options for build types
##########################################################################
if(CMAKE_BUILD_TYPE MATCHES Release)
    set(CMAKE_C_FLAGS_RELEASE "-Os")
    set(CMAKE_CXX_FLAGS_RELEASE "-Os")
endif(CMAKE_BUILD_TYPE MATCHES Release)

if(CMAKE_BUILD_TYPE MATCHES RelWithDebInfo)
    set(CMAKE_C_FLAGS_RELWITHDEBINFO "-Os -save-temps -g -gdwarf-3 -gstrict-dwarf")
    set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "-Os -save-temps -g -gdwarf-3 -gstrict-dwarf")
endif(CMAKE_BUILD_TYPE MATCHES RelWithDebInfo)

if(CMAKE_BUILD_TYPE MATCHES Debug)
    set(CMAKE_C_FLAGS_DEBUG "-O0 -save-temps -g -gdwarf-3 -gstrict-dwarf")
    set(CMAKE_CXX_FLAGS_DEBUG "-O0 -save-temps -g -gdwarf-3 -gstrict-dwarf")
endif(CMAKE_BUILD_TYPE MATCHES Debug)

##########################################################################
# avr-gcc: error: unrecognized command line option ‘-rdynamic’
set(CMAKE_SHARED_LIBRARY_LINK_C_FLAGS "")
set(CMAKE_SHARED_LIBRARY_LINK_CXX_FLAGS "")

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/bin")

##########################################################################
# target file name add-on
##########################################################################
if(WITH_MCU)
    set(MCU_TYPE_FOR_FILENAME "${AVR_MCU}")
else(WITH_MCU)
    set(MCU_TYPE_FOR_FILENAME "")
endif(WITH_MCU)

##########################################################################
#
##########################################################################
set(elf_file ${MCU_TYPE_FOR_FILENAME}.elf)
set(hex_file ${MCU_TYPE_FOR_FILENAME}.hex)
set(map_file ${MCU_TYPE_FOR_FILENAME}.map)
set(eeprom_image ${MCU_TYPE_FOR_FILENAME}.eep)

ADD_EXECUTABLE(${elf_file} ${SOURCE_EXE})

#ADD_LIBRARY(foo STATIC ${SOURCE_LIB})
#target_link_libraries(${PROJECT_NAME} foo)

set_target_properties(
        ${elf_file}
        PROPERTIES
        COMPILE_FLAGS "-mmcu=${AVR_MCU}"
        LINK_FLAGS "-mmcu=${AVR_MCU} -Wl,--gc-sections -mrelax -Wl,-Map,${map_file}"
)

add_custom_command(
        OUTPUT ${hex_file}
        COMMAND
        ${AVR_OBJCOPY} -j .text -j .data -O ihex ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${elf_file} ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${hex_file}
        COMMAND
        ${AVR_SIZE_TOOL} ${AVR_SIZE_ARGS} ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${elf_file}
        DEPENDS ${elf_file}
)

# eeprom
add_custom_command(
        OUTPUT ${eeprom_image}
        COMMAND
        ${AVR_OBJCOPY} -j .eeprom --set-section-flags=.eeprom=alloc,load
        --change-section-lma .eeprom=0 --no-change-warnings
        -O ihex ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${elf_file} ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${eeprom_image}
        DEPENDS ${elf_file}
)

add_custom_target(
        build_all
        ALL
        DEPENDS ${hex_file} ${eeprom_image}
)

# clean
get_directory_property(clean_files ADDITIONAL_MAKE_CLEAN_FILES)
set_directory_properties(
        PROPERTIES
        ADDITIONAL_MAKE_CLEAN_FILES "${map_file}"
)

#build
add_custom_target(
        build_${MCU_TYPE_FOR_FILENAME}
        DEPENDS ${hex_file}
        COMMENT "Build ${hex_file} for ${AVR_MCU}"
)

# upload - with avrdude
add_custom_target(
        upload_${MCU_TYPE_FOR_FILENAME}
        ${AVR_UPLOADTOOL} -p ${AVR_MCU} -c ${AVR_PROGRAMMER} ${AVR_UPLOADTOOL_OPTIONS}
        -U flash:w:${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${hex_file}
        -P ${AVR_UPLOADTOOL_PORT}
        DEPENDS ${hex_file}
        COMMENT "Uploading ${hex_file} to ${AVR_MCU} using ${AVR_PROGRAMMER}"
)

# upload eeprom only - with avrdude
# see also bug http://savannah.nongnu.org/bugs/?40142
add_custom_target(
        upload_eeprom
        ${AVR_UPLOADTOOL} -p ${AVR_MCU} -c ${AVR_PROGRAMMER} ${AVR_UPLOADTOOL_OPTIONS}
        -U eeprom:w:${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${eeprom_image}
        -P ${AVR_UPLOADTOOL_PORT}
        DEPENDS ${eeprom_image}
        COMMENT "Uploading ${eeprom_image} to ${AVR_MCU} using ${AVR_PROGRAMMER}"
)

# get status
add_custom_target(
        get_status
        ${AVR_UPLOADTOOL} -p ${AVR_MCU} -c ${AVR_PROGRAMMER} -P ${AVR_UPLOADTOOL_PORT} -n -v
        COMMENT "Get status from ${AVR_MCU}"
)

# get fuses
IF(AVR_E_FUSE)
    add_custom_target(
            get_fuses
            ${AVR_UPLOADTOOL} -p ${AVR_MCU} -c ${AVR_PROGRAMMER} -P ${AVR_UPLOADTOOL_PORT} -n
            -U lfuse:r:-:b
            -U hfuse:r:-:b
            -U efuse:r:-:b
            COMMENT "Get fuses from ${AVR_MCU}"
    )
    ELSE(AVR_E_FUSE)
    add_custom_target(
        get_fuses
        ${AVR_UPLOADTOOL} -p ${AVR_MCU} -c ${AVR_PROGRAMMER} -P ${AVR_UPLOADTOOL_PORT} -n
        -U lfuse:r:-:b
        -U hfuse:r:-:b
        COMMENT "Get fuses from ${AVR_MCU}"
    )
ENDIF(AVR_E_FUSE)

# set fuses
IF(AVR_E_FUSE)
    add_custom_target(
            set_fuses
            ${AVR_UPLOADTOOL} -p ${AVR_MCU} -c ${AVR_PROGRAMMER} -P ${AVR_UPLOADTOOL_PORT}
            -U lfuse:w:${AVR_L_FUSE}:m
            -U hfuse:w:${AVR_H_FUSE}:m
            -U efuse:w:${AVR_E_FUSE}:m
            COMMENT "Setup: High Fuse: ${AVR_H_FUSE} Low Fuse: ${AVR_L_FUSE}"
    )
ELSE(AVR_E_FUSE)
    add_custom_target(
        set_fuses
        ${AVR_UPLOADTOOL} -p ${AVR_MCU} -c ${AVR_PROGRAMMER} -P ${AVR_UPLOADTOOL_PORT}
        -U lfuse:w:${AVR_L_FUSE}:m
        -U hfuse:w:${AVR_H_FUSE}:m
        COMMENT "Setup: High Fuse: ${AVR_H_FUSE} Low Fuse: ${AVR_L_FUSE}"
)
ENDIF(AVR_E_FUSE)


# get oscillator calibration
add_custom_target(
        get_calibration
        ${AVR_UPLOADTOOL} -p ${AVR_MCU} -c ${AVR_PROGRAMMER} -P ${AVR_UPLOADTOOL_PORT}
        -U calibration:r:${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${AVR_MCU}_calib.tmp:r
        COMMENT "Write calibration status of internal oscillator to ${AVR_MCU}_calib.tmp."
)

# set oscillator calibration
add_custom_target(
        set_calibration
        ${AVR_UPLOADTOOL} -p ${AVR_MCU} -c ${AVR_PROGRAMMER} -P ${AVR_UPLOADTOOL_PORT}
        -U calibration:w:${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${AVR_MCU}_calib.hex
        COMMENT "Program calibration status of internal oscillator from ${AVR_MCU}_calib.hex."
)

# disassemble
add_custom_target(
        disassemble_${elf_file}
        ${AVR_OBJDUMP} -h -S ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${elf_file} > ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${MCU_TYPE_FOR_FILENAME}.lst
        DEPENDS ${elf_file}
        COMMENT "Disassemble ${elf_file} >>> ${MCU_TYPE_FOR_FILENAME}.lst"
)
