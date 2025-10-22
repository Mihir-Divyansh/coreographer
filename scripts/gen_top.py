#!/usr/bin/env python3
"""
Generate parameterized top-level module for Coreographer
Reads configuration from JSON and generates top.v
"""

import json
import os
import sys
from pathlib import Path
from typing import Dict, List, Any

class CoreographerGenerator:
    def __init__(self, config_path: str = "configs/default.json"):
        with open(config_path, 'r') as f:
            self.config = json.load(f)
        
        self.num_cores = self.config['cores']['num_cores']
        self.xlen = self.config['cores']['xlen']
        self.topology = self.config['topology']['type']
        self.output_dir = Path("build/generated")
        self.output_dir.mkdir(parents=True, exist_ok=True)
    
    def generate_ports(self) -> str:
        """Generate module ports"""
        return f"""
    // Clock and reset
    input  wire                     clk,
    input  wire                     rst_n,
    
    // Optional: External memory interface for Zynq PS
    output wire [{self.xlen-1}:0]   mem_addr,
    output wire [{self.xlen-1}:0]   mem_wdata,
    input  wire [{self.xlen-1}:0]   mem_rdata,
    output wire                     mem_we,
    output wire                     mem_req,
    input  wire                     mem_ack,
    
    // Debug outputs
    output wire [{self.num_cores-1}:0]  core_active,
    output wire [{self.num_cores-1}:0]  core_task_done,
    output wire [31:0]                  completed_tasks
"""
    
    def generate_parameters(self) -> str:
        """Generate module parameters"""
        return f"""
    parameter NUM_CORES = {self.num_cores},
    parameter XLEN = {self.xlen},
    parameter DATA_MEM_SIZE = {self.config['memory']['data_mem_size']},
    parameter TASK_CACHE_DEPTH = {self.config['scheduler']['task_cache_depth']}
"""
    
    def generate_core_signals(self) -> str:
        """Generate signals for all cores"""
        signals = []
        
        # Per-core signals
        for i in range(self.num_cores):
            signals.append(f"""
    // Core {i} signals
    wire                    core{i}_task_req;
    wire                    core{i}_task_ack;
    wire [127:0]            core{i}_task_data;
    wire                    core{i}_mem_req;
    wire                    core{i}_mem_we;
    wire [{self.xlen-1}:0]  core{i}_mem_addr;
    wire [{self.xlen-1}:0]  core{i}_mem_wdata;
    wire [{self.xlen-1}:0]  core{i}_mem_rdata;
    wire                    core{i}_mem_ack;
    wire                    core{i}_active;
""")
        
        return "\n".join(signals)
    
    def generate_neighbor_signals(self) -> str:
        """Generate neighbor register sharing signals"""
        signals = []
        
        connections = self.config['topology']['connections']
        
        for conn in connections:
            core_id = conn['core']
            for neighbor_id in conn['neighbors']:
                signals.append(f"""
    // Neighbor link: Core {core_id} -> Core {neighbor_id}
    wire [4:0]              core{core_id}_nbr{neighbor_id}_reg_addr;
    wire [{self.xlen-1}:0]  core{core_id}_nbr{neighbor_id}_reg_rdata;
    wire                    core{core_id}_nbr{neighbor_id}_reg_req;
""")
        
        return "\n".join(signals)
    
    def generate_core_instantiations(self) -> str:
        """Generate core wrapper instantiations"""
        instantiations = []
        
        for i, core_cfg in enumerate(self.config['cores']['core_types']):
            neighbors = [c for c in self.config['topology']['connections'] 
                        if c['core'] == i][0]['neighbors']
            
            instantiations.append(f"""
    // Core {i} ({core_cfg['isa']})
    core_wrapper #(
        .CORE_ID({i}),
        .XLEN(XLEN),
        .ISA_STRING("{core_cfg['isa']}")
    ) core_{i}_inst (
        .clk(clk),
        .rst_n(rst_n),
        
        // Task interface from scheduler
        .task_req(core{i}_task_req),
        .task_ack(core{i}_task_ack),
        .task_data(core{i}_task_data),
        
        // Memory interface
        .mem_req(core{i}_mem_req),
        .mem_we(core{i}_mem_we),
        .mem_addr(core{i}_mem_addr),
        .mem_wdata(core{i}_mem_wdata),
        .mem_rdata(core{i}_mem_rdata),
        .mem_ack(core{i}_mem_ack),
        
        // Neighbor register interfaces
        .nbr{neighbors[0]}_reg_addr(core{i}_nbr{neighbors[0]}_reg_addr),
        .nbr{neighbors[0]}_reg_rdata(core{i}_nbr{neighbors[0]}_reg_rdata),
        .nbr{neighbors[0]}_reg_req(core{i}_nbr{neighbors[0]}_reg_req),
        
        .nbr{neighbors[1]}_reg_addr(core{i}_nbr{neighbors[1]}_reg_addr),
        .nbr{neighbors[1]}_reg_rdata(core{i}_nbr{neighbors[1]}_reg_rdata),
        .nbr{neighbors[1]}_reg_req(core{i}_nbr{neighbors[1]}_reg_req),
        
        // Status
        .active(core{i}_active)
    );
""")
        
        return "\n".join(instantiations)
    
    def generate_scheduler_instantiation(self) -> str:
        """Generate hardware scheduler instantiation"""
        task_ports = ",\n        ".join([
            f".core{i}_task_req(core{i}_task_req),\n"
            f"        .core{i}_task_ack(core{i}_task_ack),\n"
            f"        .core{i}_task_data(core{i}_task_data)"
            for i in range(self.num_cores)
        ])
        
        return f"""
    // Hardware scheduler (task dispatcher)
    task_dispatcher #(
        .NUM_CORES(NUM_CORES),
        .TASK_CACHE_DEPTH(TASK_CACHE_DEPTH)
    ) scheduler_inst (
        .clk(clk),
        .rst_n(rst_n),
        
        // Task interfaces to cores
        {task_ports},
        
        // Status
        .completed_tasks(completed_tasks)
    );
"""
    
    def generate_memory_arbiter(self) -> str:
        """Generate memory arbiter instantiation"""
        mem_ports = ",\n        ".join([
            f".core{i}_mem_req(core{i}_mem_req),\n"
            f"        .core{i}_mem_we(core{i}_mem_we),\n"
            f"        .core{i}_mem_addr(core{i}_mem_addr),\n"
            f"        .core{i}_mem_wdata(core{i}_mem_wdata),\n"
            f"        .core{i}_mem_rdata(core{i}_mem_rdata),\n"
            f"        .core{i}_mem_ack(core{i}_mem_ack)"
            for i in range(self.num_cores)
        ])
        
        return f"""
    // Memory arbiter
    memory_arbiter #(
        .NUM_CORES(NUM_CORES),
        .XLEN(XLEN),
        .MEM_SIZE(DATA_MEM_SIZE)
    ) mem_arbiter_inst (
        .clk(clk),
        .rst_n(rst_n),
        
        // Core memory interfaces
        {mem_ports},
        
        // Unified memory interface
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_rdata(mem_rdata),
        .mem_we(mem_we),
        .mem_req(mem_req),
        .mem_ack(mem_ack)
    );
"""
    
    def generate_debug_logic(self) -> str:
        """Generate debug output assignments"""
        core_active_bits = " | ".join([f"core{i}_active" for i in range(self.num_cores)])
        
        return f"""
    // Debug outputs
    assign core_active = {{{", ".join([f"core{i}_active" for i in range(self.num_cores)])}}};
    assign core_task_done = /* TODO: wire from cores */;
"""
    
    def generate_top(self) -> str:
        """Generate complete top-level module"""
        template = f"""//
// Auto-generated top-level module for Coreographer
// Generated from: {self.config['project']['name']} v{self.config['project']['version']}
// Configuration: {self.num_cores} cores, {self.topology} topology
//
// DO NOT EDIT THIS FILE MANUALLY
// Regenerate with: fusesoc run --target=default ::coreographer
//

`include "defines.vh"
`include "params.vh"

module coreographer_top #(
{self.generate_parameters()}
) (
{self.generate_ports()}
);

{self.generate_core_signals()}

{self.generate_neighbor_signals()}

{self.generate_core_instantiations()}

{self.generate_scheduler_instantiation()}

{self.generate_memory_arbiter()}

{self.generate_debug_logic()}

endmodule
"""
        return template
    
    def write_top(self):
        """Write generated top.v to output directory"""
        top_verilog = self.generate_top()
        output_path = self.output_dir / "top.v"
        
        with open(output_path, 'w') as f:
            f.write(top_verilog)
        
        print(f"[GEN] Generated top-level: {output_path}")
        print(f"      Cores: {self.num_cores}")
        print(f"      Topology: {self.topology}")
        print(f"      XLEN: {self.xlen}")

def main():
    config_file = sys.argv[1] if len(sys.argv) > 1 else "configs/default.json"
    
    if not os.path.exists(config_file):
        print(f"[ERROR] Config file not found: {config_file}")
        sys.exit(1)
    
    generator = CoreographerGenerator(config_file)
    generator.write_top()
    
    print("[GEN] Top-level generation complete!")

if __name__ == "__main__":
    main()
