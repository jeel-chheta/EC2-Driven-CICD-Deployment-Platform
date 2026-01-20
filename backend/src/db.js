const { Pool } = require('pg');

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    max: 20,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 2000,
});

// Test connection on startup
pool.query('SELECT NOW()', (err, res) => {
    if (err) {
        console.error('❌ Database connection failed:', err.message);
    } else {
        console.log('✅ Database connected successfully at', res.rows[0].now);
    }
});

// Handle pool errors
pool.on('error', (err) => {
    console.error('Unexpected database error:', err);
});

module.exports = {
    query: (text, params) => pool.query(text, params),
    end: () => pool.end(),
    pool
};
