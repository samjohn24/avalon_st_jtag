# =============================================================================
# FILE: jtag_server.tcl
# DATE: 07-Feb-2019
# AUTHOR: Sammy Carbajal
# =============================================================================
# PURPOSE: 
#   TCP/IP Server for Altera JTAG
#   Code Derived from Tcl Developer Exchange 
#    - http://www.tcl.tk/about/netserver.html
# =============================================================================

# Loading routines
source jtag_server/default_master.tcl

set p_address 0
set conn_timeout 20000
set verbose 0
set verbose_basic 0
 
### Start server
# port: socket port
# mode: 0 - command, 1 - data
proc Start_Server {port mode} {
    if {$mode == 0} {
      set s [socket -server CmdConnAccept $port]
      puts "\[CMD\]: Started Command Socket Server on port - $port"
    } else {
      set s [socket -server DataConnAccept $port]
      puts "\[DAT\]: Started Data Socket Server on port - $port"
    }
    vwait forever
}
 
proc DataConnAccept {sock addr port} {
    global conn_data
    global p_path
    global p_address
    global sock_data

    # Open JTAG bytestream
    set p_path [open_bytestream $p_address]
 
    # Record the client's information
    puts "\[DAT\]: Accept $sock from $addr port $port"
    set conn_data(addr,$sock) [list $addr $port]

    set sock_data $sock

 
    # Ensure that each "puts" by the server
    # results in a network transmission
 
    fconfigure $sock -buffering line
 
    # Set up a callback for when the client sends data
    
    fileevent $sock readable [list IncomingData $sock]

}
 
proc IncomingData {sock} {
    global conn_data
    global p_path
 
    # Check end of file or abnormal connection drop,
    # then write the data to the vJTAG
 
    if {[eof $sock] || [catch {gets $sock line}]} {
      close $sock
      puts "\[DAT\]: Close $conn(addr,$sock)"
      unset conn_data(addr,$sock)
    } else {
      if {$line > 0} {
        #set recv_data [get_packet $p_path [expr 2*$line]]
        set recv_data [get_packet_improved $p_path [expr 2*$line]]
        puts $sock $recv_data
      } elseif {$line == -2} {
        #set recv_data [parse_packet [get_frame $p_path]]
        set recv_data [parse_packet [get_n_frames $p_path 1]]
        puts $sock $recv_data
      } elseif {$line == -1} {
	puts $sock [flush_fifo $p_path]
      }
    #puts $recv_data
    # TODO: Add recovery checking
    }
}

proc CmdConnAccept {sock addr port} {
    global conn_cmd

    # Open JTAG master
    #open_default_master
 
    # Record the client's information
 
    puts "\[CMD\]: Accept $sock from $addr port $port"
    set conn_cmd(addr,$sock) [list $addr $port]
 
    # Ensure that each "puts" by the server
    # results in a network transmission
 
    fconfigure $sock -buffering line
 
    # Set up a callback for when the client sends data
    
    fileevent $sock readable [list IncomingCmd $sock]
}

proc IncomingCmd {sock} {
    global conn_cmd
    global conn_data
    global p_address
    global s_data
    global verbose
 
    # Check end of file or abnormal connection drop,
    # then write the data to the vJTAG
 
    if {[eof $sock] || [catch {gets $sock line}]} {
      close $sock
      puts "\[CMD\]: Close $conn_cmd(addr,$sock)"
      unset conn_cmd(addr,$sock)
    } else {
      # Command parse
      set cmd [lindex $line 0]
      set arg0 [lindex $line 1]
      set arg1 [lindex $line 2]

      #puts "\tCommand $cmd received."
      if {$cmd == 0} {
         write_32 $arg0 $arg1
         set writevalue [format "%#010x" $arg1]
         set addressval [format "%#010x" $arg0]
	 if {$verbose} {
           puts "\[CMD\]: Write $writevalue to $addressval address"
	 }
      } elseif {$cmd == 1} {
         set readvalue [format "%#010x" [read_32 $arg0 1]]
         set addressval [format "%#010x" $arg0]
	 if {$verbose} {
           puts "\[CMD\]: Read $readvalue from $addressval address"
	 }
         puts $sock $readvalue
      } elseif {$cmd == 2} {
         puts "\[CMD\]: Close JTAG Master."
         close_default_master
      } elseif {$cmd == 3} {
         puts "\[CMD\]: Open JTAG Master."
         open_default_master
      } elseif {$cmd == 4} {
	 set p_address $arg1
	 if {[info exists s_data]} {
      	   puts "\[DAT\]: Data Socket Server on port - $arg0 already started"
    	   puts $sock 1
	 } else {
      	   set s_data [socket -server DataConnAccept $arg0]
      	   puts "\[DAT\]: Started Data Socket Server on port - $arg0"
    	   puts $sock 1
	 }
	 #TODO: Add routine to detect when is already connected
      } else {
         #puts "Unknown command num: $cmd. Ignoring."
      }
    }

}

