import argparse

from . import start

parser = argparse.ArgumentParser(description='Oremi Player')
parser.add_argument('--port', type=int, default = 3765, help='Server port')
args = parser.parse_args()

start(args.port)
