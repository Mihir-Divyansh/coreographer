# Next Steps: Getting Your First Core on FPGA

This guide will get you from **zero to a single RISC-V core running on your PYNQ-Z2** in the most efficient way possible.

## Phase 1: Get One Core Working (Week 1)

### Day 1-2: Setup Infrastructure

**1. Copy all the generated files to your repo:**

```bash
# Save all the artifacts I created to these locations:
├── coreographer.core          # Main FuseSoC file
├── fusesoc.conf              # FuseSoC config
├── Makefile                  # Build automation
├── .gitignore               # Git ignore rules
├── README.md                # Project README
├── SETUP_GUIDE.md           # Setup instructions
├── configs/
│   └── default.json         # Configuration
├── scripts/
│   └── gen_top.py          # Generator script
├── rtl/common/
│   ├── defines.vh          # Global defines
│   └── params.vh           # Parameters
└── constraints/
    └── pynq_z2.xdc         # FPGA constraints
```

**2. Initialize the project:**

```bash
cd coreographer
make setup

# This will:
# - Create directory structure
# - Check for dependencies
# - Prepare for VexRiscv
```

**3. Get VexRiscv:**

Download a pre-generated VexRiscv configuration:

```bash
cd rtl/cores/vexriscv/

# Option A: Download from releases
wget https://github.com/SpinalHDL/VexRiscv/releases/download/v1.2.0/VexRiscv.v

# Option B: Clone and copy
git clone https://github.com/SpinalHDL/VexRiscv
# Find a pre-generated config in the repo, for example:
# VexRiscv/src/main/scala/vexriscv/demo/
cp VexRiscv/src/main/scala/vexriscv/demo/GenSmallest.v ./VexRiscv.v

cd ../../..
```

### Day 3-4: Create Minimal Core Wrapper

**Goal**: Wrap VexRiscv to match your interface

Create `rtl/core/core_wrapper.v`:

