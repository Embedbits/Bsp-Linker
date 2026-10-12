# Linker Script

This component defines the memory layout and segment placement for the STM32 microcontroller firmware. It is a critical part of the BSP (Board Support Package) and is required by the linker to correctly organize code and data in the device's memory.

## Purpose

The linker script provides:
- Explicit control over memory regions such as Flash, AXI SRAM, TCM RAMs, domain SRAMs and Backup SRAM
- Placement of special sections like the vector table, `.text`, `.data`, `.bss`, and stack
- Symbols that are referenced during startup (e.g., `_sdata`, `_edata`, `_sidata`)
- Support for CMSIS-style initialization arrays (`.preinit_array`, `.init_array`)

## Key Features

- Defines `FLASH`, `FLASH2`, `USER_DATA`, `RAM`, `DTCMRAM`, `ITCMRAM`, `RAM_D2`, `RAM_D3` and `BKPSRAM` with `ORIGIN` and `LENGTH`
- Places the vector table at the beginning of `FLASH`
- Places all firmware data (`.data`, `.bss`, `.noinit`, heap, stack and the RAM interrupt vector table) into the AXI SRAM (`RAM` at `0x24000000`) - the only large RAM accessible by the CPU and by all DMA controllers (DTCM is not accessible by DMA1 / DMA2 / BDMA)
- Optionally places data into:
  - `DTCMRAM` (`.dtcmram` section) - zero wait state RAM of the CPU, not accessible by DMA
  - `RAM_D2` (`.ram_d2` section) - AHB SRAM of D2 / CD domain, e.g. DMA buffers of D2 peripherals
  - `RAM_D3` (`.ram_d3` section) - SRAM of D3 / SRD domain, the only RAM accessible by BDMA
  - `BKPSRAM` (`.bkpsram` section) - battery backed 4K Backup SRAM at `0x38800000`
  - `FLASH2` (`.flash2` section) - constant data in FLASH bank 2 of 1M dual-bank devices
- Content of the optional sections is not initialized by StartUp (`NOLOAD`). All STM32H7 RAMs are protected by ECC - write data before reading them after power-on
- Adds read-only permissions for `.init_array`, `.preinit_array`, and `.fini_array` to prevent RWX warnings from the linker

## Memory Map

Sizes according to the device linker templates of STMicroelectronics (`stm32h7xx_dfp`), default option bytes:

| Line | RAM (AXI SRAM) | DTCMRAM | ITCMRAM | RAM_D2 | RAM_D3 | BKPSRAM | FLASH sector |
|------|----------------|---------|---------|--------|--------|---------|--------------|
| STM32H723 / H725 / H730 / H733 / H735 | 320K | 128K | 64K | 32K | 16K | 4K | 128K |
| STM32H742 | 384K | 128K | 64K | 32K (SRAM1) | 64K | 4K | 128K |
| STM32H743 / H745 / H747 / H750 / H753 / H755 / H757 | 512K | 128K | 64K | 288K | 64K | 4K | 128K |
| STM32H7A3 / H7B0 / H7B3 | 1024K | 128K | 64K | 128K | 32K | 4K | 8K |
| STM32H7R3 / H7R7 / H7S3 / H7S7 | 456K | 64K | 64K | 32K | - | 4K | 8K |

FLASH starts at `0x08000000`:
- 1M dual-bank devices (STM32H742xG, H743xG, H7A3xG) have two 512K banks at `0x08000000` and `0x08100000` - `FLASH` is bank 1, `FLASH2` is bank 2
- Dual-core devices (STM32H745, H747, H755, H757) - firmware of the Cortex-M7 core is placed into bank 1 only, bank 2 (`0x08100000`) is the boot area of the Cortex-M4 core
- Other devices use the whole FLASH as one region

## Typical Layout

