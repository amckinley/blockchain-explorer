import warnings
warnings.filterwarnings("ignore")

import os
from web3 import Web3, exceptions

from flask import Flask, jsonify

api_key = os.getenv('API_KEY')
infura_url =  'https://mainnet.infura.io/v3/{}'.format(api_key)
web3 = Web3(Web3.HTTPProvider(infura_url))

app = Flask(__name__)

@app.route('/')
def index():
    return jsonify({"message": "Hello from AWS Lambda!"})

@app.route('/address/balance')
def balance():
    bal = web3.eth.get_balance("0xc94770007dda54cF92009BFF0dE90c06F603a09f")
    return jsonify({"balance": web3.fromWei(bal, 'ether')})


if __name__ == "__main__":
    app.run(debug=True)