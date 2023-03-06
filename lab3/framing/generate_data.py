import random
import sys

def main(fname, size):
    s = [random.choice(['0', '1']) for i in range(size)]
    s = ''.join(s)
    with open(fname, "w") as f:
        f.write(s)

if __name__ == "__main__":
    n = int(sys.argv[1])
    fname = sys.argv[2]
    main(fname, n)