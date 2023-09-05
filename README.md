# Smart Contract based M+1st-Price Sealed-bid Auction

In NFT, PoS, Cross-Chain Communication and DEX, a Vickrey auction is proven (the prover won a Nobel prize) to increase the seller's income and the bidder pays their true valuation. The bidder with the highest bid wins and pays the second-highest price for the goods.
Google Ads used a Vickrey auction but migrated to an English auction because it is not easy to achieve public verifiability on the second price.
A Vickrey auction can be generalized to an M+1st-price auction that sells M goods. The highest M winners pay the M+1st-price.

### Required Properties of a Secure (Vickrey or M+1st-price) Sealed-bid Auction

* **Correctness**: The protocol can find exactly M winners and the M+1st price.
* **Public Verifiability**: The result can be publicly verifiable.
* **Bid Secrecy**: All bidder's bids should be kept as a secret.
* **M+1st-Bidder's Anonymity**: The identity of the bidder who bids the M+1st-price should be kept a secret.
* **No Trusted Manager**: A trusted manager is not necessary in our protocol.
* **Bid Binding**: Each bidder cannot change their bid after submitting it to the Smart Contract.
* **Financial Fairness**: The malicious (absent) bidder's stake will be used to compensate honest bidders.

We proposed three Smart Contract based auction protocols. All of them fulfill the required properties and provide additional features without a trusted manager.

### Auction Protocol with Exponential Bid Upper Bound (2023)

