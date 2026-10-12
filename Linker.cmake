#============================ Build configuration =============================#

# Configure core type
set(CMAKE_C_FLAGS      "${CMAKE_C_FLAGS} ${MCPU_CORTEX_M7}")
set(CMAKE_CXX_FLAGS    "${CMAKE_CXX_FLAGS} ${MCPU_CORTEX_M7}")

# Configure Floating-Point unit
set(CMAKE_C_FLAGS      "${CMAKE_C_FLAGS} ${MFPU_FPV5_D16}")
set(CMAKE_CXX_FLAGS    "${CMAKE_CXX_FLAGS} ${MFPU_FPV5_D16}")

# Configure FPU
set(CMAKE_C_FLAGS      "${CMAKE_C_FLAGS} ${MFLOAT_ABI_HARDWARE}")
set(CMAKE_CXX_FLAGS    "${CMAKE_CXX_FLAGS} ${MFLOAT_ABI_HARDWARE}")

#============================== Constant values ===============================#

# Include current directory for provide headers include
include_directories(${CMAKE_CURRENT_SOURCE_DIR})

# Path to the folder with linker files
set(LINKER_FILES_PATH "${CMAKE_CURRENT_LIST_DIR}")

# STM32H7 lines (subfamily identifiers) with the same memory map
set(LINKER_H7_LINE_H72X     "723" "725" "730" "733" "735")
set(LINKER_H7_LINE_H742     "742")
set(LINKER_H7_LINE_H74X     "743" "745" "747" "750" "753" "755" "757")
set(LINKER_H7_LINE_H7AX     "7A3" "7B0" "7B3")
set(LINKER_H7_LINE_H7RS     "7R3" "7R7" "7S3" "7S7")

# Dual-core lines - FLASH bank 2 (0x08100000) is the boot area of the
# Cortex-M4 core, Cortex-M7 firmware is placed into bank 1 only
set(LINKER_H7_DUAL_CORE     "745" "747" "755" "757")

# Dual-bank lines - FLASH bank 2 always starts at 0x08100000, devices with
# banks smaller than 1M (1M FLASH devices) have a hole between the banks
set(LINKER_H7_DUAL_BANK     "742" "743" "753" "7A3" "7B3")

#=========================== Linker file selection ===========================#

set(LINKER_FILE_NAME "Linker.ld")

message(STATUS "MCU target: ${TARGET_MCU_FULL_NAME}")

# Generic extraction of the subfamily identifier (three chars right after the
# one-letter STM32 family code) from the STM32 MCU name. Works unchanged for
# both the generic placeholder form (e.g. STM32H743xI) and a full order code
# (e.g. STM32H743ZIT6) - the subfamily code always sits in that position for
# either form.
string(REGEX MATCH "STM32.([0-9A-Z][0-9A-Z][0-9A-Z])" _ ${TARGET_MCU_FULL_NAME})
set(MCU_ID "${CMAKE_MATCH_1}")
message(STATUS "MCU_ID: ${MCU_ID}")

# Dual-core lines - the CMSIS device header (stm32h7xx.h) stops with an #error
# unless the core is selected, so every source (Ral, Mcal, tests) is compiled
# for the Cortex-M7 core, which runs the firmware
if(MCU_ID IN_LIST LINKER_H7_DUAL_CORE)
    add_compile_definitions(CORE_CM7)
endif()

# Extraction of FLASH identification.
#
# Generic placeholder form (STM32H743xI): the flash-size letter is the char
# right after the literal "x" placeholder.
# Full order code form (STM32H743ZIT6): the flash-size letter is the char
# right after the real pin-count/package letter ("Z" here).
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
# The firmware RAM (data, bss, heap, stack) is the AXI SRAM at 0x24000000 -
# accessible by the CPU and by all DMA controllers (DTCM at 0x20000000 is not
# accessible by DMA1 / DMA2). Sizes of the AXI SRAM according to the device
# linker templates of STMicroelectronics (stm32h7xx_dfp).
if(MCU_ID IN_LIST LINKER_H7_LINE_H72X)

    # 128K AXI SRAM + 192K shared AXI / ITCM SRAM (default option bytes)
    set(RAM_SIZE "320K")

