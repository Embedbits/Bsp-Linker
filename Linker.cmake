#============================ Build configuration =============================#

# Configure core type
set(CMAKE_C_FLAGS      "${CMAKE_C_FLAGS} ${MCPU_CORTEX_M4}")
set(CMAKE_CXX_FLAGS    "${CMAKE_CXX_FLAGS} ${MCPU_CORTEX_M4}")

# Configure Floating-Point unit
set(CMAKE_C_FLAGS      "${CMAKE_C_FLAGS} ${MFPU_FPV4_SP_D16}")
set(CMAKE_CXX_FLAGS    "${CMAKE_CXX_FLAGS} ${MFPU_FPV4_SP_D16}")

# Configure FPU
set(CMAKE_C_FLAGS      "${CMAKE_C_FLAGS} ${MFLOAT_ABI_HARDWARE}")
set(CMAKE_CXX_FLAGS    "${CMAKE_CXX_FLAGS} ${MFLOAT_ABI_HARDWARE}")

#============================== Constant values ===============================#

# Include current directory for provide headers include
include_directories(${CMAKE_CURRENT_SOURCE_DIR})

# Path to the folder with linker files
set(LINKER_FILES_PATH "${CMAKE_CURRENT_LIST_DIR}")

#=========================== Linker file selection ===========================#

set(LINKER_FILE_NAME "Linker.ld")

message(STATUS "MCU target: ${TARGET_MCU_FULL_NAME}")

# Generic extraction of the subfamily identifier (three chars right after the
# one-letter STM32 family code) from the STM32 MCU name. Works unchanged for
# both the generic placeholder form (e.g. STM32H503xH) and a full order code
# (e.g. STM32H503RBT6) - the subfamily code always sits in that position for
# either form.
string(REGEX MATCH "STM32.([0-9A-Z][0-9A-Z][0-9A-Z])" _ ${TARGET_MCU_FULL_NAME})
set(MCU_ID "${CMAKE_MATCH_1}")
message(STATUS "MCU_ID: ${MCU_ID}")

# Extraction of FLASH identification.
#
# Generic placeholder form (STM32H503xH): the flash-size letter is the char
# right after the literal "x" placeholder.
# Full order code form (STM32H503RBT6): the flash-size letter is the char
# right after the real pin-count/package letter ("R" here).
#
# Both forms put the flash-size letter one character after the subfamily
# code, so a single regex that treats that in-between character as a
# wildcard (instead of requiring the literal "x") covers both - it no
# longer needs an end-of-string anchor either, since the full order code has
# more characters (package letter, temperature grade, ...) following the
# flash-size letter.
string(REGEX MATCH "STM32.[0-9A-Z][0-9A-Z][0-9A-Z].([0-9A-K])" _ ${TARGET_MCU_FULL_NAME})
set(MCU_FLASH_CODE "${CMAKE_MATCH_1}")
message(STATUS "MCU FLASH code: ${MCU_FLASH_CODE}")

# Decode RAM and CCMRAM from MCU ID (and FLASH code for STM32G411)
# This values has to be set according to the MCU family because ST cannot unify
# their MCU naming convention.
# Sizes follow the CMSIS device headers (SRAM1_SIZE_MAX, SRAM2_SIZE,
# CCMSRAM_SIZE): RAM is SRAM1 + SRAM2 contiguous at 0x20000000, CCMRAM is the
# CCM SRAM at 0x10000000. CCM SRAM is aliased right after SRAM2 as well - the
# alias is never part of RAM, otherwise RAM and CCMRAM content would overlap.
# STM32G411x6 / x8 / xB use the STM32G431 die (stm32g411xb.h), STM32G411xC
# the STM32G491 die (stm32g411xc.h).
if((MCU_ID STREQUAL "431") OR
   (MCU_ID STREQUAL "441") OR
   ((MCU_ID STREQUAL "411") AND
    NOT (MCU_FLASH_CODE STREQUAL "C"))    )

    set(RAM_SIZE    "22K")
    set(CCMRAM_SIZE "10K")

elseif(MCU_ID STREQUAL "414")

    set(RAM_SIZE    "40K")
    set(CCMRAM_SIZE "20K")

elseif((MCU_ID STREQUAL "471") OR
       (MCU_ID STREQUAL "473") OR
       (MCU_ID STREQUAL "474") OR
       (MCU_ID STREQUAL "483") OR
       (MCU_ID STREQUAL "484")    )

    set(RAM_SIZE    "96K")
    set(CCMRAM_SIZE "32K")

