const express = require('express');
const router = express.Router();
const db = require('../db');

/**
 * GET /api/health
 * Health check endpoint for monitoring and deployment validation
 */
router.get('/', async (req, res) => {
    try {
        // Check database connectivity
        const result = await db.query('SELECT NOW() as timestamp');

        res.json({
            status: 'healthy',
            timestamp: result.rows[0].timestamp,
            database: 'connected',
            uptime: process.uptime(),
            memory: process.memoryUsage()
        });
    } catch (error) {
        console.error('Health check failed:', error);
        res.status(503).json({
            status: 'unhealthy',
            timestamp: new Date().toISOString(),
            database: 'disconnected',
            error: error.message
        });
    }
});

module.exports = router;
