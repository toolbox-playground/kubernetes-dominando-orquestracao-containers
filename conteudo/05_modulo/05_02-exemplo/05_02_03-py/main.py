from flask import Flask, jsonify

app = Flask(__name__)

# Simulating memory consumption
def consume_memory():
    large_list = []
    # Keep adding objects to the list to consume memory
    for _ in range(int(1e6)):  # Adjust the number as needed
        large_list.append({'data': 'This is a large object to consume memory'})
    return large_list

@app.route('/home', methods=['GET'])
def home():
    # Consume memory before sending the response
    consume_memory()

    # Send a response to the client
    return jsonify({'message': 'Test!'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=3000)
