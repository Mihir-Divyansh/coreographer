## **ThreadWeaver**

Resource Sharing and Latency Hiding in Heterogeneous Multi-Threaded Architectures


## **Objective**

Design and implement a **heterogeneous RISC-V based multi-threading processor architecture** that demonstrates:

1. **Register file sharing** among multiple RISC-V cores.
2. **Instruction/workload distribution** via a centralized scheduler.
3. **Latency hiding** inspired by GPU-style multithreading.
4. Support for **heterogeneous cores** (different RISC-V cores with varying capabilities) and scheduling based on **availability and requirements**.

---

## **Key Architectural Features**

| Feature                        | Description                                                                                                               |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------- |
| **Multiple RISC-V cores**      | 4–8 cores instantiated; may have different types (e.g., integer-only, floating-point capable).                            |
| **Large shared register file** | Inspired by NVIDIA SM register file; enables fast context switching and reduces duplication of storage.                   |
| **Centralized scheduler**      | Dispatches instructions to available cores based on thread readiness, dependencies, and core type.                        |
| **Latency hiding**             | When a core stalls, the scheduler issues instructions from other ready contexts. |
| **Workload distribution**      | Scheduler balances tasks across cores, aiming to maximize throughput and minimize idle cycles.                            |
| **Heterogeneous execution**    | Scheduler is aware of core capabilities and assigns instructions appropriately.                                           |

---

## **Mechanisms for Latency Hiding**

1. **Stall Detection** 
2. **Context Management:** Stalled context is marked “waiting”; its registers are tagged as unavailable.
3. **Scheduler Reallocation:** Ready threads/contexts are dispatched to idle cores.
4. **Wakeup/Scoreboard:** When stalled instructions complete, their dependent instructions become eligible for scheduling.
5. **Process Switching:** Similar to GPU fine-grained multithreading, the scheduler tries to issue instructions  from ready contexts to keep functional units busy.

---

## **GPU-Inspired Concepts**

| Concept                 | GPU Implementation                                            | Your Implementation                                                                    |
| ----------------------- | ------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| **Warp**                | 32 threads executing in SIMT (lockstep)                       | Each RV core executes in an "SIMD" manner            |
| **Warp Scheduler**      | Picks a warp each cycle to issue instructions                 | Your central scheduler picks which RISC-V core/context receives an instruction next    |
| **Latency Hiding**      | Switch to another warp every cycle to hide memory/ALU latency | Switch to another ready context/core when a thread stalls                              |
| **Large register file** | SM registers hold all warps’ registers                        | Shared register file accessible by multiple RISC-V cores, reduces register duplication |

