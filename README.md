# Linker Script

This component defines the memory layout and segment placement for the STM32 microcontroller firmware. It is a critical part of the BSP (Board Support Package) and is required by the linker to correctly organize code and data in the device's memory.

## Purpose

The linker script provides:
- Explicit control over memory regions such as Flash, RAM, ITCM RAM and Backup SRAM
- Placement of special sections like the vector table, `.text`, `.data`, `.bss`, and stack
- Symbols that are referenced during startup (e.g., `_sdata`, `_edata`, `_sidata`)
- Support for CMSIS-style initialization arrays (`.preinit_array`, `.init_array`)

## Key Features

- Defines `FLASH`, `USER_DATA`, `RAM`, `ITCMRAM` and `BKPRAM` with `ORIGIN` and `LENGTH`
- `RAM` is the contiguous RAM at `0x20000000` - DTCM followed by SRAM1 and SRAM2 (256K on STM32F72x/F73x, 320K on STM32F74x/F75x, 512K on STM32F76x/F77x)
- Places the vector table at the beginning of `FLASH`
- Reserves memory for:
  - Initialized data (`.data`)
  - Uninitialized data (`.bss`)
  - Heap and stack
- Optionally places data or code into instruction RAM `ITCMRAM` (`.itcmram` section, 16K at `0x00000000`) - content is not initialized by StartUp
- Optionally places data into battery backed `BKPRAM` (`.bkpram` section, 4K at `0x40024000`)
- Adds read-only permissions for `.init_array`, `.preinit_array`, and `.fini_array` to prevent RWX warnings from the linker

## Typical Layout

```ld
MEMORY
{
  FLASH    (rx)  : ORIGIN = 0x08000000, LENGTH = 512K
  RAM      (xrw) : ORIGIN = 0x20000000, LENGTH = 320K
  ITCMRAM  (xrw) : ORIGIN = 0x00000000, LENGTH = 16K
  BKPRAM   (rw)  : ORIGIN = 0x40024000, LENGTH = 4K
}

SECTIONS
{
  .isr_vector :
  {
    KEEP(*(.isr_vector))
  } > FLASH

  .text :
  {
    *(.text*)
    *(.rodata*)
  } > FLASH

  .data : AT (_etext)
  {
    _sdata = .;
    *(.data*)
    _edata = .;
  } > RAM

  .bss :
  {
    _sbss = .;
    *(.bss*)
    _ebss = .;
  } > RAM

  .itcmram (NOLOAD) :
  {
    *(.itcmram*)
  } > ITCMRAM

  .bkpram (NOLOAD) :
  {
    *(.bkpram*)
  } > BKPRAM

  /* Initialization arrays */
  .preinit_array (READONLY) :
  {
    KEEP(*(.preinit_array))
  } > FLASH

  .init_array (READONLY) :
  {
    KEEP(*(.init_array))
  } > FLASH
}
```

## Symbols Provided

The linker script defines symbols used in the startup and initialization process:

- `_sidata`: Start address of the initial values for the `.data` section, typically located in Flash
- `_sdata`: Start address of the `.data` section in RAM
- `_edata`: End address of the `.data` section in RAM

- `_sbss`: Start address of the `.bss` section (uninitialized data) in RAM
- `_ebss`: End address of the `.bss` section in RAM

- `_dtcm_start`, `_dtcm_end`: Bounds of the DTCM part of `RAM`
- `_itcmram_start`, `_itcmram_end`: Bounds of the ITCM RAM memory area
- `_sitcmram`, `_eitcmram`: Bounds of the `.itcmram` section in ITCM RAM

- `_bkpram_start`, `_bkpram_end`: Bounds of the Backup SRAM memory area (optional)
- `_sbkpram`, `_ebkpram`: Bounds of the `.bkpram` section in Backup SRAM

- `_user_data_flash_start`, `_user_data_flash_end`: Bounds of the `.user_data_flash` section in `USER_DATA` region

- `_irqVectorTable_RAM_Start`, `_irqVectorTable_RAM_End`: Bounds of the RAM interrupt vector table

- `_estack`: Top of the stack, at the end of RAM

These symbols are used by the startup code to:

1. Copy initialized data from Flash to RAM (`.data` section)
2. Zero-initialize the `.bss` section
3. Set the initial stack pointer
4. Optionally relocate the vector table to RAM if needed

## Usage Notes

- The linker script must be kept in sync with the memory configuration defined in your project settings.
- Any custom sections added in your code (e.g., `.itcmram`, `.bootloader`, `.shared`) must be accounted for in the linker script.
- Cortex-M7 caches are not enabled by the BSP. When the application enables the D-Cache, DMA buffers in SRAM1 / SRAM2 need cache maintenance (DTCM is not cached).
- Pay attention to alignment and section permissions to avoid hard faults or unexpected behavior.

## Integration

The linker file script is generated from `Linker.ld.in` by CMake and depends on configured STM32 MCU.

Ensure your compiler and linker flags allow usage of these symbols in your C code, typically via:

```c
extern uint32_t _sdata;
extern uint32_t _edata;
extern uint32_t _sidata;
extern uint32_t _sbss;
extern uint32_t _ebss;

extern uint32_t _itcmram_start;
extern uint32_t _itcmram_length;
extern uint32_t _itcmram_end;

extern uint32_t _bkpram_start;
extern uint32_t _bkpram_length;
extern uint32_t _bkpram_end;

extern uint32_t _ram_start;
extern uint32_t _ram_length;
extern uint32_t _ram_end;
```
---

## 🛠 CMake Integration

1. Set `TARGET_MCU_FULL_NAME` to the STM32F7 device name (generic form, e.g. `STM32F746xG`, or full order code, e.g. `STM32F746NGH6`).
2. Optionally set `USER_DATA_SIZE` (in bytes) to reserve a region at the end of FLASH for user data. The size must be a multiple of the last FLASH sector size, since only whole sectors can be erased: STM32F72x/F73x 16K for 64K FLASH, 128K otherwise; STM32F74x-F77x 32K for 64K FLASH, 256K otherwise (single bank mode).
3. Include `Linker.cmake` - it configures Cortex-M7 / hard-float compiler flags (FPv5-D16 on STM32F76x/F77x, FPv5-SP-D16 on other lines) and generates `Linker.ld` into the binary directory.
4. Pass the generated script (`LINKER_SCRIPT` cache variable) to the linker with `-T`.

---

## License

This project is licensed under the **Creative Commons Attribution–NonCommercial 4.0 International (CC BY-NC 4.0)**.

You are free to use, modify, and share this work for **non-commercial purposes**, provided appropriate credit is given.

See [LICENSE.md](LICENSE.md) for full terms or visit [creativecommons.org/licenses/by-nc/4.0](https://creativecommons.org/licenses/by-nc/4.0/).

---

## Authors

- **Mr.Nobody** — [embedbits.com](https://embedbits.com)

Contributions are welcome! Please open a pull request.

---

## 🌐 Useful Links

- [STM32CubeIDE](https://www.st.com/en/development-tools/stm32cubeide.html)
- [Azure DevOps](https://azure.microsoft.com/en-us/services/devops/)
- [Embedbits Github](https://github.com/Embedbits)
- [CC BY-NC 4.0 License](https://creativecommons.org/licenses/by-nc/4.0/)