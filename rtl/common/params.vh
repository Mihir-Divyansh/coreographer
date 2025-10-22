//
// Default Parameters for Coreographer
// Can be overridden by top-level or configuration
//

`ifndef COREOGRAPHER_PARAMS_VH
`define COREOGRAPHER_PARAMS_VH

//==============================================================================
// System Parameters
//==============================================================================
`ifndef NUM_CORES
    `define NUM_CORES 4
`endif

`ifndef XLEN
    `define XLEN 32
`endif

`ifndef DATA_MEM_SIZE
    `define DATA_MEM_SIZE 32768  // 32 KB
`endif

`ifndef INSTR_MEM_SIZE
    `define INSTR_MEM_SIZE 8192  // 8 KB
`endif

//==============================================================================
// Scheduler Parameters
//==============================================================================
`ifndef TASK_CACHE_DEPTH
    `define TASK_CACHE_DEPTH 32
`endif

`ifndef MAX_TASK_INSTRUCTIONS
    `define MAX_TASK_INSTRUCTIONS 16
`endif

`ifndef DISPATCH_BUS_WIDTH
    `define DISPATCH_BUS_WIDTH 128
`endif

`ifndef MAX_DEPENDENCIES
    `define MAX_DEPENDENCIES 8
`endif

//==============================================================================
// Neighbor Network Parameters
//==============================================================================
`ifndef NEIGHBOR_ACCESS_LATENCY
    `define NEIGHBOR_ACCESS_LATENCY 1  // cycles
`endif

`ifndef MAX_NEIGHBORS_PER_CORE
    `define MAX_NEIGHBORS_PER_CORE 2
`endif

//==============================================================================
// Memory Parameters
//==============================================================================
`ifndef MEM_ADDR_WIDTH
    `define MEM_ADDR_WIDTH 15  // log2(32768)
`endif

`ifndef MEM_DATA_WIDTH
    `define MEM_DATA_WIDTH `XLEN
`endif

//==============================================================================
// Timing Parameters
//==============================================================================
`ifndef RESET_CYCLES
    `define RESET_CYCLES 10
`endif

`ifndef TIMEOUT_CYCLES
    `define TIMEOUT_CYCLES 10000
`endif

//==============================================================================
// Feature Enables
//==============================================================================
`ifndef ENABLE_PERFORMANCE_COUNTERS
    `define ENABLE_PERFORMANCE_COUNTERS 1
`endif

`ifndef ENABLE_DEBUG_TRACE
    `define ENABLE_DEBUG_TRACE 1
`endif

`endif // COREOGRAPHER_PARAMS_VH
