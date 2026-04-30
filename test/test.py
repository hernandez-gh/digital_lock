# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.triggers import RisingEdge, Timer
from cocotb.clock import Clock

CLK_PERIOD_NS = 83  # ~12 MHz

# -----------------------
# Helpers
# -----------------------

async def reset(dut):
    dut.rst_n.value = 0
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.ena.value = 1

    await Timer(200, unit="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)


async def send_code(dut, code):
    """
    code: int (2 bits)
    ui[1] = enter
    ui[3:2] = code_in
    """
    dut.ui_in.value = (code << 2) | (1 << 1)  # enter=1
    await RisingEdge(dut.clk)

    dut.ui_in.value = (code << 2)  # enter=0
    await RisingEdge(dut.clk)


async def press_clear(dut):
    dut.ui_in.value = 1 << 0  # clear=1
    await RisingEdge(dut.clk)
    dut.ui_in.value = 0
    await RisingEdge(dut.clk)


# -----------------------
# TEST 1: Unlock correcto
# -----------------------

@cocotb.test()
async def test_unlock_sequence(dut):
    """Secuencia correcta debe desbloquear"""

    cocotb.start_soon(Clock(dut.clk, CLK_PERIOD_NS, unit="ns").start())
    await reset(dut)

    # Código correcto: 01 -> 10 -> 11 -> 00
    await send_code(dut, 0b01)
    await send_code(dut, 0b10)
    await send_code(dut, 0b11)
    await send_code(dut, 0b00)

    await RisingEdge(dut.clk)

    assert (dut.uo_out.value.integer & 0b001) == 1


# -----------------------
# TEST 2: Error visible
# -----------------------

@cocotb.test()
async def test_error_signal(dut):
    """Error debe activarse en intento incorrecto"""

    cocotb.start_soon(Clock(dut.clk, CLK_PERIOD_NS, unit="ns").start())
    await reset(dut)

    # Primer intento incorrecto
    await send_code(dut, 0b00)

    await RisingEdge(dut.clk)

    error = (dut.uo_out.value.integer >> 1) & 1
    assert error == 1, "Error no se activó"

    # Esperar unos ciclos (debe seguir activo por el timer)
    for _ in range(10):
        await RisingEdge(dut.clk)
        error = (dut.uo_out.value.integer >> 1) & 1
        assert error == 1, "Error no se mantiene suficiente tiempo"


# -----------------------
# TEST 3: Lock tras 3 fallos
# -----------------------

@cocotb.test()
async def test_lock_after_3_attempts(dut):
    """Después de 3 errores debe bloquear"""

    cocotb.start_soon(Clock(dut.clk, CLK_PERIOD_NS, unit="ns").start())
    await reset(dut)

    # 3 intentos incorrectos
    for _ in range(3):
        await send_code(dut, 0b00)

    await RisingEdge(dut.clk)

    locked = (dut.uo_out.value.integer >> 2) & 1
    assert locked == 1, "No se bloqueó después de 3 intentos"


# -----------------------
# TEST 4: Clear resetea todo
# -----------------------

@cocotb.test()
async def test_clear_resets(dut):
    """Clear debe resetear estado"""

    cocotb.start_soon(Clock(dut.clk, CLK_PERIOD_NS, unit="ns").start())
    await reset(dut)

    # Forzar error y estado
    await send_code(dut, 0b00)

    await press_clear(dut)

    await RisingEdge(dut.clk)

    assert dut.uo_out.value == 0, "Clear no reseteó salidas"
