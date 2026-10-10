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
# both the generic placeholder form (e.g. STM32F746xG) and a full order code
# (e.g. STM32F746NGH6) - the subfamily code always sits in that position for
# either form.
string(REGEX MATCH "STM32.([0-9A-Z][0-9A-Z][0-9A-Z])" _ ${TARGET_MCU_FULL_NAME})
set(MCU_ID "${CMAKE_MATCH_1}")
message(STATUS "MCU_ID: ${MCU_ID}")

# Extraction of FLASH identification.
#
# Generic placeholder form (STM32F746xG): the flash-size letter is the char
# right after the literal "x" placeholder.
# Full order code form (STM32F746NGH6): the flash-size letter is the char
# right after the real pin-count/package letter ("N" here).
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

# Lines of STM32F7 family. ST cannot unify their MCU naming convention, the
# memory layout has to be decoded per line:
#   - STM32F72x/F73x : DTCM 64K  + SRAM1 176K + SRAM2 16K, FLASH sectors 16K/64K/128K
#   - STM32F74x/F75x : DTCM 64K  + SRAM1 240K + SRAM2 16K, FLASH sectors 32K/128K/256K
#   - STM32F76x/F77x : DTCM 128K + SRAM1 368K + SRAM2 16K, FLASH sectors 32K/128K/256K
#                      (single bank mode - default nDBANK option), double
#                      precision FPU
if((MCU_ID STREQUAL "722") OR
   (MCU_ID STREQUAL "723") OR
   (MCU_ID STREQUAL "730") OR
   (MCU_ID STREQUAL "732") OR
   (MCU_ID STREQUAL "733")    )

    set(MCU_LINE "F72x")

elseif((MCU_ID STREQUAL "745") OR
       (MCU_ID STREQUAL "746") OR
       (MCU_ID STREQUAL "750") OR
       (MCU_ID STREQUAL "756")    )

    set(MCU_LINE "F74x")

elseif((MCU_ID STREQUAL "765") OR
       (MCU_ID STREQUAL "767") OR
       (MCU_ID STREQUAL "768") OR
       (MCU_ID STREQUAL "769") OR
       (MCU_ID STREQUAL "777") OR
       (MCU_ID STREQUAL "778") OR
       (MCU_ID STREQUAL "779")    )

    set(MCU_LINE "F76x")

else()
    set(MCU_LINE "")
    message(SEND_ERROR "Unknown MCU type: ${MCU_ID}")
endif()

#============================ Build configuration =============================#

# Configure core type
set(CMAKE_C_FLAGS      "${CMAKE_C_FLAGS} ${MCPU_CORTEX_M7}")
set(CMAKE_CXX_FLAGS    "${CMAKE_CXX_FLAGS} ${MCPU_CORTEX_M7}")

# Configure Floating-Point unit - STM32F76x/F77x have double precision FPU
# (FPv5-D16), other lines single precision FPU (FPv5-SP-D16)
if(MCU_LINE STREQUAL "F76x")
    set(CMAKE_C_FLAGS      "${CMAKE_C_FLAGS} ${MFPU_FPV5_D16}")
    set(CMAKE_CXX_FLAGS    "${CMAKE_CXX_FLAGS} ${MFPU_FPV5_D16}")
else()
    set(CMAKE_C_FLAGS      "${CMAKE_C_FLAGS} ${MFPU_FPV5_SP_D16}")
    set(CMAKE_CXX_FLAGS    "${CMAKE_CXX_FLAGS} ${MFPU_FPV5_SP_D16}")
endif()

# Configure FPU
set(CMAKE_C_FLAGS      "${CMAKE_C_FLAGS} ${MFLOAT_ABI_HARDWARE}")
set(CMAKE_CXX_FLAGS    "${CMAKE_CXX_FLAGS} ${MFLOAT_ABI_HARDWARE}")

#============================ Memory decoding =================================#

# Decode RAM from MCU line
# Sizes cover the contiguous RAM at 0x20000000 (DTCM + SRAM1 + SRAM2). DTCM is
# accessible by DMA through the AHBS port of the core.
if(MCU_LINE STREQUAL "F72x")

    set(RAM_SIZE   "256K")
    set(DTCM_SIZE  "64K")

elseif(MCU_LINE STREQUAL "F74x")

    set(RAM_SIZE   "320K")
    set(DTCM_SIZE  "64K")

elseif(MCU_LINE STREQUAL "F76x")

    set(RAM_SIZE   "512K")
    set(DTCM_SIZE  "128K")

else()
    set(RAM_SIZE   "0")
    set(DTCM_SIZE  "0")
endif()

# Instruction RAM (ITCM) and Backup SRAM are present on all STM32F7 lines
set(ITCMRAM_SIZE "16K")
set(BKPRAM_SIZE  "4K")

# Decode FLASH from MCU ID
if(MCU_FLASH_CODE STREQUAL "8")
    set(FLASH_SIZE_KB 64)
elseif(MCU_FLASH_CODE STREQUAL "C")
    set(FLASH_SIZE_KB 256)
elseif(MCU_FLASH_CODE STREQUAL "E")
    set(FLASH_SIZE_KB 512)
elseif(MCU_FLASH_CODE STREQUAL "G")
    set(FLASH_SIZE_KB 1024)
elseif(MCU_FLASH_CODE STREQUAL "I")
    set(FLASH_SIZE_KB 2048)
else()
    set(FLASH_SIZE_KB 0)
    message(SEND_ERROR "Unknown FLASH code: ${MCU_FLASH_CODE}")
endif()

set(FLASH_SIZE "${FLASH_SIZE_KB}K")

message(STATUS "RAM: ${RAM_SIZE} (DTCM ${DTCM_SIZE}), ITCMRAM: ${ITCMRAM_SIZE}, BKPRAM: ${BKPRAM_SIZE}, FLASH: ${FLASH_SIZE}")


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

# STM32F7 FLASH sectors have different sizes and only a whole sector can be
# erased. The USER_DATA region is placed at the end of FLASH, so it has to
# consist of whole sectors, otherwise erasing the user data would erase
# application code as well. The last sector is:
#   - STM32F72x/F73x : 16K for 64K FLASH (4 x 16K), 128K otherwise
#                      (4 x 16K + 64K + 128K ...)
#   - STM32F74x-F77x : 32K for 64K FLASH (2 x 32K), 256K otherwise
#                      (4 x 32K + 128K + 256K ..., single bank mode)
if(USER_DATA_SIZE GREATER 0)

    if(MCU_LINE STREQUAL "F72x")
        if(FLASH_SIZE_KB LESS_EQUAL 64)
            set(FLASH_LAST_SECTOR_KB 16)
        else()
            set(FLASH_LAST_SECTOR_KB 128)
        endif()
    else()
        if(FLASH_SIZE_KB LESS_EQUAL 64)
            set(FLASH_LAST_SECTOR_KB 32)
        else()
            set(FLASH_LAST_SECTOR_KB 256)
        endif()
    endif()

    math(EXPR FLASH_LAST_SECTOR_SIZE "${FLASH_LAST_SECTOR_KB} * 1024")
    math(EXPR FLASH_SIZE_BYTES       "${FLASH_SIZE_KB} * 1024")
    math(EXPR USER_DATA_SECTOR_REM   "${USER_DATA_SIZE} % ${FLASH_LAST_SECTOR_SIZE}")

    if(NOT USER_DATA_SECTOR_REM EQUAL 0)
        message(FATAL_ERROR "USER_DATA_SIZE (${USER_DATA_SIZE}) must be a multiple "
                            "of the last FLASH sector size (${FLASH_LAST_SECTOR_SIZE}).")
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
