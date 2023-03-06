import common
import sys

def encode(data: str): 
    output = ""
    frames_count = 0

    for start in range(0, len(data), common.FRAME_LENGTH):
        frame_data = data[start : start + common.FRAME_LENGTH]
        print(f"Frame {frames_count}: {frame_data}")

        frame_data += common.CRC32(frame_data)

        output += common.ESCAPE_SEQ
        ones_cnt = 0

        while frame_data:
            bit = frame_data[0]
            output += bit

            if bit == '1':
                ones_cnt += 1
                if ones_cnt == common.ESCAPE_COUNT - 1:
                    output += '0'
                    ones_cnt = 0
            else:
                ones_cnt = 0
            
            frame_data = frame_data[1:]

        output += common.ESCAPE_SEQ

        frames_count += 1

    return output

def main(input_fname, output_fname):
    with open(input_fname) as f:
        in_data = f.read()

    out_data = encode(in_data)

    with open(output_fname, "w") as f:
        f.write(out_data)

if __name__ == "__main__":
    input_fname = sys.argv[1]
    output_fname = sys.argv[2]
    main(input_fname, output_fname)