# Get packet
proc get_packet {p_path num_bytes} {
  set t0 [clock clicks -millisec]
  set recv_bytes [bytestream_receive $p_path [expr $num_bytes]]
  puts "time recv: [expr {[clock clicks -millisec]-$t0}] ms" 
  set parsed [binary format c* $recv_bytes]
  puts "time recv total: [expr {[clock clicks -millisec]-$t0}] ms" 
  set packet "[format %06d [string length $parsed]]$parsed"
  #puts $packet
  #set packet_show {}
  #foreach char [split $packet ""] {
  #  lappend packet_show [scan $char %c]
  #}
  #puts $packet_show
  return $packet
}

# Get packet large (excluding the latest 2 bytes)
proc get_packet_large {p_path num_bytes} {
  #open_service bytestream [get_bytestream 0]
  #puts "requested $num_bytes bytes"
  set parsed {}
  set t0 [clock clicks -millisec]

  set recv_bytes {}
  #while { [llength recv_bytes] == 0} {
  #  set recv_bytes [bytestream_receive $p_path $num_bytes]
  #}

  set counter 0

  #open_default_bytestream
  while { [llength $recv_bytes] < [expr $num_bytes]} {
    #puts "num recv bytes:[llength $recv_bytes]"
    set req_bytes [expr $num_bytes-[llength $recv_bytes]]
    set recv_data [bytestream_receive $p_path $req_bytes]
    #puts "recv data ([llength $recv_data] bytes of $req_bytes): $recv_data"

    #if { [llength $recv_data] > 2 } {
    #  lappend recv_bytes {*}[lrange $recv_data 0 end-2]
    #  set counter 0
    #} elseif { [llength $recv_data] > 1 } {
    #  lappend recv_bytes {*}$recv_data
    #  set counter 0
    #} else {
    #  incr counter
    #  after 1
    #}
    if { [llength $recv_data] > 0 } {
      lappend recv_bytes {*}$recv_data
      set counter 0
    } else {
      incr counter
      after 1
    }
    
    #puts "recv bytes: $recv_bytes"
    if { $counter > 200000} {
      refresh_connections
      close_default_bytestream
      open_default_bytestream
      set counter 0
      break
    }
  }
  #close_default_bytestream

  #puts $recv_bytes
  #puts "\ttime recv: [expr {[clock clicks -millisec]-$t0}] ms" 
  foreach byte $recv_bytes {
    append parsed [format %02x $byte]
  }
  #binary scan $recv_bytes H* parsed
  set parsed_len [string length $parsed]
  set packet "[format %06d $parsed_len]$parsed"
  if { $parsed_len > 0 } {
    #puts "\t$parsed_len bytes sent"
  }
  #puts "\ttime recv total: [expr {[clock clicks -millisec]-$t0}] ms" 
  #puts $packet
  #set packet_show {}
  #foreach char [split $packet ""] {
  #  lappend packet_show [scan $char %c]
  #}
  #puts $packet_show
  #close_service bytestream [get_bytestream 0]
  return $packet
}

