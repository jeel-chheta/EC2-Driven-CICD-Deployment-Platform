const request = require('supertest');
const app = require('../src/server');

describe('API Endpoints', () => {
    describe('GET /', () => {
        it('should return API information', async () => {
            const res = await request(app).get('/');
            expect(res.statusCode).toBe(200);
            expect(res.body).toHaveProperty('message');
            expect(res.body).toHaveProperty('version');
        });
    });

    describe('GET /api/health', () => {
        it('should return health status', async () => {
            const res = await request(app).get('/api/health');
            expect(res.statusCode).toBe(200);
            expect(res.body).toHaveProperty('status');
        });
    });

    describe('GET /api/users', () => {
        it('should return users array', async () => {
            const res = await request(app).get('/api/users');
            expect(res.statusCode).toBe(200);
            expect(Array.isArray(res.body)).toBe(true);
        });
    });

    describe('404 Handler', () => {
        it('should return 404 for unknown routes', async () => {
            const res = await request(app).get('/api/unknown');
            expect(res.statusCode).toBe(404);
            expect(res.body).toHaveProperty('error');
        });
    });
});
