const mysql = require('mysql2/promise');

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'admin',
  password: process.env.DB_PASS || 'senha123',
  database: process.env.DB_NAME || 'appdb',
  port: process.env.DB_PORT || 3306,
});

module.exports = pool;
