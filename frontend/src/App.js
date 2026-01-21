import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './App.css';

function App() {
    const [health, setHealth] = useState(null);
    const [users, setUsers] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    useEffect(() => {
        fetchHealthStatus();
        fetchUsers();
    }, []); 

    const fetchHealthStatus = async () => {
        try {
            const response = await axios.get('/api/health');
            setHealth(response.data);
        } catch (err) {
            console.error('Health check failed:', err);
            setError('Backend service unavailable');
        }
    };

    const fetchUsers = async () => {
        try {
            setLoading(true);
            const response = await axios.get('/api/users');
            setUsers(response.data);
            setError(null);
        } catch (err) {
            console.error('Failed to fetch users:', err);
            setError('Failed to load users');
        } finally {
            setLoading(false);
        }
    };

    const refreshData = () => {
        fetchHealthStatus();
        fetchUsers();
    };

    return (
        <div className="App">
            <header className="App-header">
                <div className="container">
                    <h1 className="title">🚀 EC2-Driven CI/CD Platform</h1>
                    <p className="subtitle">Production-Ready DevOps Deployment</p>

                    {/* Health Status Card */}
                    <div className="card health-card">
                        <h2>System Health</h2>
                        {health ? (
                            <div className="health-status">
                                <div className="status-item">
                                    <span className="label">Status:</span>
                                    <span className={`badge ${health.status === 'healthy' ? 'success' : 'error'}`}>
                                        {health.status}
                                    </span>
                                </div>
                                <div className="status-item">
                                    <span className="label">Database:</span>
                                    <span className={`badge ${health.database === 'connected' ? 'success' : 'error'}`}>
                                        {health.database}
                                    </span>
                                </div>
                                <div className="status-item">
                                    <span className="label">Last Check:</span>
                                    <span className="value">{new Date(health.timestamp).toLocaleString()}</span>
                                </div>
                            </div>
                        ) : (
                            <p className="loading">Checking health status...</p>
                        )}
                    </div>

                    {/* Users List Card */}
                    <div className="card users-card">
                        <div className="card-header">
                            <h2>User Directory</h2>
                            <button onClick={refreshData} className="refresh-btn">
                                🔄 Refresh
                            </button>
                        </div>

                        {loading ? (
                            <div className="loading">Loading users...</div>
                        ) : error ? (
                            <div className="error-message">{error}</div>
                        ) : (
                            <div className="users-grid">
                                {users.map((user) => (
                                    <div key={user.id} className="user-card">
                                        <div className="user-avatar">
                                            {user.name.charAt(0).toUpperCase()}
                                        </div>
                                        <div className="user-info">
                                            <h3>{user.name}</h3>
                                            <p>{user.email}</p>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        )}
                    </div>

                    {/* Deployment Info */}
                    <div className="card info-card">
                        <h3>Deployment Information</h3>
                        <div className="info-grid">
                            <div className="info-item">
                                <span className="info-label">CI Pipeline:</span>
                                <span className="info-value">GitHub Actions</span>
                            </div>
                            <div className="info-item">
                                <span className="info-label">CD Pipeline:</span>
                                <span className="info-value">Jenkins</span>
                            </div>
                            <div className="info-item">
                                <span className="info-label">Container:</span>
                                <span className="info-value">Docker</span>
                            </div>
                            <div className="info-item">
                                <span className="info-label">Infrastructure:</span>
                                <span className="info-value">AWS EC2</span>
                            </div>
                        </div>
                    </div>
                </div>
            </header>
        </div>
    );
}

export default App;