```ld
MEMORY
{
  RAM      (xrw) : ORIGIN = 0x24000000, LENGTH = 512K
  DTCMRAM  (xrw) : ORIGIN = 0x20000000, LENGTH = 128K
  ITCMRAM  (xrw) : ORIGIN = 0x00000000, LENGTH = 64K
  RAM_D2   (xrw) : ORIGIN = 0x30000000, LENGTH = 288K
  RAM_D3   (xrw) : ORIGIN = 0x38000000, LENGTH = 64K
  BKPSRAM   (rw) : ORIGIN = 0x38800000, LENGTH = 4K
  FLASH     (rx) : ORIGIN = 0x08000000, LENGTH = 2048K
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

  .dtcmram (NOLOAD) :
  {
    *(.dtcmram*)
  } > DTCMRAM

  .ram_d3 (NOLOAD) :
  {
    *(.ram_d3*)
  } > RAM_D3

  .bkpsram (NOLOAD) :
  {
    *(.bkpsram*)
  } > BKPSRAM
}
```

## Symbols Provided

The linker script defines symbols used in the startup and initialization process:

- `_sidata`: Start address of the initial values for the `.data` section, typically located in Flash
- `_sdata`: Start address of the `.data` section in RAM
- `_edata`: End address of the `.data` section in RAM

- `_sbss`: Start address of the `.bss` section (uninitialized data) in RAM
- `_ebss`: End address of the `.bss` section in RAM

- `_ram_start`, `_ram_end`: Bounds of the AXI SRAM memory area
- `_dtcmram_start`, `_dtcmram_end` / `_sdtcmram`, `_edtcmram`: Bounds of the DTCM memory area / `.dtcmram` section
- `_itcmram_start`, `_itcmram_end`: Bounds of the ITCM memory area
- `_ram_d2_start`, `_ram_d2_end` / `_sram_d2`, `_eram_d2`: Bounds of the D2 SRAM memory area / `.ram_d2` section
- `_ram_d3_start`, `_ram_d3_end` / `_sram_d3`, `_eram_d3`: Bounds of the D3 SRAM memory area / `.ram_d3` section
- `_bkpsram_start`, `_bkpsram_end` / `_sbkpsram`, `_ebkpsram`: Bounds of the Backup SRAM memory area / `.bkpsram` section
- `_flash_start`, `_flash_end`: Bounds of the FLASH region (bank 1)
- `_flash2_start`, `_flash2_end` / `_sflash2`, `_eflash2`: Bounds of the FLASH2 region (bank 2) / `.flash2` section

- `_user_data_flash_start`, `_user_data_flash_end`: Bounds of the `.user_data_flash` section in `USER_DATA` region

- `_irqVectorTable_RAM_Start`, `_irqVectorTable_RAM_End`: Bounds of the RAM interrupt vector table

- `_estack`: Top of the stack, at the end of RAM (AXI SRAM)

These symbols are used by the startup code to:

1. Copy initialized data from Flash to RAM (`.data` section)
2. Zero-initialize the `.bss` section
3. Set the initial stack pointer
4. Optionally relocate the vector table to RAM if needed

## Usage Notes

- The linker script must be kept in sync with the memory configuration defined in your project settings.
- Any custom sections added in your code (e.g., `.dtcmram`, `.bootloader`, `.shared`) must be accounted for in the linker script.
- DMA buffers must not be placed into `DTCMRAM` / `ITCMRAM`; buffers of BDMA (D3 / SRD domain peripherals) must be placed into `RAM_D3` (`.ram_d3`).
- When the Cortex-M7 data cache is enabled, DMA buffers need cache maintenance or a non-cacheable MPU region.
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

extern uint32_t _ram_start;
extern uint32_t _ram_length;
extern uint32_t _ram_end;

extern uint32_t _dtcmram_start;
extern uint32_t _dtcmram_length;
extern uint32_t _dtcmram_end;

extern uint32_t _bkpsram_start;
extern uint32_t _bkpsram_length;
extern uint32_t _bkpsram_end;
```
---

## 🛠 CMake Integration

1. Set `TARGET_MCU_FULL_NAME` to the STM32H7 device name (generic form, e.g. `STM32H743xI`, or full order code, e.g. `STM32H743ZIT6`).
2. Optionally set `USER_DATA_SIZE` (in bytes) to reserve a region at the end of FLASH (end of bank 1) for user data. The size must be a multiple of the FLASH sector size (128K on STM32H72x/73x/74x/75x, 8K on STM32H7A3/7B0/7B3/7R/7S), since only whole sectors can be erased.
3. Include `Linker.cmake` - it configures Cortex-M7 / FPv5-D16 / hard-float compiler flags and generates `Linker.ld` into the binary directory.
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
