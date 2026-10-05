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
# both the generic placeholder form (e.g. STM32F411xE) and a full order code
# (e.g. STM32F411VET6) - the subfamily code always sits in that position for
# either form.
string(REGEX MATCH "STM32.([0-9A-Z][0-9A-Z][0-9A-Z])" _ ${TARGET_MCU_FULL_NAME})
set(MCU_ID "${CMAKE_MATCH_1}")
message(STATUS "MCU_ID: ${MCU_ID}")

# Extraction of FLASH identification.
#
# Generic placeholder form (STM32F411xE): the flash-size letter is the char
# right after the literal "x" placeholder.
# Full order code form (STM32F411VET6): the flash-size letter is the char
# right after the real pin-count/package letter ("V" here).
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

# Decode RAM from MCU ID
# This values has to be set according to the MCU family because ST cannot unify
# their MCU naming convention.
# Sizes cover the contiguous SRAM at 0x20000000 (SRAM1 + SRAM2 + SRAM3).
if(MCU_ID STREQUAL "410")

    set(RAM_SIZE "32K")

elseif((MCU_ID STREQUAL "401") AND
       ((MCU_FLASH_CODE STREQUAL "B") OR
        (MCU_FLASH_CODE STREQUAL "C")    ))

    set(RAM_SIZE "64K")

elseif((MCU_ID STREQUAL "401") AND
       ((MCU_FLASH_CODE STREQUAL "D") OR
        (MCU_FLASH_CODE STREQUAL "E")    ))

    set(RAM_SIZE "96K")

elseif((MCU_ID STREQUAL "446") OR
       (MCU_ID STREQUAL "411") OR
       (MCU_ID STREQUAL "405") OR
       (MCU_ID STREQUAL "407") OR
       (MCU_ID STREQUAL "415") OR
       (MCU_ID STREQUAL "417")    )

    set(RAM_SIZE "128K")

elseif((MCU_ID STREQUAL "427") OR
       (MCU_ID STREQUAL "429") OR
       (MCU_ID STREQUAL "437") OR
       (MCU_ID STREQUAL "439")    )

    set(RAM_SIZE "192K")

elseif(MCU_ID STREQUAL "412")

    set(RAM_SIZE "256K")

elseif((MCU_ID STREQUAL "413") OR
       (MCU_ID STREQUAL "423") OR
       (MCU_ID STREQUAL "469") OR
       (MCU_ID STREQUAL "479")    )

    set(RAM_SIZE "320K")

else()
    message(SEND_ERROR "Unknown MCU type: ${MCU_ID}")
endif()

# Decode CCMRAM from MCU ID
# This values has to be set according to the MCU family because ST cannot unify
# their MCU naming convention
if((MCU_ID STREQUAL "405") OR
   (MCU_ID STREQUAL "407") OR
   (MCU_ID STREQUAL "415") OR
   (MCU_ID STREQUAL "417") OR
   (MCU_ID STREQUAL "427") OR
   (MCU_ID STREQUAL "429") OR
   (MCU_ID STREQUAL "437") OR
   (MCU_ID STREQUAL "439") OR
   (MCU_ID STREQUAL "469") OR
   (MCU_ID STREQUAL "479")    )

    set(CCMRAM_SIZE "64K")

else()
    set(CCMRAM_SIZE "0")
    message(STATUS "No CCMRAM available for ${MCU_ID}")
endif()

# Decode Backup SRAM from MCU ID
# This values has to be set according to the MCU family because ST cannot unify
# their MCU naming convention
if((MCU_ID STREQUAL "405") OR
   (MCU_ID STREQUAL "407") OR
   (MCU_ID STREQUAL "415") OR
   (MCU_ID STREQUAL "417") OR
   (MCU_ID STREQUAL "427") OR
   (MCU_ID STREQUAL "429") OR
   (MCU_ID STREQUAL "437") OR
   (MCU_ID STREQUAL "439") OR
   (MCU_ID STREQUAL "446") OR
   (MCU_ID STREQUAL "469") OR
   (MCU_ID STREQUAL "479")    )

    set(BKPRAM_SIZE "4K")

else()
    set(BKPRAM_SIZE "0")
    message(STATUS "No Backup SRAM available for ${MCU_ID}")
endif()

# Decode FLASH from MCU ID
if(MCU_FLASH_CODE STREQUAL "8")
    set(FLASH_SIZE_KB 64)
elseif(MCU_FLASH_CODE STREQUAL "B")
    set(FLASH_SIZE_KB 128)
elseif(MCU_FLASH_CODE STREQUAL "C")
    set(FLASH_SIZE_KB 256)
elseif(MCU_FLASH_CODE STREQUAL "D")
    set(FLASH_SIZE_KB 384)
elseif(MCU_FLASH_CODE STREQUAL "E")
    set(FLASH_SIZE_KB 512)
elseif(MCU_FLASH_CODE STREQUAL "G")
    set(FLASH_SIZE_KB 1024)
elseif(MCU_FLASH_CODE STREQUAL "H")
    set(FLASH_SIZE_KB 1536)
elseif(MCU_FLASH_CODE STREQUAL "I")
    set(FLASH_SIZE_KB 2048)
else()
    set(FLASH_SIZE_KB 0)
    message(SEND_ERROR "Unknown FLASH code: ${MCU_FLASH_CODE}")
endif()

set(FLASH_SIZE "${FLASH_SIZE_KB}K")

message(STATUS "RAM: ${RAM_SIZE}, CCMRAM: ${CCMRAM_SIZE}, BKPRAM: ${BKPRAM_SIZE}, FLASH: ${FLASH_SIZE}")


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

# STM32F4 FLASH sectors have different sizes (16K/64K/128K) and only a whole
# sector can be erased. The USER_DATA region is placed at the end of FLASH, so
# it has to consist of whole sectors, otherwise erasing the user data would
# erase application code as well. The last sector is:
#   - 16K  for 64K FLASH  (4 x 16K)
#   - 64K  for 128K FLASH (4 x 16K + 64K)
#   - 128K for >= 256K FLASH (all sectors from offset 128K are 128K)
if(USER_DATA_SIZE GREATER 0)

    if(FLASH_SIZE_KB LESS_EQUAL 64)
        set(FLASH_LAST_SECTOR_KB 16)
    elseif(FLASH_SIZE_KB EQUAL 128)
        set(FLASH_LAST_SECTOR_KB 64)
    else()
        set(FLASH_LAST_SECTOR_KB 128)
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
