//
// Global Defines for Coreographer
// Common constants and macros
//

`ifndef COREOGRAPHER_DEFINES_VH
`define COREOGRAPHER_DEFINES_VH

//==============================================================================
// Topology Definitions
//==============================================================================
`define TOPOLOGY_RING            2'b00
`define TOPOLOGY_MESH            2'b01
`define TOPOLOGY_FULLY_CONNECTED 2'b10

//==============================================================================
// ISA Extensions
//==============================================================================
`define ISA_RV32I   3'b000
`define ISA_RV32IM  3'b001
`define ISA_RV32IF  3'b010
`define ISA_RV32IMF 3'b011

//==============================================================================
// Custom Instructions (Neighbor Register Access)
//==============================================================================
// Custom-0 opcode space (0x0B)
`define OPCODE_CUSTOM0 7'b0001011

// Function codes for neighbor operations
`define FUNCT3_NBR_READ  3'b000
`define FUNCT3_NBR_WRITE 3'b001

// Instruction format:
// NBRRD rd, rs1, neighbor_id
// NBRWR rs2, rs1, neighbor_id

//==============================================================================
// Task Header Format (32 bits)
//==============================================================================
`define TASK_ID_MSB         31
`define TASK_ID_LSB         24
`define TASK_DEP_MSB        23
`define TASK_DEP_LSB        16
`define TASK_CAP_MSB        15
`define TASK_CAP_LSB        12
`define TASK_CLUSTER_MSB    11
`define TASK_CLUSTER_LSB    8
`define TASK_INSTR_CNT_MSB  7
`define TASK_INSTR_CNT_LSB  0

// Capability flags
`define TASK_CAP_MUL    3
`define TASK_CAP_DIV    2
`define TASK_CAP_MEM    1
`define TASK_CAP_RSVD   0

//==============================================================================
// Task Completion Marker
//==============================================================================
// Custom instruction to signal task completion
// Using CUSTOM-1 opcode (0x2B)
`define TASK_DONE_OPCODE 7'b0101011
`define TASK_DONE_FUNCT3 3'b000
`define TASK_DONE_FUNCT7 7'b0000001

// Full instruction encoding: 0x0000002B
`define TASK_DONE_INSTR 32'h0000002B

//==============================================================================
// Memory Arbiter
//==============================================================================
`define ARB_ROUND_ROBIN   2'b00
`define ARB_FIXED_PRIORITY 2'b01
`define ARB_DYNAMIC       2'b10

//==============================================================================
// Scheduler States
//==============================================================================
`define SCHED_IDLE       3'b000
`define SCHED_FETCH      3'b001
`define SCHED_PARSE      3'b010
`define SCHED_CHECK_DEPS 3'b011
`define SCHED_DISPATCH   3'b100
`define SCHED_WAIT       3'b101

//==============================================================================
// Debug and Performance Counters
//==============================================================================
`ifdef DEBUG_ENABLE
    `define DEBUG_PRINT(msg) $display("[%0t] %s", $time, msg)
`else
    `define DEBUG_PRINT(msg)
`endif

//==============================================================================
// Utility Macros
//==============================================================================
`define MAX(a,b) ((a) > (b) ? (a) : (b))
`define MIN(a,b) ((a) < (b) ? (a) : (b))
`define CLOG2(x) \
    (x <= 2) ? 1 : \
    (x <= 4) ? 2 : \
    (x <= 8) ? 3 : \
    (x <= 16) ? 4 : \
    (x <= 32) ? 5 : \
    (x <= 64) ? 6 : \
    (x <= 128) ? 7 : \
    (x <= 256) ? 8 : \
    (x <= 512) ? 9 : 10

`endif // COREOGRAPHER_DEFINES_VH