# Get frames
proc get_frame {p_path} {
  global conn_timeout
  global verbose
  global verbose_basic

  set t0 [clock clicks -millisec]

  if {$verbose_basic} {
    puts "read header init..."
  }

  # Get header
  set recv_header {}
  while 1 {
    lappend recv_header {*}[bytestream_receive $p_path [expr 2-[llength $recv_header]]]
    if { [llength $recv_header] >= 2 } break
  }
  
  if {$verbose_basic} {
    puts "header: $recv_header"
  }

  # Required num bytes
  set req_bytes [expr wide(2*pow(2, [lindex $recv_header 0]))]

  if {$verbose} {
    puts "num bytes: $req_bytes"
  }

  # Get data
  set recv_bytes {}
  while 1 {
    lappend recv_bytes {*}[bytestream_receive $p_path [expr $req_bytes-[llength $recv_bytes]]]
    if { [llength $recv_bytes] >= [expr $req_bytes] } break
    #else {after 1 }
  }

  if {$verbose} {
    puts "recv bytes ([llength $recv_bytes] bytes): $recv_bytes"
    puts "\ttime recv: [expr {[clock clicks -millisec]-$t0}] ms" 
  }

  # data with tag
  set recv_bytes_tag {}
  lappend recv_bytes_tag [lindex $recv_header 1]
  lappend recv_bytes_tag {*}$recv_bytes

  if {$verbose} {
    puts "data with tag: $recv_bytes_tag"
  }

  return $recv_bytes_tag

}

proc get_n_frames {p_path N} {
  set i 0
  set packet {}
  while {$i < $N} {
    lappend packet {*}[get_frame $p_path]
    incr i
  }  
  return $packet
}

proc parse_packet {recv_bytes} {
  global verbose

  # Parse data
  set parsed {}
  foreach byte $recv_bytes {
    append parsed [format %02x $byte]
  }

  if {$verbose} {
    puts "data parsed: $parsed"
  }

  # Packet
  set packet "$parsed"
  if {$verbose} {
    puts "packet: $packet"
  }

  set packet_len [string length $packet]
  set whole_packet "[format %06d $packet_len]$packet"

  if {$verbose} {
    show_packet $whole_packet
  }

  #puts "\ttime recv total: [expr {[clock clicks -millisec]-$t0}] ms" 
  return $whole_packet
}

# Get packet large
proc get_packet_improved {p_path num_bytes} {
  global conn_timeout

  set t0 [clock clicks -millisec]

  set counter 0

  set recv_bytes {}
  while { [llength $recv_bytes] < [expr $num_bytes]} {
    set req_bytes [expr $num_bytes-[llength $recv_bytes]]
    set recv_data [bytestream_receive $p_path $req_bytes]
    #puts "recv data ([llength $recv_data] bytes of $req_bytes): $recv_data"

    if { [llength $recv_data] > 0 } {
      lappend recv_bytes {*}$recv_data
      set counter 0
    } else {
      incr counter
      after 1
    }
    
    if { $counter > $conn_timeout} {
      refresh_connections
      close_default_bytestream
      open_default_bytestream
      set counter 0
      break
    }
  }

  #puts "recv bytes ([llength $recv_bytes] bytes): $recv_bytes"
  #puts "\ttime recv: [expr {[clock clicks -millisec]-$t0}] ms" 
  
  set parsed {}
  foreach byte $recv_bytes {
    append parsed [format %02x $byte]
  }

  set parsed_len [string length $parsed]
  set packet "[format %06d $parsed_len]$parsed"

  #if { $parsed_len > 0 } {
    #puts "\t$parsed_len bytes sent"
  #}

  #show_packet $packet

  #puts "\ttime recv total: [expr {[clock clicks -millisec]-$t0}] ms" 
  return $packet
}

proc show_packet {packet} {
  puts $packet
  set packet_show {}
  foreach char [split $packet ""] {
    lappend packet_show [scan $char %c]
  }
  puts $packet_show
}

proc flush_fifo {p_path} {

  set num_bytes 48

  set recv_data {}

  while 1 {
    set recv_data [bytestream_receive $p_path $num_bytes]

    if { [llength $recv_data] <=0 } break
  }

  return 1
}

open_default_master

Start_Server 2540 0
