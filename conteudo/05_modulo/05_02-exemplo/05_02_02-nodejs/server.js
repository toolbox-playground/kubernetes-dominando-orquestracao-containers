const express = require('express');
const app = express();

function matrixMultiplication(size) {
    let a = Array.from({ length: size }, () => Array(size).fill(1));
    let b = Array.from({ length: size }, () => Array(size).fill(2));
    let result = Array.from({ length: size }, () => Array(size).fill(0));

    for (let i = 0; i < size; i++) {
        for (let j = 0; j < size; j++) {
            for (let k = 0; k < size; k++) {
                result[i][j] += a[i][k] * b[k][j];
            }
        }
    }
    return result;
}


app.get('/test', (req, res) => {
    matrixMultiplication(300);
    res.json({ message: "Matrix multiplication done!" });
});

app.get('/home', (req, res) => {
    res.json({ message: "Test!" });
});

app.listen(3000, () => console.log('Server running on port 3000'));
