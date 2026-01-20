const express = require('express');
const router = express.Router();
const db = require('../db');

/**
 * GET /api/users
 * Retrieve all users from the database
 */
router.get('/', async (req, res) => {
    try {
        const result = await db.query(
            'SELECT id, name, email, created_at FROM users ORDER BY id ASC'
        );

        res.json(result.rows);
    } catch (error) {
        console.error('Error fetching users:', error);
        res.status(500).json({
            error: 'Failed to fetch users',
            message: error.message
        });
    }
});

/**
 * GET /api/users/:id
 * Retrieve a specific user by ID
 */
router.get('/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const result = await db.query(
            'SELECT id, name, email, created_at FROM users WHERE id = $1',
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'User not found' });
        }

        res.json(result.rows[0]);
    } catch (error) {
        console.error('Error fetching user:', error);
        res.status(500).json({
            error: 'Failed to fetch user',
            message: error.message
        });
    }
});

/**
 * POST /api/users
 * Create a new user
 */
router.post('/', async (req, res) => {
    try {
        const { name, email } = req.body;

        if (!name || !email) {
            return res.status(400).json({
                error: 'Validation failed',
                message: 'Name and email are required'
            });
        }

        const result = await db.query(
            'INSERT INTO users (name, email) VALUES ($1, $2) RETURNING id, name, email, created_at',
            [name, email]
        );

        res.status(201).json(result.rows[0]);
    } catch (error) {
        console.error('Error creating user:', error);

        if (error.code === '23505') { // Unique violation
            return res.status(409).json({
                error: 'User already exists',
                message: 'Email already registered'
            });
        }

        res.status(500).json({
            error: 'Failed to create user',
            message: error.message
        });
    }
});

module.exports = router;
