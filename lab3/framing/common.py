import binascii


FRAME_LENGTH = 32
ESCAPE_COUNT = 6
ESCAPE_SEQ = '0' + ESCAPE_COUNT * '1' + '0'
CRC_LENGTH = 32

def CRC32(data: str):
    # split the data into 8-bit chunks
    int_arr = [int(data[i:i+8], 2) for i in range(0, len(data), 8)] 
    v = binascii.crc32(bytes(int_arr))
    return format(v, 'b').rjust(32, '0')