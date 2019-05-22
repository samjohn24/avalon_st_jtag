"""
 +FHDR-------------------------------------------------------------------------
 FILE NAME      : jtag_client.py
 AUTHOR         : Sammy Carbajal
 ------------------------------------------------------------------------------
 PURPOSE
  Client to interface with Altera JTAGUART using system-console server.
 -FHDR-------------------------------------------------------------------------
"""
import socket
import textwrap
import struct
import time
import collections
import threading
 
class AlteraJTAGClient:

    def __init__(self, host='localhost', port=2540):
        self.host = host
        self.port = port
        self.conn = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.conn.connect(( host,port))

    def close(self):
        self.conn.close()

    def WriteMaster(self, address, data):
        self.conn.send("00 %d %d\n" %(address, data))

    def ReadMaster(self, address):
        self.conn.send("01 %d\n" %(address))
        data = self.conn.recv(10)
        self.conn.recv(2)
        return int(data[2:10],16)

    def StartBytestreamServer(self, port=2541, address=0):
        self.conn.send("04 %d %d\n" %(port, address))
        while self.conn.recv(1) != "1":
            pass
        self.conn.recv(2)

class BytestreamClient(threading.Thread):

    def __init__(self, queue, host='localhost', port=2541, jtag_packet_len=48*10, buf_packet_len=10, buf_maxlen=2, buf_num=1, mode="packet"):
        threading.Thread.__init__(self)
        self.queue = queue
        self.host = host
        self.port = port
        self.num_misses = 0
        self.buf_packet_len = buf_packet_len
        self.jtag_packet_len = jtag_packet_len
        self.mode = mode
        self.buf_num = buf_num
        
        # Socket create and connect
        self.conn = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.conn.connect(( host,port))
        
        # Buffer deque create
        self.buffer = collections.deque(maxlen=buf_maxlen)

        if mode == "frame_buffer_tag":
            self.buffers_tag = [collections.deque(maxlen=buf_maxlen) for i in range(buf_num)] 

    def str2short(self, hexstr):
        """
        Convert a little endian bytestring(hex format) to short
        Ex: "2345" -> 13330 
        """
        return struct.unpack('<h',bytearray([int(hexstr[0:2],16),int(hexstr[2:4],16)]))[0]

    def ascii2short(self, char):
        """
        Convert a little endian bytestring(hex format) to short
        Ex: "xc" -> 13330 
        """
        return struct.unpack('<h',char)[0]
        
    def GetBytestream(self, size):
        return self.conn.recv(size)
    
    def ReqShortSamples(self, num_samples=48*10):
        self.conn.send(str(num_samples) + '\n')

    def RecvPacketAscii(self, verbose=False):

        # Receive packet length
        try:
            packet_len = int(self.conn.recv(6))+2
            if verbose:
                print 'packet len: %d'%packet_len
        except ValueError:
            return ""

        # Receive packet
        data = ""
        while (len(data) < packet_len):
            start = time.time()
            if verbose:
                print '\ttry to receive %d bytes' % (packet_len-len(data))

            packet = self.conn.recv(packet_len - len(data))
            if verbose:
                print '\treceived %d bytes: "%s"' % (len(packet),list(packet))
                print '\tproc recv packet: %.2f ms' %((time.time()-start)*1e3) 

            data += packet
            data = data[:-1].replace('\r\n','\n')+data[-1]
            if verbose:
                print '\tproc total packet: %.2f ms' %((time.time()-start)*1e3) 
        
        if verbose:
            print 'total received %d bytes: "%s"' % (len(data),list(data))

        # Check is even and return
        if len(data) % 2 == 0:
            return data[:-2]
        else:
            return data[:-3]
        
    def RecvFrame(self, verbose=False):

        # Receive packet length
        try:
            packet_len = int(self.conn.recv(6))+2
            if verbose and packet_len>2:
                print 'packet len: %d'%packet_len
        except ValueError:
            return ""

        # Receive packet
        data = ""
        while (len(data) < packet_len):
            start = time.time()

            if verbose and packet_len>2:
                print '\ttry to receive %d bytes' % (packet_len-len(data))
            packet = self.conn.recv(packet_len - len(data))

            if verbose and packet_len>2:
                print '\treceived %d bytes: "%s"' % (len(packet),list(packet))
                print '\tproc recv packet: %.2f ms' %((time.time()-start)*1e3) 

            data += packet
            data = data[:-1].replace('\r\n','\n')+data[-1]
            if verbose and packet_len>2:
                print '\tproc total packet: %.2f ms' %((time.time()-start)*1e3) 
        
        if verbose and packet_len>2:
            print 'total received %d bytes: "%s"' % (len(data),list(data))

        tag = data[:2]
        data = data[2:]

        return tag + data[:4*((len(data)-2)/4)]

    def RecvPacketRaw(self, verbose=False):

        # Receive packet length
        try:
            packet_len = int(self.conn.recv(6))+2
            if verbose and packet_len>2:
                print 'packet len: %d'%packet_len
        except ValueError:
            return ""

        # Receive packet
        data = ""
        while (len(data) < packet_len):
            start = time.time()

            if verbose and packet_len>2:
                print '\ttry to receive %d bytes' % (packet_len-len(data))
            packet = self.conn.recv(packet_len - len(data))

            if verbose and packet_len>2:
                print '\treceived %d bytes: "%s"' % (len(packet),list(packet))
                print '\tproc recv packet: %.2f ms' %((time.time()-start)*1e3) 

            data += packet
            data = data[:-1].replace('\r\n','\n')+data[-1]
            if verbose and packet_len>2:
                print '\tproc total packet: %.2f ms' %((time.time()-start)*1e3) 
        
        if verbose and packet_len>2:
            print 'total received %d bytes: "%s"' % (len(data),list(data))

        return data[:4*((len(data)-2)/4)]

    def RawToInt (self, data, verbose=False):
        if data == "":
            return [] 

        start = time.time()

        data_out = ""
        for i in range(0,len(data),4):
            data_out += chr(int(data[i:i+2],16))+chr(int(data[i+2:i+4],16))

        if verbose:
            print 'total received parsed %d bytes: "%s"' % (len(data_out),list(data_out))
            print '\tproc RawParse: %.2f ms' %((time.time()-start)*1e3) 

        data_int = struct.unpack('>'+'h'*(len(data_out)/2),data_out)

        if verbose:
            print 'total received %d samples: "%s"' % (len(data_int),list(data_int))
            print '\tproc RawToInt: %.2f ms' %((time.time()-start)*1e3) 

        return data_int

    def getSamples(self, num_samples=48*10, verbose=False):
        # Request samples
        self.conn.send(str(num_samples) + '\n')

        # Receive raw packet
        data_raw = self.RecvPacketRaw(verbose)

        return self.RawToInt(data_raw, verbose)

    def flushFIFO(self, verbose=False):
        # Request samples
        self.conn.send(str(-1) + '\n')

        # Receive raw packet
        data_raw = self.conn.recv(3)
        if verbose:
            print "Flush FIFO data:", data_raw

        return 

    def getData (self, verbose=False):
        return self.RawToInt(self.buffer.pop()[0], verbose)

    def getDataN (self, num_packets, frame_tag=0, verbose=False):
        data = ""
        tag = ""
        i = 0
        while i < num_packets:
            if self.mode == "frame":
              packet = self.buffer.pop()[0]
              data += packet[2:]
              tag += "00" + packet[:2]
            elif self.mode == "frame_buffer_tag":
              if frame_tag in range(self.buf_num):
                  packet = self.buffers_tag[frame_tag].pop()[0]
                  data += packet
            else:
              packet = self.buffer.pop()[0]
              data += packet
            i += 1 
        
        return self.RawToInt(data, verbose), self.RawToInt(tag, verbose)

    def run(self):
        verbose = False
        data_raw = ""
        desired_len = 4*self.buf_packet_len*self.jtag_packet_len

        while (True):
            period = time.time()
            
            if self.mode == "packet":
                while(len(data_raw) < desired_len):

                    # Request samples
                    self.conn.send(str(self.jtag_packet_len) + '\n')

                    # Receive raw packet
                    data_raw += self.RecvPacketRaw(verbose)

                # Save into buffer
                self.buffer.appendleft([data_raw[:desired_len]])

                # Clear buffered samples
                data_raw = data_raw[desired_len:]

            elif self.mode == "frame":
                # Request samples
                self.conn.send(str(-2) + '\n')

                # Receive raw packet
                data_raw = self.RecvFrame(verbose)

                # Save into buffer
                self.buffer.appendleft([data_raw])

            elif self.mode == "frame_buffer_tag":
                # Request samples
                self.conn.send(str(-2) + '\n')

                # Receive raw packet
                data_raw = self.RecvFrame(verbose)
                
                # Tag
                #print data_raw[:2]
                tag = int(str(data_raw[:2]),16)
                #print "%d" %tag
                
                # Save into respective buffer
                if tag in range(self.buf_num):
                    self.buffers_tag[tag].appendleft([data_raw[2:]])

            else:
                raise ValueError('Invalid mode') 

            if verbose:
                print 'buffer len %d:' %(len(self.buffer)),self.buffer

            
            # Send message
            #self.queue.put("new data elem")
            #if len(self.buffer) > 1:
            #    self.queue.put("quit")
            #else:
            if verbose:
                print "thread_period: %d ms" %((time.time()-period)*1e3)
