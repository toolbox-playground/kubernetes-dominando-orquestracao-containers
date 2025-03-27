const express = require('express');
const db = require('./db');
const app = express();

app.use(express.json());

app.get('/items', async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM items');
    res.json(rows);
  } catch (err) {
    console.error('Error fetching items:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/items', async (req, res) => {
  const { name } = req.body;
  if (!name) return res.status(400).json({ error: 'Missing name' });

  try {
    await db.query('INSERT INTO items (name) VALUES (?)', [name]);
    res.status(201).json({ message: 'Item created' });
  } catch (err) {
    console.error('Error inserting item:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`App listening on port ${PORT}`);
});
