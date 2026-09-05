# Include current directory for provide headers include
include_directories(${CMAKE_CURRENT_SOURCE_DIR})

#============================== Constant values ===============================#
# Path to the folder with linker files
set(LINKER_FILES_PATH "${CMAKE_CURRENT_LIST_DIR}")

#=========================== Linker file selection ===========================#

set(LINKER_FILE_NAME "Linker.ld")

message(STATUS "MCU target: ${TARGET_MCU_FULL_NAME}")

# Generic extraction of two least significant digits from STM32 MCU name
string(REGEX MATCH "STM32.[0-9A-Z]([0-9A-Z][0-9A-Z])" _ ${TARGET_MCU_FULL_NAME})
set(MCU_ID "${CMAKE_MATCH_1}")
message(STATUS "MCU_ID: ${MCU_ID}")

# Extraction of FLASH identification
string(REGEX MATCH "x([0-9A-J])$" _ ${TARGET_MCU_FULL_NAME})
set(MCU_FLASH_CODE "${CMAKE_MATCH_1}")
message(STATUS "MCU FLASH code: ${MCU_FLASH_CODE}")

# Decode RAM from MCU ID
# This values has to be set according to the MCU family because ST cannot unify
# their MCU naming convention
if((MCU_ID STREQUAL "31") OR (MCU_ID STREQUAL "41"))
    set(RAM_SIZE "22k")
elseif((MCU_ID STREQUAL "11"))
    set(RAM_SIZE "32k")
elseif((MCU_ID STREQUAL "73") OR (MCU_ID STREQUAL "74") OR (MCU_ID STREQUAL "83") OR (MCU_ID STREQUAL "84") OR (MCU_ID STREQUAL "A1") OR (MCU_ID STREQUAL "91"))
    set(RAM_SIZE "96K")
elseif((MCU_ID STREQUAL "71"))
    set(RAM_SIZE "128K")
elseif((MCU_ID STREQUAL "11") OR (MCU_ID STREQUAL "14"))
    set(RAM_SIZE "256K")
else()
    message(SEND_ERROR "Unknown MCU type: ${MCU_ID}")
endif()

# Decode CCMRAM from MCU ID
# This values has to be set according to the MCU family because ST cannot unify
# their MCU naming convention
if((MCU_ID STREQUAL "31") OR (MCU_ID STREQUAL "41"))
    set(CCMRAM_SIZE "10k")
elseif((MCU_ID STREQUAL "A1") OR (MCU_ID STREQUAL "91"))
    set(CCMRAM_SIZE "16k")
elseif((MCU_ID STREQUAL "73") OR (MCU_ID STREQUAL "74") OR (MCU_ID STREQUAL "84") OR (MCU_ID STREQUAL "83"))
    set(CCMRAM_SIZE "32k")
else()
    set(CCMRAM_SIZE "0")
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


