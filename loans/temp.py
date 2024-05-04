import json

with open('loans/brownie/build/contracts/LoanSystem.json', 'r') as f:
    contract_abi = json.load(f)['abi']

print(contract_abi)