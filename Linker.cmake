#============================ Build configuration =============================#

# Configure core type
set(CMAKE_C_FLAGS      "${CMAKE_C_FLAGS} ${MCPU_CORTEX_M33}")
set(CMAKE_CXX_FLAGS    "${CMAKE_CXX_FLAGS} ${MCPU_CORTEX_M33}")

# Configure Floating-Point unit
set(CMAKE_C_FLAGS      "${CMAKE_C_FLAGS} ${MFPU_FPV5_SP_D16}")
set(CMAKE_CXX_FLAGS    "${CMAKE_CXX_FLAGS} ${MFPU_FPV5_SP_D16}")

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

# Decode RAM from MCU ID
# This values has to be set according to the MCU family because ST cannot unify
# their MCU naming convention
if(MCU_ID STREQUAL "503")
    set(RAM_SIZE "32K")
elseif((MCU_ID STREQUAL "523") OR (MCU_ID STREQUAL "533"))
    set(RAM_SIZE "272K")
elseif((MCU_ID STREQUAL "543") OR (MCU_ID STREQUAL "553"))
    set(RAM_SIZE "304K")
elseif((MCU_ID STREQUAL "562") OR (MCU_ID STREQUAL "563") OR (MCU_ID STREQUAL "573"))
    set(RAM_SIZE "640K")
elseif((MCU_ID STREQUAL "5E4") OR (MCU_ID STREQUAL "5F4") OR (MCU_ID STREQUAL "5E5") OR (MCU_ID STREQUAL "5F5"))
    set(RAM_SIZE "1536K")
else()
    message(SEND_ERROR "Unknown MCU type: ${MCU_ID}")
endif()

# Decode CCMRAM from MCU ID
# This values has to be set according to the MCU family because ST cannot unify
# their MCU naming convention
if((MCU_ID STREQUAL "503") OR
   (MCU_ID STREQUAL "523") OR 
   (MCU_ID STREQUAL "533") OR 
   (MCU_ID STREQUAL "543") OR 
   (MCU_ID STREQUAL "553")    )
   
    set(BACKUPRAM_SIZE "2K")
    
elseif((MCU_ID STREQUAL "562") OR 
       (MCU_ID STREQUAL "563") OR 
       (MCU_ID STREQUAL "573") OR 
       (MCU_ID STREQUAL "5F4") OR 
       (MCU_ID STREQUAL "5F5") OR 
       (MCU_ID STREQUAL "5E5") OR 
       (MCU_ID STREQUAL "5E4")    )
       
    set(BACKUPRAM_SIZE "4K")
    
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
elseif(MCU_FLASH_CODE STREQUAL "K")
    set(FLASH_SIZE "3072K")
else()
    message(SEND_ERROR "Unknown FLASH code: ${MCU_FLASH_CODE}")
endif()

# Decode high-cycle write flash size.
# The high-cycle data flash (EDATA) window of the device consists of the windows
# of both flash banks one after another (the bank 2 window follows the bank 1
# window). A sector holds 6 KB of data and a bank has 8 sectors (16 sectors on
# the H5E / H5F lines): 2 * 8 * 6K = 96K, 2 * 16 * 6K = 192K (ST CMSIS
# FLASH_EDATA_SIZE).
if((MCU_ID STREQUAL "523") OR
   (MCU_ID STREQUAL "533") OR
   (MCU_ID STREQUAL "543") OR 
   (MCU_ID STREQUAL "553") OR
   (MCU_ID STREQUAL "562") OR 
   (MCU_ID STREQUAL "563") OR
   (MCU_ID STREQUAL "573")    )
   
    set(HIGH_CYCLE_FLASH "96K")
    
elseif((MCU_ID STREQUAL "5F4") OR 
       (MCU_ID STREQUAL "5F5") OR
       (MCU_ID STREQUAL "5E4") OR 
       (MCU_ID STREQUAL "5E5")    )
       
    set(HIGH_CYCLE_FLASH "192K")
    
else()

    set(HIGH_CYCLE_FLASH "0K")
    
endif()

# Maximal number of the high-cycle data sectors of one flash bank (width of the
# EDATA_STRT field of the option bytes: 3 bits, 4 bits on the H5E / H5F lines).
if(HIGH_CYCLE_FLASH STREQUAL "96K")
    set(HIGH_CYCLE_BANK_SECTORS "8")
elseif(HIGH_CYCLE_FLASH STREQUAL "192K")
    set(HIGH_CYCLE_BANK_SECTORS "16")
else()
    set(HIGH_CYCLE_BANK_SECTORS "0")
endif()

# Number of the 8 KB sectors at the end of the flash taken by the high-cycle
# data area (EDATA option bytes of the last flash bank). The sectors are not
# available to the code and to the USER_DATA region.
if(NOT DEFINED HIGH_CYCLE_SECTORS)
    set(HIGH_CYCLE_SECTORS "0")
    message(STATUS "HIGH_CYCLE_SECTORS is not defined. Using default value.")
elseif(NOT HIGH_CYCLE_SECTORS MATCHES "^[0-9]+$")
    message(FATAL_ERROR "HIGH_CYCLE_SECTORS must be a number.")
elseif(HIGH_CYCLE_SECTORS GREATER HIGH_CYCLE_BANK_SECTORS)
    message(FATAL_ERROR "HIGH_CYCLE_SECTORS (${HIGH_CYCLE_SECTORS}) is greater than the number of high-cycle data sectors of one bank (${HIGH_CYCLE_BANK_SECTORS}) of ${TARGET_MCU_FULL_NAME}.")
endif()

math(EXPR HIGH_CYCLE_RESERVED "${HIGH_CYCLE_SECTORS} * 8192")

message(STATUS "RAM: ${RAM_SIZE}, FLASH: ${FLASH_SIZE}, HIGH_CYCLE: ${HIGH_CYCLE_FLASH}, reserved sectors: ${HIGH_CYCLE_SECTORS}")


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

# The USER_DATA region is erased by sectors (8 KB), its start has to be aligned
# to a sector to be usable by the Flash module.
math(EXPR USER_DATA_SECTOR_REMAINDER "${USER_DATA_SIZE} % 8192")
if(NOT USER_DATA_SECTOR_REMAINDER EQUAL 0)
    message(WARNING "USER_DATA_SIZE (${USER_DATA_SIZE}) is not a multiple of the 8 KB flash sector, the USER_DATA region can not be erased by the Flash module.")
endif()


set(LINKER_TEMPLATE "${CMAKE_CURRENT_LIST_DIR}/${LINKER_FILE_NAME}.in")
set(LINKER_SCRIPT   "${CMAKE_CURRENT_BINARY_DIR}/${LINKER_FILE_NAME}")

configure_file(${LINKER_TEMPLATE} ${LINKER_SCRIPT} @ONLY)

set(LINKER_SCRIPT "${CMAKE_CURRENT_BINARY_DIR}/${LINKER_FILE_NAME}" CACHE STRING "Linker script")
