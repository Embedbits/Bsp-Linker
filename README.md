# Linker Script

This component defines the memory layout and segment placement for the STM32 microcontroller firmware. It is a critical part of the BSP (Board Support Package) and is required by the linker to correctly organize code and data in the device's memory.

## Purpose

The linker script provides:
- Explicit control over memory regions such as Flash, RAM, and CCMRAM
- Placement of special sections like the vector table, `.text`, `.data`, `.bss`, and stack
- Symbols that are referenced during startup (e.g., `_sdata`, `_edata`, `_sidata`)
- Support for CMSIS-style initialization arrays (`.preinit_array`, `.init_array`)

## Key Features

- Defines `FLASH`, `USER_DATA`, `RAM` and `CCMRAM` with `ORIGIN` and `LENGTH`
- Places the vector table at the beginning of `FLASH`
- Reserves memory for:
  - Initialized data (`.data`)
  - Uninitialized data (`.bss`)
  - Data kept over system reset (`.noinit`)
  - RAM interrupt vector table (`._irqVectorTable_RAM`, written by NVIC module)
  - Heap and stack (last section in RAM, the stack grows down from the end of RAM)
- Optionally places data into `CCMRAM` (`.ccmram` section, not initialized by StartUp)
- Adds read-only permissions for `.init_array`, `.preinit_array`, and `.fini_array` to prevent RWX warnings from the linker

## STM32G4 Memory Sizes

Sizes follow the CMSIS device headers (`SRAM1_SIZE_MAX`, `SRAM2_SIZE`, `CCMSRAM_SIZE`). `RAM` is SRAM1 + SRAM2 (contiguous at `0x20000000`), `CCMRAM` is the CCM SRAM at `0x10000000`. The CCM SRAM is aliased right after SRAM2 as well - the alias is not part of `RAM`.

| Line                                   | RAM | CCMRAM | FLASH page (USER_DATA granularity) |
|----------------------------------------|-----|--------|------------------------------------|
| STM32G411x6 / x8 / xB, STM32G431, STM32G441 | 22K | 10K | 2K |
| STM32G411xC                            | 96K | 16K    | 4K (dual bank option)              |
| STM32G414                              | 40K | 20K    | 4K (dual bank option)              |
| STM32G471, STM32G473, STM32G474, STM32G483, STM32G484 | 96K | 32K | 4K (dual bank option) |
| STM32G491, STM32G4A1                   | 96K | 16K    | 2K                                 |

FLASH size is decoded from the flash code of the device name (`6` - 32K, `8` - 64K, `B` - 128K, `C` - 256K, `E` - 512K). On lines with the dual bank option (`FLASH_OPTR_DBANK`) the page has 2K in dual bank mode and 4K in single bank mode, the `USER_DATA` region therefore has to be a multiple of 4K there.

## Typical Layout

```ld
MEMORY
{
  RAM       (xrw) : ORIGIN = 0x20000000, LENGTH = 96K
  CCMRAM    (xrw) : ORIGIN = 0x10000000, LENGTH = 32K
  FLASH      (rx) : ORIGIN = 0x08000000, LENGTH = 512K - USER_DATA_SIZE
  USER_DATA  (rx) : ORIGIN = ORIGIN(FLASH) + LENGTH(FLASH), LENGTH = USER_DATA_SIZE
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

  ._irqVectorTable_RAM (NOLOAD) :
  {
    . = ALIGN(512);
    KEEP(*(._irqVectorTable_RAM*))
  } > RAM

  ._user_heap_stack :
  {
    . = . + _Min_Heap_Size;
    . = . + _Min_Stack_Size;
  } > RAM

  .ccmram (NOLOAD) :
  {
    *(.ccmram*)
  } > CCMRAM

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

- `_ccmram_start`, `_ccmram_end`: Bounds of the CCMRAM memory area
- `_sccmram`, `_eccmram`: Bounds of the `.ccmram` section in CCMRAM

- `_user_data_flash_start`, `_user_data_flash_end`: Bounds of the `.user_data_flash` section in `USER_DATA` region

- `_irqVectorTable_RAM_Start`, `_irqVectorTable_RAM_End`: Bounds of the RAM interrupt vector table

- `_estack`: Top of the stack, at the end of RAM

These symbols are used by the startup code to:

1. Copy initialized data from Flash to RAM (`.data` section)
2. Zero-initialize the `.bss` section
3. Set the initial stack pointer
4. Relocate the vector table to RAM (NVIC module)

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

extern uint32_t _ram_start;
extern uint32_t _ram_length;
extern uint32_t _ram_end;
```
---

## 🛠 CMake Integration

1. Set `TARGET_MCU_FULL_NAME` to the STM32G4 device name (generic form, e.g. `STM32G474xE`, or full order code, e.g. `STM32G474RET6`).
2. Optionally set `USER_DATA_SIZE` (in bytes) to reserve a region at the end of FLASH for user data. The size must be a multiple of the FLASH page size (2K, 4K on lines with the dual bank option - see the table above) and smaller than FLASH.
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