```verilog
`include "defines.vh"
`include "params.vh"

module core_wrapper #(
    parameter CORE_ID = 0,
    parameter XLEN = 32,
    parameter ISA_STRING = "RV32I"
) (
    input wire clk,
    input wire rst_n,
    
    // Task interface (unused for now)
    input wire task_req,
    output reg task_ack,
    input wire [127:0] task_data,
    
    // Memory interface
    output wire mem_req,
    output wire mem_we,
    output wire [XLEN-1:0] mem_addr,
    output wire [XLEN-1:0] mem_wdata,
    input wire [XLEN-1:0] mem_rdata,
    input wire mem_ack,
    
    // Neighbor interfaces (unused for now)
    output wire [4:0] nbr0_reg_addr,
    input wire [XLEN-1:0] nbr0_reg_rdata,
    output wire nbr0_reg_req,
    
    output wire [4:0] nbr1_reg_addr,
    input wire [XLEN-1:0] nbr1_reg_rdata,
    output wire nbr1_reg_req,
    
    // Status
    output wire active
);

    // ======== Step 1: Just instantiate VexRiscv ========
    // Connect VexRiscv's instruction and data buses
    
    wire        iBus_cmd_valid;
    wire        iBus_cmd_ready;
    wire [31:0] iBus_cmd_payload_pc;
    wire        iBus_rsp_valid;
    wire [31:0] iBus_rsp_payload_inst;
    
    wire        dBus_cmd_valid;
    wire        dBus_cmd_ready;
    wire        dBus_cmd_payload_wr;
    wire [31:0] dBus_cmd_payload_addr;
    wire [31:0] dBus_cmd_payload_data;
    wire [1:0]  dBus_cmd_payload_size;
    wire        dBus_rsp_valid;
    wire [31:0] dBus_rsp_payload_data;
    
    VexRiscv core (
        .clk(clk),
        .reset(~rst_n),  // VexRiscv uses active-high reset
        
        // Instruction bus
        .iBus_cmd_valid(iBus_cmd_valid),
        .iBus_cmd_ready(iBus_cmd_ready),
        .iBus_cmd_payload_pc(iBus_cmd_payload_pc),
        .iBus_rsp_valid(iBus_rsp_valid),
        .iBus_rsp_payload_inst(iBus_rsp_payload_inst),
        
        // Data bus
        .dBus_cmd_valid(dBus_cmd_valid),
        .dBus_cmd_ready(dBus_cmd_ready),
        .dBus_cmd_payload_wr(dBus_cmd_payload_wr),
        .dBus_cmd_payload_address(dBus_cmd_payload_addr),
        .dBus_cmd_payload_data(dBus_cmd_payload_data),
        .dBus_cmd_payload_size(dBus_cmd_payload_size),
        .dBus_rsp_ready(dBus_rsp_valid),
        .dBus_rsp_data(dBus_rsp_payload_data)
    );
    
    // ======== Step 2: For now, tie instruction bus to a simple ROM ========
    // Later you'll connect this to the scheduler
    reg [31:0] instruction_rom [0:255];
    
    initial begin
        // Load a simple program that writes to memory
        instruction_rom[0] = 32'h00100093;  // addi x1, x0, 1
        instruction_rom[1] = 32'h00200113;  // addi x2, x0, 2
        instruction_rom[2] = 32'h002081B3;  // add x3, x1, x2
        instruction_rom[3] = 32'h0000006F;  // j 0 (loop forever)
    end
    
    assign iBus_cmd_ready = 1'b1;
    assign iBus_rsp_valid = 1'b1;
    assign iBus_rsp_payload_inst = instruction_rom[iBus_cmd_payload_pc[9:2]];
    
    // ======== Step 3: Connect data bus to memory interface ========
    assign mem_req = dBus_cmd_valid;
    assign mem_we = dBus_cmd_payload_wr;
    assign mem_addr = dBus_cmd_payload_addr;
    assign mem_wdata = dBus_cmd_payload_data;
    assign dBus_cmd_ready = mem_ack;
    assign dBus_rsp_valid = mem_ack & ~dBus_cmd_payload_wr;
    assign dBus_rsp_payload_data = mem_rdata;
    
    // ======== Step 4: Tie off unused interfaces ========
    always @(posedge clk) task_ack <= 1'b0;
    assign nbr0_reg_addr = 5'b0;
    assign nbr0_reg_req = 1'b0;
    assign nbr1_reg_addr = 5'b0;
    assign nbr1_reg_req = 1'b0;
    assign active = dBus_cmd_valid | iBus_cmd_valid;

endmodule
```

### Day 5: Create Stub Modules

Create simple stubs for other required modules:

**`rtl/scheduler/task_dispatcher.v`:**
```verilog
module task_dispatcher #(
    parameter NUM_CORES = 4,
    parameter TASK_CACHE_DEPTH = 32
) (
    input wire clk,
    input wire rst_n,
    
    // Core interfaces (replicate for each core)
    output reg core0_task_req,
    input wire core0_task_ack,
    output reg [127:0] core0_task_data,
    
    output reg core1_task_req,
    input wire core1_task_ack,
    output reg [127:0] core1_task_data,
    
    output reg core2_task_req,
    input wire core2_task_ack,
    output reg [127:0] core2_task_data,
    
    output reg core3_task_req,
    input wire core3_task_ack,
    output reg [127:0] core3_task_data,
    
    output reg [31:0] completed_tasks
);

    // Stub: do nothing for now
    always @(posedge clk) begin
        if (!rst_n) begin
            core0_task_req <= 1'b0;
            core1_task_req <= 1'b0;
            core2_task_req <= 1'b0;
            core3_task_req <= 1'b0;
            completed_tasks <= 32'b0;
        end
    end

endmodule
```

