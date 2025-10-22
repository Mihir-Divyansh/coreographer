# Coreographer

**Multi-core RISC-V Architecture with Hardware Scheduler and Neighbor Register Sharing**

A heterogeneous multi-core RISC-V system inspired by GPU streaming multiprocessors, featuring:
- Clustered cores with local register sharing
- Hardware-based micro-task scheduler
- Configurable topology (ring, mesh, fully-connected)
- Target: PYNQ-Z2 (Zynq-7020) FPGA

## Features

- 🚀 **Multi-core RISC-V**: Configurable number of cores (2, 4, 8+)
- 🔗 **Neighbor Register Sharing**: Cores can access neighbors' registers via custom instructions
- 📋 **Hardware Scheduler**: Dedicated task dispatcher with dependency tracking
- 🎯 **Micro-task Programming**: Self-contained tasks with explicit dependencies
- 🔧 **Heterogeneous ISA**: Mix RV32I, RV32IM, RV32IF cores
- 📊 **Performance Monitoring**: Built-in counters for analysis

## Quick Start

```bash
# 1. Setup build system and get VexRiscv
make setup

# 2. Generate top-level from configuration
make gen

# 3. Run simulation
make sim

# 4. Synthesize for PYNQ-Z2
make synth

# 5. Program FPGA
make program
```

See [SETUP_GUIDE.md](SETUP_GUIDE.md) for detailed instructions.

## Architecture

```
┌─────────────────────────────────────────────────┐
│         Hardware Scheduler (Task Dispatcher)    │
│         • Instruction Cache (32 micro-tasks)    │
│         • Dependency Tracker                    │
│         • Task Queue                            │
└────────────────┬────────────────────────────────┘
                 │
         Task Dispatch Bus (128-bit)
                 │
    ┌────────────┴────────────┬──────────────┐
    │                         │              │
┌───▼───┐  neighbor  ┌───────▼──┐  ┌───────▼──┐
│Core 0 │◄──────────►│ Core 1   │  │ Core 2   │
│RV32I  │    link    │ RV32I    │  │ RV32IM   │
└───┬───┘            └────┬─────┘  └────┬─────┘
    │                     │             │
    └─────────────────────┴─────────────┘
                  │
          ┌───────▼────────┐
          │  Memory Arbiter │
          │  (Round Robin)  │
          └───────┬────────┘
                  │
          ┌───────▼────────┐
          │  Data Memory   │
          │   (32 KB BRAM) │
          └────────────────┘
```

## Project Structure

```
coreographer/
├── configs/              # System configurations
│   └── default.json      # 4-core ring topology
├── rtl/
│   ├── cores/           # VexRiscv RISC-V cores
│   ├── core/            # Core wrappers & neighbor interface
│   ├── scheduler/       # Task dispatcher & queue
│   ├── interconnect/    # Memory arbiter & neighbor network
│   └── common/          # Shared defines & parameters
├── tb/                  # Testbenches
├── scripts/             # Build automation
│   ├── gen_top.py      # Top-level generator
│   └── vivado/         # FPGA scripts
├── constraints/         # PYNQ-Z2 constraints
└── docs/               # Documentation
```

## Configuration

Edit `configs/default.json` to customize:

```json
{
  "cores": {
    "num_cores": 4,
    "core_types": [
      {"id": 0, "isa": "RV32I"},
      {"id": 1, "isa": "RV32I"},
      {"id": 2, "isa": "RV32IM"},
      {"id": 3, "isa": "RV32IM"}
    ]
  },
  "topology": {
    "type": "ring"  // ring | mesh | fully_connected
  }
}
```

Then regenerate:
```bash
make gen
```

## Micro-Task Programming Model

Programs are structured as micro-tasks with headers:

```assembly
.task 42                    # Task ID
.depends 39, 40             # Wait for tasks 39, 40
.needs mul                  # Requires multiply unit
.instructions
    lw   r1, 0(r10)        # Load A[i]
    lw   r2, 0(r11)        # Load B[i]
    mul  r3, r1, r2        # Multiply
    sw   r3, 0(r12)        # Store C[i]
    TASK_DONE              # Signal completion
.end_task
```

## Custom Instructions

### Neighbor Register Access

**NBRRD** - Read from neighbor's register file
```assembly
nbrrd rd, neighbor_id, rs1
# rd = neighbor[neighbor_id].reg[rs1]
```

**NBRWR** - Write to neighbor's register file
```assembly
nbrwr neighbor_id, rd, rs2
# neighbor[neighbor_id].reg[rd] = rs2
```

Example:
```assembly
# Core 0 reads register x5 from Core 1
nbrrd x10, 1, x5    # x10 = core1.x5

# Core 0 writes to Core 1's x6
nbrwr 1, x6, x11    # core1.x6 = x11
```

## Build Targets

### Simulation
```bash
make sim              # Full system simulation (Verilator)
make sim-core         # Single core wrapper test
make sim-scheduler    # Scheduler test
make waves            # Open waveform viewer
```

### Synthesis
```bash
make synth            # Synthesize for PYNQ-Z2
make impl             # Place & route
make program          # Program bitstream to FPGA
```

### Verification
```bash
make lint             # Run Verilator linter
make verify           # Run all testbenches
```