elseif(MCU_ID IN_LIST LINKER_H7_LINE_H742)

    set(RAM_SIZE "384K")

elseif(MCU_ID IN_LIST LINKER_H7_LINE_H74X)

    set(RAM_SIZE "512K")

elseif(MCU_ID IN_LIST LINKER_H7_LINE_H7AX)

    # CD-SRAM1 + CD-SRAM2 + CD-SRAM3 (AXI)
    set(RAM_SIZE "1024K")

elseif(MCU_ID IN_LIST LINKER_H7_LINE_H7RS)

    # AXI SRAM1 - SRAM4 (default option bytes - no extra TCM)
    set(RAM_SIZE "456K")

else()
    set(RAM_SIZE "0")
    message(SEND_ERROR "Unknown MCU type: ${MCU_ID}")
endif()

# Decode tightly coupled memories and domain SRAMs from MCU ID
# DTCM (0x20000000) and ITCM (0x00000000) are accessible by the CPU (and MDMA)
# only. D2 SRAM (AHB SRAM at 0x30000000) is the contiguous part of the D2 / CD
# domain SRAM, D3 SRAM (SRAM4 / SRD SRAM at 0x38000000) is the only RAM
# accessible by BDMA of D3 / SRD domain peripherals.
if(MCU_ID IN_LIST LINKER_H7_LINE_H72X)

    set(DTCMRAM_SIZE "128K")
    set(ITCMRAM_SIZE "64K")
    set(RAM_D2_SIZE  "32K")
    set(RAM_D3_SIZE  "16K")

elseif(MCU_ID IN_LIST LINKER_H7_LINE_H742)

    # SRAM1 32K only - SRAM2 (16K at 0x30020000) is not contiguous
    set(DTCMRAM_SIZE "128K")
    set(ITCMRAM_SIZE "64K")
    set(RAM_D2_SIZE  "32K")
    set(RAM_D3_SIZE  "64K")

elseif(MCU_ID IN_LIST LINKER_H7_LINE_H74X)

    # SRAM1 128K + SRAM2 128K + SRAM3 32K
    set(DTCMRAM_SIZE "128K")
    set(ITCMRAM_SIZE "64K")
    set(RAM_D2_SIZE  "288K")
    set(RAM_D3_SIZE  "64K")

elseif(MCU_ID IN_LIST LINKER_H7_LINE_H7AX)

    # AHB SRAM1 64K + AHB SRAM2 64K, SRD SRAM 32K
    set(DTCMRAM_SIZE "128K")
    set(ITCMRAM_SIZE "64K")
    set(RAM_D2_SIZE  "128K")
    set(RAM_D3_SIZE  "32K")

elseif(MCU_ID IN_LIST LINKER_H7_LINE_H7RS)

    # AHB SRAM1 16K + AHB SRAM2 16K, no SRAM in D3 domain
    set(DTCMRAM_SIZE "64K")
    set(ITCMRAM_SIZE "64K")
    set(RAM_D2_SIZE  "32K")
    set(RAM_D3_SIZE  "0")

else()

    set(DTCMRAM_SIZE "0")
    set(ITCMRAM_SIZE "0")
    set(RAM_D2_SIZE  "0")
    set(RAM_D3_SIZE  "0")

endif()

# Decode Backup SRAM from MCU ID
# Backup SRAM (4K, battery backed when VBAT is supplied) is available on all
# STM32H7 devices at 0x38800000.
if(NOT MCU_ID STREQUAL "")

    set(BKPSRAM_SIZE "4K")

else()

    set(BKPSRAM_SIZE "0")
    message(STATUS "Unknown MCU type: ${MCU_ID}")

endif()

# Decode FLASH from MCU ID
if(MCU_FLASH_CODE STREQUAL "8")
    set(FLASH_SIZE_KB 64)
elseif(MCU_FLASH_CODE STREQUAL "B")
    set(FLASH_SIZE_KB 128)
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

