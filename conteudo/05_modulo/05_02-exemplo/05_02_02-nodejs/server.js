const express = require('express');
const app = express();

// Simulating memory consumption
function consumeMemory() {
    let largeArray = [];
    // Keep adding objects to the array to consume memory
    for (let i = 0; i < 1e6; i++) {  // Adjust the number as needed
        largeArray.push({ data: 'This is a large object to consume memory' });
    }
    return largeArray;
}

app.get('/home', (req, res) => {
    // Consume memory before sending the response
    consumeMemory();

    // Send a response to the client
    res.json({ message: "Test!" });
});

app.listen(3000, () => {
    console.log('Server is running on http://localhost:3000');
});
