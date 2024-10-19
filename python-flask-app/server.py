from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/health-check', methods=['GET'])
def output():
    return jsonify({"message": "The server is healthy"})

if __name__ == '__main__':
    # Run the app on host 0.0.0.0 and port 5000
    app.run(host='0.0.0.0', port=5000)