### Configuration
```bash
make config-2core     # 2-core configuration
make config-4core     # 4-core (default)
make config-8core     # 8-core configuration
make info             # Show current config
```

### Utilities
```bash
make clean            # Clean build artifacts
make help             # Show all targets
```

## Benchmarks

Three benchmarks demonstrate different parallelism patterns:

### 1. Vector Dot Product
- **Size**: 64-element vectors
- **Parallelism**: Element-wise multiplication
- **Purpose**: Basic task dispatch validation

### 2. Matrix Multiply
- **Size**: 8×8 or 16×16 matrices
- **Parallelism**: Each task computes one output element
- **Purpose**: Demonstrates heterogeneous core utilization

### 3. Streaming Accumulator
- **Size**: 256-element stream with 8-tap window
- **Parallelism**: Overlapping windows in pipeline
- **Purpose**: Tests scheduler throughput

## Performance Metrics

The system tracks:
- **Throughput**: Tasks completed per cycle
- **Speedup**: Performance vs single core
- **Core Utilization**: % active cycles per core
- **Scheduler Efficiency**: Dispatch stalls / total attempts
- **Neighbor Access Metrics**: Access counts and latency

## Development Phases

### Phase 1: Single Core ✅ (Current)
- [x] FuseSoC build system
- [x] VexRiscv integration
- [ ] Basic core wrapper
- [ ] Simple testbench
- [ ] FPGA synthesis

### Phase 2: Multi-core
- [ ] Memory arbiter
- [ ] Multiple core instantiation
- [ ] Independent task execution
- [ ] Performance counters

### Phase 3: Neighbor Network
- [ ] Register file proxy
- [ ] Custom instruction decoder
- [ ] Topology implementation (ring)
- [ ] Neighbor access verification

### Phase 4: Hardware Scheduler
- [ ] Task queue and cache
- [ ] Dependency tracker
- [ ] Dispatch bus protocol
- [ ] Task-to-core assignment

### Phase 5: Benchmarks & Analysis
- [ ] Micro-task assembler
- [ ] Benchmark programs
- [ ] Performance analysis
- [ ] FPGA demonstration

## Tools & Dependencies

### Required
- **FuseSoC** ≥ 2.0 - Build system
- **Verilator** ≥ 4.0 - Simulation
- **Vivado** ≥ 2020.2 - FPGA synthesis
- **Python** ≥ 3.7 - Code generation

### Optional
- **GTKWave** - Waveform viewer
- **SpinalHDL** - For custom VexRiscv configs

Install with:
```bash
pip3 install fusesoc
sudo apt-get install verilator gtkwave
```

## Hardware Target

**Board**: PYNQ-Z2
- **FPGA**: Zynq-7020 (xc7z020clg400-1)
- **Logic Cells**: 85K
- **Block RAM**: 4.9 Mb
- **DSP Slices**: 220
- **Clock**: 125 MHz external, 100 MHz system

## File Overview

### Core Files
- `coreographer.core` - FuseSoC core definition
- `fusesoc.conf` - FuseSoC configuration
- `Makefile` - Build automation

### RTL
- `rtl/top.v` - Manual top-level (optional)
- `build/generated/top.v` - Auto-generated top
- `rtl/core/core_wrapper.v` - VexRiscv wrapper
- `rtl/scheduler/task_dispatcher.v` - Hardware scheduler
- `rtl/interconnect/memory_arbiter.v` - Shared memory arbiter

### Configuration
- `configs/default.json` - System configuration
- `scripts/gen_top.py` - Top-level generator

### Constraints
- `constraints/pynq_z2.xdc` - Pin assignments and timing

## Documentation

- [SETUP_GUIDE.md](SETUP_GUIDE.md) - Detailed setup instructions
- [docs/architecture.md](docs/architecture.md) - Architecture details
- [docs/isa_extensions.md](docs/isa_extensions.md) - Custom instructions
- [docs/microtask_format.md](docs/microtask_format.md) - Task programming

## Troubleshooting

### Build Fails
```bash
# Clean and retry
make clean
make setup
make gen
```

### Simulation Errors
```bash
# Check generated files
cat build/generated/top.v

# Run lint
make lint
```

### VexRiscv Missing
```bash
# Download VexRiscv
cd rtl/cores/vexriscv/
wget https://github.com/SpinalHDL/VexRiscv/releases/download/v1.0.0/VexRiscv.v
```

## Contributing

This is an academic project for CS2323 Computer Architecture.

**Author**: E. Mihir Divyansh (EE23BTECH11017)

## Future Work

- [ ] Topology comparison (ring vs mesh vs fully-connected)
- [ ] Varying core counts (2, 4, 8 cores)
- [ ] Homogeneous vs heterogeneous ISA analysis
- [ ] Neighbor access latency sensitivity study
- [ ] Integration with Zynq PS for software control
- [ ] DMA for larger datasets
- [ ] Power analysis

## References

- **RISC-V ISA Spec**: https://riscv.org/technical/specifications/
- **VexRiscv**: https://github.com/SpinalHDL/VexRiscv
- **FuseSoC**: https://fusesoc.readthedocs.io/
- **PYNQ**: https://pynq.readthedocs.io/

## License

See [LICENSE](LICENSE) file for details.

---

**Status**: 🚧 In Development - Phase 1

**Last Updated**: October 2025
