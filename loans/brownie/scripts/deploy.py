# deploy.py
from brownie import LoanSystem, accounts, network, config

def main():
    # Set the account to deploy from (you can use your Ganache accounts)
    account = accounts[0]

    # Deploy the contract
    my_contract = LoanSystem.deploy({"from": account})

    # Print contract address
    print(f"Contract deployed at address: {my_contract.address}")

    # Additional setup or interactions with the contract can be done here
    # ...

if __name__ == "__main__":
    main()
