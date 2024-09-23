import warnings
import os
from dotenv import load_dotenv
from web3 import Web3
from flask import Flask, jsonify

warnings.filterwarnings("ignore")
load_dotenv()

api_key = os.getenv('API_KEY')
infura_url = f'https://mainnet.infura.io/v3/{api_key}'
web3 = Web3(Web3.HTTPProvider(infura_url))

app = Flask(__name__)

@app.route('/')
def index():
    return jsonify({"message": "Hello from AWS Lambda!"})

@app.route('/address/balance', methods=['GET'])
def balance():
    # Fetch Ethereum balance for a hardcoded address
    balance = web3.eth.get_balance("0xc94770007dda54cF92009BFF0dE90c06F603a09f")

    # Use web3.fromWei to convert from Wei to Ether
    balance_in_ether = web3.from_wei(balance, 'ether')
    return jsonify({"balance": str(balance_in_ether)})

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5005, debug=True)
