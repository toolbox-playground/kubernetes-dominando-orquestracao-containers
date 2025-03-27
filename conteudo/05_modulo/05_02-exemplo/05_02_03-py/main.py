from flask import Flask, request, jsonify
import mysql.connector

app = Flask(__name__)

# Configurações do banco de dados
db_config = {
    'user': 'seu_usuario',
    'password': 'sua_senha',
    'host': 'mysql',
    'database': 'appdb'
}

@app.route('/items', methods=['GET'])
def get_items():
    conn = mysql.connector.connect(**db_config)
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM items")
    items = cursor.fetchall()
    cursor.close()
    conn.close()
    return jsonify(items)

@app.route('/items', methods=['POST'])
def add_item():
    new_item = request.json
    conn = mysql.connector.connect(**db_config)
    cursor = conn.cursor()
    cursor.execute("INSERT INTO items (name) VALUES (%s)", (new_item['name'],))
    conn.commit()
    cursor.close()
    conn.close()
    return '', 201

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
