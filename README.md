# Linker Script

This component defines the memory layout and segment placement for the STM32 microcontroller firmware. It is a critical part of the BSP (Board Support Package) and is required by the linker to correctly organize code and data in the device's memory.

## Purpose

The linker script provides:
- Explicit control over memory regions such as Flash, RAM, and CCMRAM
- Placement of special sections like the vector table, `.text`, `.data`, `.bss`, and stack
- Symbols that are referenced during startup (e.g., `_sdata`, `_edata`, `_sidata`)
- Support for CMSIS-style initialization arrays (`.preinit_array`, `.init_array`)

## Key Features

- Defines `FLASH`, `USER_DATA`, `RAM`, and optionally `CCMRAM` and `BKPRAM` with `ORIGIN` and `LENGTH`
- Places the vector table at the beginning of `FLASH`
- Reserves memory for:
  - Initialized data (`.data`)
  - Uninitialized data (`.bss`)
  - Heap and stack
- Optionally places data into `CCMRAM` (`.ccmram` section) for faster access - on STM32F4 the CCMRAM is data-only (no code execution, no DMA access)
- Optionally places data into battery backed `BKPRAM` (`.bkpram` section, 4K at `0x40024000`)
- Adds read-only permissions for `.init_array`, `.preinit_array`, and `.fini_array` to prevent RWX warnings from the linker

## Typical Layout

```ld
MEMORY
{
  FLASH    (rx)  : ORIGIN = 0x08000000, LENGTH = 512K
  RAM      (xrw) : ORIGIN = 0x20000000, LENGTH = 128K
  CCMRAM   (rw)  : ORIGIN = 0x10000000, LENGTH = 64K
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

  .ccm_data :
  {
    *(.ccmram*)
  } > CCMRAM

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

- `_ccmram_start`, `_ccmram_end`: Bounds of the CCMRAM memory area (optional)
- `_sccmram`, `_eccmram`: Bounds of the `.ccmram` section in CCMRAM

- `_bkpram_start`, `_bkpram_end`: Bounds of the Backup SRAM memory area (optional)
- `_sbkpram`, `_ebkpram`: Bounds of the `.bkpram` section in Backup SRAM

- `_user_data_flash_start`, `_user_data_flash_end`: Bounds of the `.user_data_flash` section in `USER_DATA` region

- `_irqVectorTable_RAM_Start`, `_irqVectorTable_RAM_End`: Bounds of the RAM interrupt vector table

- `_estack`: Top of the stack, at the end of RAM

These symbols are used by the startup code to:

1. Copy initialized data from Flash to RAM (`.data` section)
2. Zero-initialize the `.bss` section
3. Set the initial stack pointer
4. Optionally relocate the vector table to RAM if needed (CCMRAM cannot hold the vector table on STM32F4)

## Usage Notes

- The linker script must be kept in sync with the memory configuration defined in your project settings.
- Any custom sections added in your code (e.g., `.ccmram`, `.bootloader`, `.shared`) must be accounted for in the linker script.
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

extern uint32_t _ccmram_start;
extern uint32_t _ccmram_length;
extern uint32_t _ccmram_end;

extern uint32_t _bkpram_start;
extern uint32_t _bkpram_length;
extern uint32_t _bkpram_end;

extern uint32_t _ram_start;
extern uint32_t _ram_length;
extern uint32_t _ram_end;
```
---

## 🛠 CMake Integration

1. Set `TARGET_MCU_FULL_NAME` to the STM32F4 device name (generic form, e.g. `STM32F411xE`, or full order code, e.g. `STM32F411VET6`).
2. Optionally set `USER_DATA_SIZE` (in bytes) to reserve a region at the end of FLASH for user data. The size must be a multiple of the last FLASH sector size (16K for 64K FLASH, 64K for 128K FLASH, 128K otherwise), since only whole sectors can be erased.
3. Include `Linker.cmake` - it configures Cortex-M4 / FPv4-SP-D16 / hard-float compiler flags and generates `Linker.ld` into the binary directory.
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