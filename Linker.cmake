#============================ Build configuration =============================#

# Configure core type
set(CMAKE_C_FLAGS      "${CMAKE_C_FLAGS} ${MCPU_CORTEX_M33}")
set(CMAKE_CXX_FLAGS    "${CMAKE_CXX_FLAGS} ${MCPU_CORTEX_M33}")

# Configure Floating-Point unit
set(CMAKE_C_FLAGS      "${CMAKE_C_FLAGS} ${MFPU_FPV4_SP_D16}")
set(CMAKE_CXX_FLAGS    "${CMAKE_CXX_FLAGS} ${MFPU_FPV4_SP_D16}")

# Configure FPU
set(CMAKE_C_FLAGS      "${CMAKE_C_FLAGS} ${FLOAT_ABI_HARDWARE}")
set(CMAKE_CXX_FLAGS    "${CMAKE_CXX_FLAGS} ${FLOAT_ABI_HARDWARE}")

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

# Decode RAM from MCU ID
# This values has to be set according to the MCU family because ST cannot unify
# their MCU naming convention
if((MCU_ID STREQUAL "723") OR 
   (MCU_ID STREQUAL "733") OR 
   (MCU_ID STREQUAL "725") OR 
   (MCU_ID STREQUAL "735") OR 
   (MCU_ID STREQUAL "730")    )
   
    set(RAM_SIZE "564K")
    
elseif((MCU_ID STREQUAL "7R3") OR 
       (MCU_ID STREQUAL "7S3") OR 
       (MCU_ID STREQUAL "7R7") OR 
       (MCU_ID STREQUAL "7S7")    )
       
    set(RAM_SIZE "620K")
    
elseif(MCU_ID STREQUAL "742")

    set(RAM_SIZE "692K")
    
elseif((MCU_ID STREQUAL "743") OR 
       (MCU_ID STREQUAL "753") OR 
       (MCU_ID STREQUAL "745") OR
       (MCU_ID STREQUAL "755") OR
       (MCU_ID STREQUAL "747") OR
       (MCU_ID STREQUAL "757") OR
       (MCU_ID STREQUAL "750")    )
       
    set(RAM_SIZE "1024K")
    
elseif((MCU_ID STREQUAL "7A3") OR 
       (MCU_ID STREQUAL "7B3") OR 
       (MCU_ID STREQUAL "7B0")    )
       
    set(RAM_SIZE "1184K")
    
else()
    message(SEND_ERROR "Unknown MCU type: ${MCU_ID}")
endif()

# Decode CCMRAM from MCU ID
# This values has to be set according to the MCU family because ST cannot unify
# their MCU naming convention
if(NOT MCU_ID STREQUAL "") 

    set(BACKUPRAM_SIZE "4K")
    
else()

    set(BACKUPRAM_SIZE "0")
    message(STATUS "Unknown MCU type: ${MCU_ID}")
    
endif()

# Decode FLASH from MCU ID
if(MCU_FLASH_CODE STREQUAL "A")
    set(FLASH_SIZE "0")
elseif(MCU_FLASH_CODE STREQUAL "6")
    set(FLASH_SIZE "32K")
elseif(MCU_FLASH_CODE STREQUAL "8")
    set(FLASH_SIZE "64K")
elseif(MCU_FLASH_CODE STREQUAL "B")
    set(FLASH_SIZE "128K")
elseif(MCU_FLASH_CODE STREQUAL "C")
    set(FLASH_SIZE "256K")
elseif(MCU_FLASH_CODE STREQUAL "D")
    set(FLASH_SIZE "384K")
elseif(MCU_FLASH_CODE STREQUAL "E")
    set(FLASH_SIZE "512K")
elseif(MCU_FLASH_CODE STREQUAL "F")
    set(FLASH_SIZE "768K")
elseif(MCU_FLASH_CODE STREQUAL "G")
    set(FLASH_SIZE "1024K")
elseif(MCU_FLASH_CODE STREQUAL "H")
    set(FLASH_SIZE "1536K")
elseif(MCU_FLASH_CODE STREQUAL "I")
    set(FLASH_SIZE "2048K")
elseif(MCU_FLASH_CODE STREQUAL "J")
    set(FLASH_SIZE "4096K")
elseif(MCU_FLASH_CODE STREQUAL "K")
    set(FLASH_SIZE "3072K")
else()
    message(SEND_ERROR "Unknown FLASH code: ${MCU_FLASH_CODE}")
endif()

message(STATUS "RAM: ${RAM_SIZE}, FLASH: ${FLASH_SIZE}")


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


set(LINKER_TEMPLATE "${CMAKE_CURRENT_LIST_DIR}/${LINKER_FILE_NAME}.in")
set(LINKER_SCRIPT   "${CMAKE_CURRENT_BINARY_DIR}/${LINKER_FILE_NAME}")

configure_file(${LINKER_TEMPLATE} ${LINKER_SCRIPT} @ONLY)

set(LINKER_SCRIPT "${CMAKE_CURRENT_BINARY_DIR}/${LINKER_FILE_NAME}" CACHE STRING "Linker script")
