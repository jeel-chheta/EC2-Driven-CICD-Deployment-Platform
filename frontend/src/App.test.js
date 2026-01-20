import { render, screen } from '@testing-library/react';
import App from './App';

test('renders EC2 CI/CD Platform title', () => {
    render(<App />);
    const titleElement = screen.getByText(/EC2-Driven CI\/CD Platform/i);
    expect(titleElement).toBeInTheDocument();
});

test('renders system health section', () => {
    render(<App />);
    const healthElement = screen.getByText(/System Health/i);
    expect(healthElement).toBeInTheDocument();
});

test('renders user directory section', () => {
    render(<App />);
    const usersElement = screen.getByText(/User Directory/i);
    expect(usersElement).toBeInTheDocument();
});