In the `IEEE-Access` and the `master` branch, we focus on extending the bid upper bound. The time complexity of this protocol is O(M log P) per bidder.
A bit-slice bidding vector V is necessary to compare each bidder's bids secretly without a trusted manager. The upper bound of a bidder's bid is bounded by the length of the bidding vector |V|. In this protocol, we use a base-2 binary format to encode the bidding vector. To our best knowledge, this is the first secure M+1st-price auction protocol that can reach an exponential level bid upper bound 2^|V| without a trusted manager, somewhat homomorphic encryption (SHE) and fully homomorphic encryption (FHE). Please read the following [journal paper](https://ieeexplore.ieee.org/abstract/document/10225494) for more details.

> Po-Chu Hsu and Atsuko Miyaji. ``Blockchain based M+1st-Price Auction with Exponential Bid Upper Bound''. In IEEE Access, vol. 11, pages 91184-91195, 2023

The conference version can be found in the `SciSec2022` branch. Please read the following [conference paper](https://link.springer.com/chapter/10.1007/978-3-031-17551-0_8) for more details.

> Po-Chu Hsu and Atsuko Miyaji. ``Scalable M+1st-Price Auction with Infinite Bidding Price''. In International Conference on Science of Cyber Security (SciSec’22), LNCS 13580, Springer-Verlag, pages 121–136, 2022


### Auction Protocol with Optimal Time Complexity (2022)

In the `TrustCom2021` branch, we focus on optimizing the time complexity. The time complexity of this protocol is O(P) per bidder.
The time complexity for a trusted manager is usually O(BPM) since the manager needs to compare all B bidder's bids, verify each bidder's bidding vector with length P and find M winning bidders.
We use zero-knowledge proofs to remove the B factor and we found a greedy strategy to remove the M factor.
To our best knowledge, this is the first secure M+1st-price auction protocol that can each an optimal time complexity without a trusted manager and Mix and Match protocol. Please read the following [conference paper](https://ieeexplore.ieee.org/abstract/document/9724495/) for more details.

> Po-Chu Hsu and Atsuko Miyaji. ``Bidder Scalable M+1st-Price Auction with Public Verifiability''. In International Conference on Trust, Security and Privacy in Comput- ing and Communications (TrustCom’21), IEEE, pages 34–42, 2021

### Auction Protocol without a Trusted Manager (2021)

In the `DSC2021` branch, we focus on how to use Smart Contracts to replace the trusted manager. The time complexity of this protocol is O(BPM) per bidder.
To our best knowledge, this is the first secure M+1st-price auction protocol that can fulfill all required properties without a trusted manager. Please read the following [journal paper](https://www.hindawi.com/journals/scn/2021/1615117/) for more details.

```
Po-Chu Hsu and Atsuko Miyaji. ``Publicly Verifiable M+1st-Price Auction Fit for IoT with Minimum Storage''. In Security and Communication Networks, pages 1–10, 2021
```

The conference version is the same as the `DSC2021` branch. Please read the following [conference paper](https://ieeexplore.ieee.org/abstract/document/9346242) for more details.

```
Po-Chu Hsu and Atsuko Miyaji. ``Verifiable M+1st-Price Auction without Manager''. In Conference on Dependable and Secure Computing (DSC’21), IEEE, pages 1–8, 2021
```


## Usage

```
usage: main.py [-h] [--port PORT] -M M -B BIDDER -L L
```

* `--port`: the port of the Ethereum simulator RPC
* `-M`: the number of goods the seller wants to sell.
* `-B`: the number of bidders you want to simulate.
* `-L`: the length of the bidding price.


## Tutorial

In the tutorial, we demonstrate how to deploy the auction Smart Contract to an Ethereum simulator [ganache-cli](https://github.com/trufflesuite/ganache) and use our [Python Web3 Client](https://github.com/tonypottera24/m-1st_auction_sol) to benchmark the gas usage.
You don't need to read this tutorial if you want to build your own web3 client.

> This tutorial is tested on a Ubuntu 22.04 (LTS) server.

### Step 1. Download the repository

1. The auction Smart Contract.
    ```
    git clone https://github.com/tonypottera24/m-1st_auction_sol.git
    ```
2. The [Python Web3 Client](https://github.com/tonypottera24/m-1st_auction_sol) we designed to benchmark the Smart Contract.
    ```
    git clone https://github.com/tonypottera24/m-1st_auction_py.git
    ```

### Step 2. Install and activate Python virtual environment (Optional)

This step can make sure you are using the python packages we tested.

1. Install a virtual environment such as `python3-venv`.
    ```
    sudo apt install python3-venv
    ```
2. Create and activate the virtual environment.
    ```
    cd m-1st_auction_py
    python3 -m venv venv
    source venv/bin/activate
    ```
3. Install required packages to build Python packages.
    ```
    sudo apt install build-essential python3-dev libgmp-dev
    ```
4. Install required python packages.
    ```
    pip install -r requirements.txt
    ```

### Step 3. Install a Solidity compiler

Please follow the instructions on the official website [py-solc-x](https://solcx.readthedocs.io/en/latest/) if the following example doesn't works for you.

1. Enter the Python interpreter
    ```
    python
    ```
2. Get installable `solc` (Solidity compiler) versions.
    > The `>>>` part is the command you need to type in the interpreter.
    ```
    >>> import solcx
    >>> solcx.get_installable_solc_versions()
    [Version('0.8.21'), ...]
    ```
3. Install version `0.8.21` (you can install the latest compatible version)
    ```
    >>> solcx.install_solc(version="0.8.21")
    Version('0.8.21')
    ```
4. You can use the following command to check the installed compiler version.
    ```
    >>> solcx.get_installed_solc_versions()
    [Version('0.8.21')]
    ```

### Step 4. Install and start the Ethereum simulator

> In this tutorial, we use [ganache-cli](https://github.com/trufflesuite/ganache) as an example.
> Please follow the instructions on the official website [ganache-cli](https://github.com/trufflesuite/ganache) if the following example doesn't works for you.

1. Install the `ganache-cli` package.
    ```
    apt install npm
    npm install ganache --global
    ```
2. Start the `ganache-cli`.
    ```
    ganache-cli --miner.defaultGasPrice 1 --miner.blockGasLimit 0xfffffffffff --miner.callGasLimit 0xfffffffffff --chain.allowUnlimitedContractSize --logging.debug -a 1000
    ```
1. Install a Solidity compiler such as [py-solc-x](https://pypi.org/project/py-solc-x/). You need to follow the instructions on their website to download the binary.
1. The codes in `contract.py` will use the Solidity compiler downloaded by `py-solc-x` to compile the Smart Contract and deploy the compiled contract to the Ganache simulator.


### Step 5.


## Contributions

If you have any questions or want to learn more about this research, please open an issue or send a mail to the following address.

* Po-Chu Hsu: tonypottera[at]gmail.com

## License

This project is licensed under the MIT License - see the LICENSE.txt file for details
