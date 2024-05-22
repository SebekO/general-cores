//------------------------------------------------------------------------------
// CERN BE-CEM-EDL
// General Cores Library
// https://www.ohwr.org/projects/general-cores
//------------------------------------------------------------------------------
//
// description: common typedefs for Wishbone BFMs.
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

`ifndef __IF_WB_TYPES_SVH
`define __IF_WB_TYPES_SVH

`include "gencores_sim_defs.svh"

typedef enum 
{
  R_OK = 0,
  R_ERROR,
  R_RETRY
} wb_cycle_result_t;

typedef enum
{
  CLASSIC = 0,
  PIPELINED = 1
} wb_cycle_type_t;

typedef enum {
  WORD = 0,
  BYTE = 1
} wb_address_granularity_t;

typedef struct {
   uint64_t a;
   uint64_t d;
   int size;
   bit [7:0] sel;
} wb_xfer_t;

typedef struct  {
   int rw;
   wb_cycle_type_t ctype;
   wb_xfer_t data[$];
   wb_cycle_result_t result;
   event done;
} wb_cycle_t;

typedef enum  
 {
  RETRY = 0,
  STALL,
  ERROR
} wba_sim_event_t;

typedef enum
{
  RANDOM = (1<<0),
  DELAYED = (1<<1)
 } wba_sim_behavior_t;

`endif //  `ifndef __IF_WB_TYPES_SVH

