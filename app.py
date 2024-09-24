import warnings
import os
from dotenv import load_dotenv
from web3 import Web3
from flask import Flask, jsonify, abort

warnings.filterwarnings("ignore")
load_dotenv()

api_key = os.getenv('API_KEY')
infura_url = f'https://mainnet.infura.io/v3/{api_key}'
web3 = Web3(Web3.HTTPProvider(infura_url))

app = Flask(__name__)

@app.route('/')
def index():
    return jsonify({"message": "Hello from AWS Lambda!"})

@app.route('/address/balance/<address>', methods=['GET'])
def balance(address):
    if not web3.is_address(address):
        abort(400, description="Invalid Ethereum address.")

    try:
        balance = web3.eth.get_balance(address)
    except Exception as e:
        abort(500, description=str(e))
    balance_in_ether = web3.from_wei(balance, 'ether')
    return jsonify({"balance": str(balance_in_ether)})

@app.errorhandler(400)
def bad_request(error):
    response = jsonify({
        "error": "Bad Request",
        "message": error.description
    })
    response.status_code = 400
    return response

@app.errorhandler(404)
def not_found(error):
    response = jsonify({
        "error": "Not Found",
        "message": "The requested URL was not found on the server."
    })
    response.status_code = 404
    return response

@app.errorhandler(500)
def internal_server_error(error):
    response = jsonify({
        "error": "Internal Server Error",
        "message": error.description
    })
    response.status_code = 500
    return response

@app.errorhandler(Exception)
def unhandled_exception(e):
    response = jsonify({
        "error": "Internal Server Error",
        "message": str(e)
    })
    response.status_code = 500
    return response

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5005, debug=True)
