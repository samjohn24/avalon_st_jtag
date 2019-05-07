package require -exact qsys 12.1

# module properties
set_module_property NAME {avalon_st_jtag}
set_module_property DISPLAY_NAME {avalon_st_jtag}

# default module properties
set_module_property VERSION {1.0}
set_module_property DESCRIPTION {default description}
set_module_property AUTHOR {author}

# Instances and instance parameters
# (disabled instances are intentionally culled)
add_instance clk clock_source 13.0
set_instance_parameter_value clk clockFrequency {50000000.0}
set_instance_parameter_value clk clockFrequencyKnown {1}
set_instance_parameter_value clk resetSynchronousEdges {NONE}

add_instance jtag_uart_sender jtag_uart_sender 1.0

add_instance jtag_uart altera_avalon_jtag_uart 13.0.1.99.2
set_instance_parameter_value jtag_uart allowMultipleConnections {0}
set_instance_parameter_value jtag_uart hubInstanceID {0}
set_instance_parameter_value jtag_uart readBufferDepth {8}
set_instance_parameter_value jtag_uart readIRQThreshold {8}
set_instance_parameter_value jtag_uart simInputCharacterStream {}
set_instance_parameter_value jtag_uart simInteractiveOptions {INTERACTIVE_ASCII_OUTPUT}
set_instance_parameter_value jtag_uart useRegistersForReadBuffer {0}
set_instance_parameter_value jtag_uart useRegistersForWriteBuffer {0}
set_instance_parameter_value jtag_uart useRelativePathForSimFile {0}
set_instance_parameter_value jtag_uart writeBufferDepth {32768}
set_instance_parameter_value jtag_uart writeIRQThreshold {8}

# connections and connection parameters
add_connection clk.clk jtag_uart_sender.clock clock

add_connection clk.clk_reset jtag_uart_sender.reset_sink reset

add_connection clk.clk jtag_uart.clk clock

add_connection clk.clk_reset jtag_uart.reset reset

add_connection jtag_uart_sender.avalon_master jtag_uart.avalon_jtag_slave avalon
set_connection_parameter_value jtag_uart_sender.avalon_master/jtag_uart.avalon_jtag_slave arbitrationPriority {1}
set_connection_parameter_value jtag_uart_sender.avalon_master/jtag_uart.avalon_jtag_slave baseAddress {0x0000}
set_connection_parameter_value jtag_uart_sender.avalon_master/jtag_uart.avalon_jtag_slave defaultConnection {0}

# exported interfaces
add_interface clk clock sink
set_interface_property clk EXPORT_OF clk.clk_in
add_interface reset reset sink
set_interface_property reset EXPORT_OF clk.clk_in_reset
add_interface avalon_st_sink avalon_streaming sink
set_interface_property avalon_st_sink EXPORT_OF jtag_uart_sender.avalon_streaming_sink
