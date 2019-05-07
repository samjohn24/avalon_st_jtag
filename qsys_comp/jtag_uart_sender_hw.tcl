# TCL File Generated by Component Editor 11.0sp1
# Sun Feb 17 01:19:44 BRT 2019
# DO NOT MODIFY


# +-----------------------------------
# | 
# | jtag_uart_sender "JTAG UART Avalon-ST sender" v1.0
# | null 2019.02.17.01:19:44
# | 
# | 
# | /home/scarbajali/OneDrive/Projects/Master/Thesis/hardware/ip/jtag_avalon_st/rtl_v/jtag_uart_sender.sv
# | 
# |    ./jtag_uart_sender.sv syn, sim
# | 
# +-----------------------------------

# +-----------------------------------
# | request TCL package from ACDS 11.0
# | 
package require -exact sopc 11.0
# | 
# +-----------------------------------

# +-----------------------------------
# | module jtag_uart_sender
# | 
set_module_property NAME jtag_uart_sender
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property DISPLAY_NAME "JTAG UART Avalon-ST sender"
set_module_property TOP_LEVEL_HDL_FILE ../rtl_v/jtag_uart_sender.sv
set_module_property TOP_LEVEL_HDL_MODULE jtag_uart_sender
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property ANALYZE_HDL TRUE
set_module_property STATIC_TOP_LEVEL_MODULE_NAME jtag_uart_sender
set_module_property FIX_110_VIP_PATH false
# | 
# +-----------------------------------

# +-----------------------------------
# | files
# | 
add_file ../rtl_v/jtag_uart_sender.sv {SYNTHESIS SIMULATION}
# | 
# +-----------------------------------

# +-----------------------------------
# | parameters
# | 
# | 
# +-----------------------------------

# +-----------------------------------
# | display items
# | 
# | 
# +-----------------------------------

# +-----------------------------------
# | connection point avalon_streaming_sink
# | 
add_interface avalon_streaming_sink avalon_streaming end
set_interface_property avalon_streaming_sink associatedClock clock
set_interface_property avalon_streaming_sink associatedReset reset_sink
set_interface_property avalon_streaming_sink dataBitsPerSymbol 8
set_interface_property avalon_streaming_sink errorDescriptor ""
set_interface_property avalon_streaming_sink firstSymbolInHighOrderBits true
set_interface_property avalon_streaming_sink maxChannel 0
set_interface_property avalon_streaming_sink readyLatency 0

set_interface_property avalon_streaming_sink ENABLED true

add_interface_port avalon_streaming_sink av_sink_error error Input 2
add_interface_port avalon_streaming_sink av_sink_data data Input 8
add_interface_port avalon_streaming_sink av_sink_valid valid Input 1
add_interface_port avalon_streaming_sink av_sink_ready ready Output 1
# | 
# +-----------------------------------

# +-----------------------------------
# | connection point avalon_master
# | 
add_interface avalon_master avalon start
set_interface_property avalon_master addressUnits SYMBOLS
set_interface_property avalon_master associatedClock clock
set_interface_property avalon_master associatedReset reset_sink
set_interface_property avalon_master bitsPerSymbol 8
set_interface_property avalon_master burstOnBurstBoundariesOnly false
set_interface_property avalon_master burstcountUnits WORDS
set_interface_property avalon_master doStreamReads false
set_interface_property avalon_master doStreamWrites false
set_interface_property avalon_master holdTime 0
set_interface_property avalon_master linewrapBursts false
set_interface_property avalon_master maximumPendingReadTransactions 0
set_interface_property avalon_master readLatency 0
set_interface_property avalon_master readWaitTime 1
set_interface_property avalon_master setupTime 0
set_interface_property avalon_master timingUnits Cycles
set_interface_property avalon_master writeWaitTime 0

set_interface_property avalon_master ENABLED true

add_interface_port avalon_master read read Output 1
add_interface_port avalon_master write write Output 1
add_interface_port avalon_master address address Output 3
add_interface_port avalon_master chipselect chipselect Output 1
add_interface_port avalon_master byteenable byteenable Output 4
add_interface_port avalon_master writedata writedata Output 32
add_interface_port avalon_master readdata readdata Input 32
add_interface_port avalon_master waitrequest waitrequest Input 1
# | 
# +-----------------------------------

# +-----------------------------------
# | connection point clock
# | 
add_interface clock clock end
set_interface_property clock clockRate 0

set_interface_property clock ENABLED true

add_interface_port clock clock clk Input 1
# | 
# +-----------------------------------

# +-----------------------------------
# | connection point reset_sink
# | 
add_interface reset_sink reset end
set_interface_property reset_sink associatedClock clock
set_interface_property reset_sink synchronousEdges DEASSERT

set_interface_property reset_sink ENABLED true

add_interface_port reset_sink reset_n reset_n Input 1
# | 
# +-----------------------------------
