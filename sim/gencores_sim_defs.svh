//------------------------------------------------------------------------------
// CERN BE-CEM-EDL
// General Cores Library
// https://www.ohwr.org/projects/general-cores
//------------------------------------------------------------------------------
//
// description: Global types for the gencores SV simulation models.
//
//------------------------------------------------------------------------------
// Copyright CERN 2010-2019
//------------------------------------------------------------------------------
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 2.0 (the "License"); you may not use this file except
// in compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-2.0.
// Unless required by applicable law or agreed to in writing, software,
// hardware and materials distributed under this License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
// or implied. See the License for the specific language governing permissions
// and limitations under the License.
//------------------------------------------------------------------------------

`ifndef GENCORES_SIM_DEFS_SV
 `define GENCORES_SIM_DEFS_SV 1

typedef byte unsigned uint8_t;
typedef longint unsigned uint64_t;
typedef int unsigned uint32_t;
typedef shortint unsigned uint16_t;

typedef uint64_t u64_vector_t[$];
typedef uint32_t u32_vector_t[$];
typedef uint16_t u16_vector_t[$];
typedef byte u8_vector_t[$];

`endif