**`rtl/interconnect/memory_arbiter.v`:**
```verilog
module memory_arbiter #(
    parameter NUM_CORES = 4,
    parameter XLEN = 32,
    parameter MEM_SIZE = 32768
) (
    input wire clk,
    input wire rst_n,
    
    // Core 0 interface
    input wire core0_mem_req,
    input wire core0_mem_we,
    input wire [XLEN-1:0] core0_mem_addr,
    input wire [XLEN-1:0] core0_mem_wdata,
    output reg [XLEN-1:0] core0_mem_rdata,
    output reg core0_mem_ack,
    
    // Core 1-3 interfaces (similar pattern)
    input wire core1_mem_req,
    input wire core1_mem_we,
    input wire [XLEN-1:0] core1_mem_addr,
    input wire [XLEN-1:0] core1_mem_wdata,
    output reg [XLEN-1:0] core1_mem_rdata,
    output reg core1_mem_ack,
    
    input wire core2_mem_req,
    input wire core2_mem_we,
    input wire [XLEN-1:0] core2_mem_addr,
    input wire [XLEN-1:0] core2_mem_wdata,
    output reg [XLEN-1:0] core2_mem_rdata,
    output reg core2_mem_ack,
    
    input wire core3_mem_req,
    input wire core3_mem_we,
    input wire [XLEN-1:0] core3_mem_addr,
    input wire [XLEN-1:0] core3_mem_wdata,
    output reg [XLEN-1:0] core3_mem_rdata,
    output reg core3_mem_ack,
    
    // Unified memory interface (to BRAM or external)
    output reg [XLEN-1:0] mem_addr,
    output reg [XLEN-1:0] mem_wdata,
    input wire [XLEN-1:0] mem_rdata,
    output reg mem_we,
    output reg mem_req,
    input wire mem_ack
);

    // Simple priority arbiter (Core 0 highest priority)
    always @(*) begin
        // Default: no request
        mem_req = 1'b0;
        mem_we = 1'b0;
        mem_addr = {XLEN{1'b0}};
        mem_wdata = {XLEN{1'b0}};
        core0_mem_ack = 1'b0;
        core1_mem_ack = 1'b0;
        core2_mem_ack = 1'b0;
        core3_mem_ack = 1'b0;
        
        // Priority: 0 > 1 > 2 > 3
        if (core0_mem_req) begin
            mem_req = core0_mem_req;
            mem_we = core0_mem_we;
            mem_addr = core0_mem_addr;
            mem_wdata = core0_mem_wdata;
            core0_mem_ack = mem_ack;
        end else if (core1_mem_req) begin
            mem_req = core1_mem_req;
            mem_we = core1_mem_we;
            mem_addr = core1_mem_addr;
            mem_wdata = core1_mem_wdata;
            core1_mem_ack = mem_ack;
        end else if (core2_mem_req) begin
            mem_req = core2_mem_req;
            mem_we = core2_mem_we;
            mem_addr = core2_mem_addr;
            mem_wdata = core2_mem_wdata;
            core2_mem_ack = mem_ack;
        end else if (core3_mem_req) begin
            mem_req = core3_mem_req;
            mem_we = core3_mem_we;
            mem_addr = core3_mem_addr;
            mem_wdata = core3_mem_wdata;
            core3_mem_ack = mem_ack;
        end
    end
    
    // Pass read data to all cores
    always @(posedge clk) begin
        core0_mem_rdata <= mem_rdata;
        core1_mem_rdata <= mem_rdata;
        core2_mem_rdata <= mem_rdata;
        core3_mem_rdata <= mem_rdata;
    end

endmodule
```

### Day 6-7: Build and Test

**1. Edit config for single core first:**

Edit `configs/default.json`:
```json
{
  "cores": {
    "num_cores": 1,  // Start with 1 core!
    ...
  }
}
```

**2. Generate top-level:**
```bash
make gen
```

**3. Check generated file:**
```bash
cat build/generated/top.v
# Verify it looks reasonable
```

**4. Run lint:**
```bash
make lint
# Fix any errors in your RTL
```

