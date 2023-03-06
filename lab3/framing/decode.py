import common
import sys

def decode(data: str):
    ones_counter = 0
    frame = ""
    output = ""

    correct_frames = 0

    while data:
        # load first bit from FIFO
        bit = data[0]

        # pop the first bit from FIFO
        data = data[1:]

        if bit == '1':
            ones_counter += 1
            if ones_counter >= common.ESCAPE_COUNT + 1:
                # too long stream of 1s, ignore it
                frame = ""
            else:
                frame += bit
        else:
            if ones_counter == common.ESCAPE_COUNT:
                # ESCAPE
                # remove the trailing escape sequence
                frame = frame[:-(common.ESCAPE_COUNT + 1)]

                if frame:
                    # split the frame into true payload and checksum
                    payload, crc = frame[:-common.CRC_LENGTH], frame[-common.CRC_LENGTH:]

                    # verify CRC
                    expected_crc = common.CRC32(payload)
                    if crc == expected_crc:
                        # handle the correctly decoded data
                        print(f"Frame {correct_frames}: {payload}")
                        correct_frames += 1
                        output += payload
                    else:
                        print("Frame with invalid CRC")

                # clear frame buffer
                frame = ""
            elif ones_counter == common.ESCAPE_COUNT - 1:
                # skip the additional '0', introduced during encoding
                pass 
            else:
                # normal data bit
                frame += bit 

            ones_counter = 0

    return output

    

def main(input_fname, output_fname):
    with open(input_fname) as f:
        in_data = f.read()

    out_data = decode(in_data)

    with open(output_fname, "w") as f:
        f.write(out_data)

if __name__ == "__main__":
    input_fname = sys.argv[1]
    output_fname = sys.argv[2]
    main(input_fname, output_fname)