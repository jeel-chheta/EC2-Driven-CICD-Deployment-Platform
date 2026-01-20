# Contributing to EC2-Driven CI/CD Deployment Platform

Thank you for your interest in contributing to this project! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Commit Messages](#commit-messages)
- [Pull Request Process](#pull-request-process)

## Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inspiring community for all. Please be respectful and constructive in all interactions.

### Our Standards

- ✅ Be respectful and inclusive
- ✅ Welcome newcomers and help them learn
- ✅ Focus on what is best for the community
- ✅ Show empathy towards others

## Getting Started

### Prerequisites

- Git
- Docker and Docker Compose
- Node.js 18+ (for local development)
- Basic understanding of CI/CD concepts

### Fork and Clone

```bash
# Fork the repository on GitHub
# Then clone your fork
git clone https://github.com/your-username/ec2-cicd-platform.git
cd ec2-cicd-platform

# Add upstream remote
git remote add upstream https://github.com/original-owner/ec2-cicd-platform.git
```

### Local Setup

```bash
# Copy environment file
cp .env.example .env

# Start development environment
docker-compose up --build

# Run tests
cd backend && npm test
cd ../frontend && npm test
```

## Development Workflow

### 1. Create a Branch

```bash
# Update your main branch
git checkout main
git pull upstream main

# Create a feature branch
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-bug-fix
```

### 2. Make Changes

- Write clean, readable code
- Follow existing code style
- Add tests for new features
- Update documentation as needed

### 3. Test Your Changes

```bash
# Run all tests
cd backend && npm test
cd ../frontend && npm test

# Test Docker builds
docker build -t test-backend ./backend
docker build -t test-frontend ./frontend

# Test full deployment locally
docker-compose up --build
```

### 4. Commit Your Changes

```bash
git add .
git commit -m "feat: add new feature"
```

See [Commit Messages](#commit-messages) for format guidelines.

### 5. Push and Create Pull Request

```bash
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub.

## Coding Standards

### JavaScript/Node.js

- Use ES6+ features
- Use `const` and `let`, avoid `var`
- Use async/await over callbacks
- Handle errors properly
- Add JSDoc comments for functions

**Example:**
```javascript
/**
 * Fetch user by ID
 * @param {number} id - User ID
 * @returns {Promise<Object>} User object
 */
async function getUserById(id) {
  try {
    const result = await db.query('SELECT * FROM users WHERE id = $1', [id]);
    return result.rows[0];
  } catch (error) {
    console.error('Error fetching user:', error);
    throw error;
  }
}
```

### React

- Use functional components with hooks
- Keep components small and focused
- Use meaningful component names
- Add PropTypes or TypeScript types

**Example:**
```javascript
import React, { useState, useEffect } from 'react';

function UserList() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchUsers();
  }, []);

  const fetchUsers = async () => {
    try {
      const response = await fetch('/api/users');
      const data = await response.json();
      setUsers(data);
    } catch (error) {
      console.error('Failed to fetch users:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) return <div>Loading...</div>;

  return (
    <div>
      {users.map(user => (
        <div key={user.id}>{user.name}</div>
      ))}
    </div>
  );
}
```

### Docker

- Use multi-stage builds
- Minimize layer count
- Use specific image tags, not `latest`
- Add health checks
- Run as non-root user

**Example:**
```dockerfile
FROM node:18-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .

FROM node:18-alpine
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001
WORKDIR /app
COPY --from=build /app .
USER nodejs
EXPOSE 5000
HEALTHCHECK CMD node -e "require('http').get('http://localhost:5000/health')"
CMD ["node", "server.js"]
```

### Shell Scripts

- Use `#!/bin/bash` shebang
- Use `set -e` for error handling
- Add comments for complex logic
- Use meaningful variable names
- Add color output for readability

**Example:**
```bash
#!/bin/bash
set -e

GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}Starting deployment...${NC}"

# Deploy application
docker-compose up -d

echo -e "${GREEN}Deployment complete!${NC}"
```

## Testing Guidelines

### Backend Tests

```javascript
// tests/api.test.js
const request = require('supertest');
const app = require('../src/server');

describe('API Endpoints', () => {
  describe('GET /api/health', () => {
    it('should return health status', async () => {
      const res = await request(app).get('/api/health');
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('status');
      expect(res.body.status).toBe('healthy');
    });
  });

  describe('GET /api/users', () => {
    it('should return users array', async () => {
      const res = await request(app).get('/api/users');
      expect(res.statusCode).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
    });
  });
});
```

### Frontend Tests

```javascript
// src/App.test.js
import { render, screen } from '@testing-library/react';
import App from './App';

test('renders application title', () => {
  render(<App />);
  const titleElement = screen.getByText(/EC2-Driven CI\/CD Platform/i);
  expect(titleElement).toBeInTheDocument();
});

test('renders health status section', () => {
  render(<App />);
  const healthElement = screen.getByText(/System Health/i);
  expect(healthElement).toBeInTheDocument();
});
```

### Test Coverage

- Aim for >80% code coverage
- Test happy paths and error cases
- Test edge cases
- Mock external dependencies

## Commit Messages

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification.

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks
- `perf`: Performance improvements
- `ci`: CI/CD changes

### Examples

```bash
# Feature
git commit -m "feat(backend): add user authentication endpoint"

# Bug fix
git commit -m "fix(frontend): resolve infinite loop in useEffect"

# Documentation
git commit -m "docs: update deployment guide with SSL setup"

# Breaking change
git commit -m "feat(api)!: change user endpoint response format

BREAKING CHANGE: User endpoint now returns array instead of object"
```

## Pull Request Process

### Before Submitting

- [ ] Code follows project style guidelines
- [ ] All tests pass
- [ ] New tests added for new features
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] No merge conflicts with main branch

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Tests pass locally
- [ ] New tests added
- [ ] Manual testing completed

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
```

### Review Process

1. **Automated Checks**: CI pipeline must pass
2. **Code Review**: At least one approval required
3. **Testing**: Reviewer tests changes locally
4. **Merge**: Squash and merge to main

## Documentation

### When to Update Documentation

- Adding new features
- Changing existing functionality
- Fixing bugs that affect usage
- Improving setup process

### Documentation Files to Update

- `README.md` - For major features
- `docs/` - For detailed guides
- `CHANGELOG.md` - For all changes
- Inline comments - For complex code

## Project Structure

```
EC2-Driven-CICD-Deployment-Platform/
├── frontend/           # React application
├── backend/            # Node.js API
├── database/           # Database scripts
├── nginx/              # NGINX configs
├── jenkins/            # Jenkins configs
├── deployment/         # Deployment scripts
├── .github/workflows/  # CI pipelines
└── docs/               # Documentation
```

## Areas for Contribution

### High Priority

- [ ] SSL/TLS setup automation
- [ ] CloudWatch integration
- [ ] Automated database backups
- [ ] Performance testing

### Medium Priority

- [ ] Prometheus/Grafana monitoring
- [ ] Slack notifications
- [ ] Multi-region support
- [ ] Auto-scaling configuration

### Low Priority

- [ ] UI improvements
- [ ] Additional API endpoints
- [ ] Code optimization
- [ ] Documentation improvements

## Getting Help

- **Documentation**: Check `docs/` folder
- **Issues**: Search existing GitHub issues
- **Questions**: Open a GitHub discussion
- **Bugs**: Open a GitHub issue with details

## Recognition

Contributors will be recognized in:
- README.md contributors section
- Release notes
- CHANGELOG.md

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for contributing to the EC2-Driven CI/CD Deployment Platform!** 🚀