**5. Synthesize:**
```bash
make synth
# This will take 10-20 minutes
```

**6. Check reports:**
```bash
ls build/*/synth-vivado/
# Look for timing reports, utilization
```

**7. Program FPGA:**
```bash
make program
```

**8. Test on hardware:**
- LED0 should blink or light up based on core activity
- Use ILA (Integrated Logic Analyzer) in Vivado to observe signals

## Phase 2: Scale to Multiple Cores (Week 2)

Once you have ONE core working:

1. **Change config to 2 cores:**
```json
{
  "cores": {
    "num_cores": 2,
    ...
  }
}
```

2. **Regenerate and test:**
```bash
make gen
make synth
```

3. **Verify both cores are active** (check LEDs)

4. **Scale to 4 cores** and repeat

## Phase 3: Add Features Incrementally (Weeks 3-4)

Don't try to build everything at once! Add features one at a time:

1. ✅ Single core running
2. ✅ Multiple cores running independently
3. ➡️ **Next**: Memory arbiter improvements (round-robin)
4. ➡️ **Next**: Simple task dispatcher (no dependencies)
5. ➡️ **Next**: Neighbor register network
6. ➡️ **Next**: Full scheduler with dependencies

## Pro Tips for Efficiency

### 1. Use Incremental Builds
```bash
# Only regenerate if config changed
make gen

# Quick syntax check (fast!)
make lint

# Full simulation (slower)
make sim

# Synthesis (slowest - only when confident)
make synth
```

### 2. Test in Simulation First
Before synthesizing, always simulate:
```bash
# Create a simple testbench
# Run simulation
make sim

# View waveforms
make waves
```

### 3. Use Version Control
```bash
git add configs/ rtl/core/ rtl/scheduler/
git commit -m "Phase 1: Single core wrapper complete"
```

### 4. Keep Notes
Document what works and what doesn't:
```bash
echo "2025-10-21: VexRiscv GenSmallest config works well" >> NOTES.md
echo "Synthesis time: 12 minutes, 45% LUT utilization" >> NOTES.md
```

### 5. Automated Testing
Create a test script:
```bash
#!/bin/bash
# test.sh
make clean
make gen
make lint || exit 1
echo "✅ Lint passed"
make sim || exit 1
echo "✅ Simulation passed"
```

## Common Pitfalls to Avoid

1. **❌ Don't implement everything at once**
   - ✅ Start with minimal working system
   
2. **❌ Don't customize VexRiscv initially**
   - ✅ Use a pre-generated config first
   
3. **❌ Don't skip simulation**
   - ✅ Always simulate before synthesizing
   
4. **❌ Don't ignore warnings**
   - ✅ Fix linter warnings early
   
5. **❌ Don't hardcode values**
   - ✅ Use parameters and configs

## Success Metrics

**Week 1 Goal**: ✅ One core blinking LED on FPGA
**Week 2 Goal**: ✅ Four cores running independently
**Week 3 Goal**: ✅ Cores sharing registers via neighbor network
**Week 4 Goal**: ✅ Scheduler dispatching tasks

## Resources

- Check `SETUP_GUIDE.md` for detailed instructions
- Use `make help` to see all commands
- Read VexRiscv documentation for core details
- PYNQ documentation for FPGA specifics

## When You Get Stuck

1. Check build logs: `cat build/*/synth-vivado/*.log`
2. Run lint: `make lint`
3. Simplify: reduce to 1 core, remove features
4. Compare with working version in git history
5. Check that all files are in the right places

## Your Immediate Action Items

```bash
# 1. Setup
make setup

# 2. Get VexRiscv
cd rtl/cores/vexriscv/ && wget <URL> && cd ../../..

# 3. Create core_wrapper.v (copy from above)

# 4. Create stub modules (copy from above)

# 5. Test the build
make gen
make lint

# 6. If lint passes, synthesize!
make synth
```

Good luck! 🚀 You're building something really cool!