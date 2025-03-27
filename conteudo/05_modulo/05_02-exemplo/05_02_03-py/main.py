from flask import Flask, jsonify
import math

app = Flask(__name__)

def is_prime(n):
    if n < 2:
        return False
    for i in range(2, int(math.sqrt(n)) + 1):
        if n % i == 0:
            return False
    return True

@app.route('/test', methods=['GET'])
def heavy_cpu_task():
    primes = [x for x in range(10**6, 10**6 + 5000) if is_prime(x)]
    return jsonify({"message": "Heavy computation done!", "primes_found": len(primes)})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