elseif((MCU_ID STREQUAL "411") OR
       (MCU_ID STREQUAL "491") OR
       (MCU_ID STREQUAL "4A1")    )

    set(RAM_SIZE    "96K")
    set(CCMRAM_SIZE "16K")

else()
    set(RAM_SIZE    "0")
    set(CCMRAM_SIZE "0")
    message(SEND_ERROR "Unknown MCU type: ${MCU_ID}")
endif()

# Decode FLASH from MCU ID (STM32G4 devices have 32K - 512K FLASH)
if(MCU_FLASH_CODE STREQUAL "6")
    set(FLASH_SIZE_KB 32)
elseif(MCU_FLASH_CODE STREQUAL "8")
    set(FLASH_SIZE_KB 64)
elseif(MCU_FLASH_CODE STREQUAL "B")
    set(FLASH_SIZE_KB 128)
elseif(MCU_FLASH_CODE STREQUAL "C")
    set(FLASH_SIZE_KB 256)
elseif(MCU_FLASH_CODE STREQUAL "E")
    set(FLASH_SIZE_KB 512)
else()
    set(FLASH_SIZE_KB 0)
    message(SEND_ERROR "Unknown FLASH code: ${MCU_FLASH_CODE}")
endif()

set(FLASH_SIZE "${FLASH_SIZE_KB}K")

message(STATUS "RAM: ${RAM_SIZE}, CCMRAM: ${CCMRAM_SIZE}, FLASH: ${FLASH_SIZE}")


if(NOT DEFINED USER_DATA_SIZE)
    # Default value for USER_DATA_SIZE
    set(USER_DATA_SIZE "0")
    message(STATUS "USER_DATA_SIZE is not defined. Using default value.")
else()
    # Check if USER_DATA_SIZE is a valid number
    if(NOT USER_DATA_SIZE MATCHES "^[0-9]+$")
        message(FATAL_ERROR "USER_DATA_SIZE must be a number.")
    endif()
endif()

# STM32G4 FLASH is erased by pages. The USER_DATA region is placed at the end
# of FLASH, so it has to consist of whole pages, otherwise erasing the user
# data would erase application code as well. The page has 2K, on lines with
# dual bank option (FLASH_OPTR_DBANK - STM32G411xC, G414, G471, G473, G474,
# G483, G484) the page has 4K in single bank mode (DBANK = 0) - 4K granularity
# is required there, so the region fits both bank modes.
if(USER_DATA_SIZE GREATER 0)

    if((MCU_ID STREQUAL "414") OR
       (MCU_ID STREQUAL "471") OR
       (MCU_ID STREQUAL "473") OR
       (MCU_ID STREQUAL "474") OR
       (MCU_ID STREQUAL "483") OR
       (MCU_ID STREQUAL "484") OR
       ((MCU_ID STREQUAL "411") AND
        (MCU_FLASH_CODE STREQUAL "C"))    )
        set(FLASH_PAGE_SIZE 4096)
    else()
        set(FLASH_PAGE_SIZE 2048)
    endif()

    math(EXPR FLASH_SIZE_BYTES       "${FLASH_SIZE_KB} * 1024")
    math(EXPR USER_DATA_PAGE_REM     "${USER_DATA_SIZE} % ${FLASH_PAGE_SIZE}")

    if(NOT USER_DATA_PAGE_REM EQUAL 0)
        message(FATAL_ERROR "USER_DATA_SIZE (${USER_DATA_SIZE}) must be a multiple "
                            "of the FLASH page size (${FLASH_PAGE_SIZE}).")
    endif()

    if(NOT USER_DATA_SIZE LESS FLASH_SIZE_BYTES)
        message(FATAL_ERROR "USER_DATA_SIZE (${USER_DATA_SIZE}) must be smaller "
                            "than FLASH size (${FLASH_SIZE_BYTES}).")
    endif()

endif()


set(LINKER_TEMPLATE "${CMAKE_CURRENT_LIST_DIR}/${LINKER_FILE_NAME}.in")
set(LINKER_SCRIPT   "${CMAKE_CURRENT_BINARY_DIR}/${LINKER_FILE_NAME}")

configure_file(${LINKER_TEMPLATE} ${LINKER_SCRIPT} @ONLY)

set(LINKER_SCRIPT "${CMAKE_CURRENT_BINARY_DIR}/${LINKER_FILE_NAME}" CACHE STRING "Linker script")


