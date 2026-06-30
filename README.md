# I2C Master Controller (Verilog RTL Design & Verification)

## 📌 Project Overview
This repository contains a robust **I2C (Inter-Integrated Circuit) Master Controller** designed in standard Verilog (IEEE 1364-2005). The design implements a complete finite state machine (FSM) to handle single-master data writes to peripheral I2C slave devices, emulating open-drain bus structures and protocol timing. 

This project was built and verified using an open-source EDA toolchain (**Icarus Verilog** and **GTKWave**), demonstrating industry-standard RTL hygiene, testbench architecture, and digital verification workflows.

---

## 🛠️ Key Technical Features
*   **Standard I2C Protocol Compliance:** Generates formal START, STOP, and repeated clock conditions.
*   **7-Bit Addressing:** Supports standard peripheral addressing with a configurable Read/Write bit.
*   **Open-Drain Emulation:** Uses high-impedance (`1'bz`) tri-state conditions to simulate external pull-up network operations on the bidirectional `SDA` line.
*   **FSM-Driven Architecture:** Implements a clean, robust synchronous state machine to track control sequences safely.

---

## 🏗️ Hardware Architecture & FSM States
The master controller shifts through sequential states to safely transmit data across the serial bus:
1.  **IDLE:** Bus is free; waiting for the `start` signal.
2.  **START:** Pulls `SDA` low while `SCL` is high to signal a start condition.
3.  **ADDRESS:** Serializes and shifts out the 7-bit slave address over 7 clock cycles.
4.  **RW (Read/Write):** Transmits the operation bit (0 for Write, 1 for Read).
5.  **ACK (Acknowledge):** Releases the `SDA` line to high-impedance to allow the slave to drive it low.
6.  **DATA:** Shifts out the 8-bit data payload bit-by-bit.
7.  **STOP:** Transitions `SDA` from low to high while `SCL` is high to cleanly close the transaction.

---

## 🔬 Verification Strategy (Testbench)
The testbench (`tb_i2c_master.v`) models a real-world system environment:
*   Generates a synchronous **50 MHz** reference clock.
*   Emulates external pull-up resistors on the I2C physical bus layout.
*   Drives active-low slave responses (`slave_ack_drive`) to test the master's capability to read incoming acknowledgments seamlessly.

---

 **`WAVEFORM.png`**

## 🚀 How to Compile and Simulate

### Prerequisites
Ensure you have **Icarus Verilog** and **GTKWave** installed and added to your system environment PATH variables.

### Execution Commands
Open your terminal inside the project directory and run the following sequence:

```bash
# 1. Compile the RTL design and testbench
iverilog -o i2c_legacy_design.vvp i2c_master.v tb_i2c_master.v

# 2. Run the simulation binary to generate waveform data
vvp i2c_legacy_design.vvp

# 3. View the digital waveforms in GTKWave
gtkwave i2c_sim.vcd
