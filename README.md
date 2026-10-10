# Linker Script

This component defines the memory layout and segment placement for the STM32 microcontroller firmware. It is a critical part of the BSP (Board Support Package) and is required by the linker to correctly organize code and data in the device's memory.

## Purpose

The linker script provides:
- Explicit control over memory regions such as Flash, RAM, and CCMRAM
- Placement of special sections like the vector table, `.text`, `.data`, `.bss`, and stack
- Symbols that are referenced during startup (e.g., `_sdata`, `_edata`, `_sidata`)
- Support for CMSIS-style initialization arrays (`.preinit_array`, `.init_array`)

## Key Features

- Defines `FLASH`, `RAM`, and optionally `CCMRAM` with `ORIGIN` and `LENGTH`
- Places the vector table at the beginning of `FLASH`
- Reserves memory for:
  - Initialized data (`.data`)
  - Uninitialized data (`.bss`)
  - Heap and stack
- Optionally places critical data or stack in `CCMRAM` for faster access
- Adds read-only permissions for `.init_array`, `.preinit_array`, and `.fini_array` to prevent RWX warnings from the linker

## Typical Layout

```ld
MEMORY
{
  FLASH    (rx)  : ORIGIN = 0x08000000, LENGTH = 512K
  RAM      (xrw) : ORIGIN = 0x20000000, LENGTH = 128K
  CCMRAM   (xrw) : ORIGIN = 0x10000000, LENGTH = 64K
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

  .stack :
  {
    . = ALIGN(8);
    _stack_top = .;
  } > RAM

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

- `_stack_top`: Top of the stack, usually at the end of RAM

These symbols are used by the startup code to:

1. Copy initialized data from Flash to RAM (`.data` section)
2. Zero-initialize the `.bss` section
3. Set the initial stack pointer
4. Optionally relocate the vector table to RAM or CCMRAM if needed

## Flash Data Regions

Besides the code, the linker script defines two flash regions for the data written at run time (by the Flash MCAL module):

| Region | Origin | Length | Meaning |
|---|---|---|---|
| `FLASH` | `0x08000000` | flash size - `HIGH_CYCLE_RESERVED` - `USER_DATA_SIZE` | Code and constants |
| `USER_DATA` | end of `FLASH` | `USER_DATA_SIZE` | Part of the user flash for runtime data (section `.user_data_flash`, no load) |
| `HIGH_CYCLE` | `0x09000000` | 96K / 192K / 0K | High-cycle data flash (EDATA) window of both flash banks, 0 on the lines without it |

CMake variables (default 0):

- `USER_DATA_SIZE` - size of the `USER_DATA` region in bytes. Shall be a multiple of the 8 KB flash sector (CMake warns otherwise): the region is erased by sectors.
- `HIGH_CYCLE_SECTORS` - number of 8 KB sectors at the end of the flash taken by the high-cycle data area (EDATA option bytes of the last flash bank), at most the number of sectors of one bank (8, 16 on the H5E / H5F lines, 0 on the lines without the high-cycle data). `FLASH` and `USER_DATA` end before them.

Symbols (bounds of the regions, in the style of `_flash_start`): `_user_data_start`, `_user_data_length`, `_user_data_end`, `_high_cycle_start`, `_high_cycle_length`, `_high_cycle_end` and `_high_cycle_sectors` (value of `HIGH_CYCLE_SECTORS`, to be compared with the option bytes at run time). `_user_data_flash_start` and `_user_data_flash_end` are different: they bound only the objects placed in the section `.user_data_flash`, not the region.

## Usage Notes

- The linker script must be kept in sync with the memory configuration defined in your project settings.
- Any custom sections added in your code (e.g., `.ccmram`, `.bootloader`, `.shared`) must be accounted for in the linker script.
- Pay attention to alignment and section permissions to avoid hard faults or unexpected behavior.

## Integration

The linker file script is generated from STM32G4xx_Linker.ld.in by CMake and depends on configured STM32 MCU.

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

extern uint32_t _ram_start;
extern uint32_t _ram_length;
extern uint32_t _ram_end;
```
---

## 🛠 CMake Integration

1. Include `Nvic_Lib` in your CMake library.
2. Include `Nvic_Port.h` in your project.
3. Link against the Nvic module implementation files.
4. Configure the module as needed for your hardware.

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