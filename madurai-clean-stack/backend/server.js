const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const helmet = require('helmet');
const path = require('path');
const apiRoutes = require('./routes/apiRoutes');

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware for security, CORS, payload parsing, and logging
app.use(helmet({
    contentSecurityPolicy: false // Needed if serving local frontend with inline scripts/styles for dev
}));
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan('dev'));

// Static files (Serve the Madurai Clean-Stack Landing Page from the parent directory)
app.use(express.static(path.join(__dirname, '../')));

// Main API Routes Hook
app.use('/api/v1', apiRoutes);

// General Health Check Endpoint
app.get('/health', (req, res) => {
    res.status(200).json({
        status: 'UP',
        message: 'Madurai Clean-Stack API System is running securely.',
        timestamp: new Date().toISOString()
    });
});

// Fallback for 404 Routes
app.use((req, res, next) => {
    res.status(404).json({ error: 'Route not found' });
});

// Global Error Handler
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ error: 'Internal Server Error', details: err.message });
});

// Start the Express Server
app.listen(PORT, () => {
    console.log(` Madurai Clean-Stack Server is running on http://localhost:${PORT}`);
    console.log(` Base API URL: http://localhost:${PORT}/api/v1`);
});
