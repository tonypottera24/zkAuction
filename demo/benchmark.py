#!/usr/bin/env python3
import random

# from multiprocessing import Process
import threading
from seller import Seller
import argparse
import logging
import sys

logging.basicConfig(stream=sys.stderr, level=logging.INFO)
logging.getLogger("websockets.client").disabled = True
logging.getLogger("web3.providers.WebsocketProvider").disabled = True
logging.getLogger("web3.RequestManager").disabled = True

parser = argparse.ArgumentParser()
parser.add_argument("--port", help="port", type=int, default=8545)
parser.add_argument("-M", help="number of goods", type=int, default=1)
parser.add_argument("-B", help="number of bidders", type=int, required=True)
parser.add_argument("-L", help="bidding vector length", type=int, required=True)
args = parser.parse_args()

B = args.B
M = args.M
L = args.L

logging.info(f"M = {M}, B = {B}, L = {L}\n")


seller = Seller(M=M, L=L, timeout=[1, B * 2, 1000000, 1000000, 1000000])

seller.deploy()


from bidder import Bidder

bidders = [Bidder(index=i + 1, port=args.port) for i in range(B)]

while True:
    bids = [random.randrange(1, pow(2, L)) for i in range(B)]
    sorted_bids = sorted(bids, reverse=True)
    correct_m1st_price = sorted_bids[M]
    if sorted_bids[M - 1] != sorted_bids[M]:
        break
    logging.info("gen random bids")

bidder_processes = []
for i, bidder in enumerate(bidders):
    # p = Process(target=bidder.start, args=(bids[i],))
    p = threading.Thread(target=bidder.start, args=(bids[i],))
    p.start()
    bidder_processes.append(p)

for p in bidder_processes:
    p.join()

calculated_m1st_price = seller.get_m1st_price()
assert correct_m1st_price == calculated_m1st_price

logging.info(bids)
logging.info(f"correct_m1st_price = {correct_m1st_price}")


# avg = sum([bidder.gas_used for bidder in bidders]) // len(bidders)
# logging.info(f'average gas usage {avg:,}')
