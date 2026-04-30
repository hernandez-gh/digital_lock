<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

The design is based on a synchronous FSM with the following states:

- `S0` → انتظار primer código  
- `S1` → segundo código correcto  
- `S2` → tercer código correcto  
- `S3` → cuarto código correcto  
- `UNLOCKED` → acceso concedido  
- `LOCKED` → sistema bloqueado tras 3 errores  

Each step is validated when the `enter` signal generates a rising edge.

If a wrong code is entered:
- The error signal is activated
- The attempt counter increments
- The FSM resets to the initial state (`S0`)
- After 3 attempts → `LOCKED`

---

## Inputs

| Pin | Name       | Description |
|-----|-----------|------------|
| ui[0] | clear     | Resets the system |
| ui[1] | enter     | Validates current input |
| ui[2] | code_in[0] | LSB of input code |
| ui[3] | code_in[1] | MSB of input code |

---

## Outputs

| Pin | Name    | Description |
|-----|--------|------------|
| uo[0] | unlock | High when correct sequence is entered |
| uo[1] | error  | High when an incorrect attempt occurs (stretched for visibility) |
| uo[2] | locked | High after 3 failed attempts |

---

## Internal Features

- FSM-based design
- Rising edge detection on `enter`
- Attempt counter (2-bit)
- Error pulse stretcher using a counter
- Fully synchronous logic
- Active-low reset (`rst_n`)

---

## How to test

1. Apply reset (`rst_n = 0 → 1`)
2. Enter each 2-bit code
3. Pulse `enter` for each step
4. Observe outputs:
   - `unlock = 1` → success
   - `error = 1` → incorrect step
   - `locked = 1` → system blocked

Use `clear` to restart the process at any time.

---

## Notes

- The error signal is extended using a timer so it can be observed on LEDs.
- The design is optimized for Tiny Tapeout constraints (small area, simple logic).
- Unused IOs are safely tied off.

---

## External hardware

No external hardware is used for this project