# FLASH region of the firmware (bank 1 at 0x08000000) and FLASH2 region (bank 2
# at 0x08100000) when the banks are not contiguous
math(EXPR FLASH_BANK_SIZE_KB "${FLASH_SIZE_KB} / 2")

if(MCU_ID IN_LIST LINKER_H7_DUAL_CORE)

    # Bank 2 belongs to the Cortex-M4 core
    set(FLASH_REGION_SIZE_KB  ${FLASH_BANK_SIZE_KB})
    set(FLASH2_REGION_SIZE_KB 0)

elseif((MCU_ID IN_LIST LINKER_H7_DUAL_BANK) AND
       (FLASH_BANK_SIZE_KB LESS 1024)            )

    # Banks are not contiguous (bank 2 at 0x08100000)
    set(FLASH_REGION_SIZE_KB  ${FLASH_BANK_SIZE_KB})
    set(FLASH2_REGION_SIZE_KB ${FLASH_BANK_SIZE_KB})

else()

    set(FLASH_REGION_SIZE_KB  ${FLASH_SIZE_KB})
    set(FLASH2_REGION_SIZE_KB 0)

endif()

set(FLASH_SIZE  "${FLASH_REGION_SIZE_KB}K")
set(FLASH2_SIZE "${FLASH2_REGION_SIZE_KB}K")

message(STATUS "RAM: ${RAM_SIZE}, DTCMRAM: ${DTCMRAM_SIZE}, ITCMRAM: ${ITCMRAM_SIZE}, RAM_D2: ${RAM_D2_SIZE}, "
               "RAM_D3: ${RAM_D3_SIZE}, BKPSRAM: ${BKPSRAM_SIZE}, FLASH: ${FLASH_SIZE}, FLASH2: ${FLASH2_SIZE}")


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

# Only a whole FLASH sector can be erased. The USER_DATA region is placed at the
# end of the FLASH region (end of bank 1), so it has to consist of whole
# sectors, otherwise erasing the user data would erase application code as
# well. Sector size is 128K on STM32H72x/73x/742/743/745/747/750/753/755/757
# and 8K on STM32H7A3/7B0/7B3/7R3/7R7/7S3/7S7.
if(USER_DATA_SIZE GREATER 0)

    if((MCU_ID IN_LIST LINKER_H7_LINE_H7AX) OR
       (MCU_ID IN_LIST LINKER_H7_LINE_H7RS)    )
        set(FLASH_SECTOR_KB 8)
    else()
        set(FLASH_SECTOR_KB 128)
    endif()

    math(EXPR FLASH_SECTOR_SIZE        "${FLASH_SECTOR_KB} * 1024")
    math(EXPR FLASH_REGION_SIZE_BYTES  "${FLASH_REGION_SIZE_KB} * 1024")
    math(EXPR USER_DATA_SECTOR_REM     "${USER_DATA_SIZE} % ${FLASH_SECTOR_SIZE}")

    if(NOT USER_DATA_SECTOR_REM EQUAL 0)
        message(FATAL_ERROR "USER_DATA_SIZE (${USER_DATA_SIZE}) must be a multiple "
                            "of the FLASH sector size (${FLASH_SECTOR_SIZE}).")
    endif()

    if(NOT USER_DATA_SIZE LESS FLASH_REGION_SIZE_BYTES)
        message(FATAL_ERROR "USER_DATA_SIZE (${USER_DATA_SIZE}) must be smaller "
                            "than FLASH size (${FLASH_REGION_SIZE_BYTES}).")
    endif()

endif()


set(LINKER_TEMPLATE "${CMAKE_CURRENT_LIST_DIR}/${LINKER_FILE_NAME}.in")
set(LINKER_SCRIPT   "${CMAKE_CURRENT_BINARY_DIR}/${LINKER_FILE_NAME}")

configure_file(${LINKER_TEMPLATE} ${LINKER_SCRIPT} @ONLY)

set(LINKER_SCRIPT "${CMAKE_CURRENT_BINARY_DIR}/${LINKER_FILE_NAME}" CACHE STRING "Linker script")
