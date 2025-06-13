import http from 'k6/http';
import { check, group, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';
import { SharedArray } from 'k6/data';
import { randomItem } from 'https://jslib.k6.io/k6-utils/1.2.0/index.js';

// Custom metrics
const errorRate = new Rate('error_rate');
const apiResponseTime = new Trend('api_response_time');

// Base URL for API
const BASE_URL = 'https://be-trigger-alungnajib-1061342868557.us-central1.run.app/api';

// Define test configuration
export const options = {
  scenarios: {
    // Health check - simple test with constant load
    health_check: {
      executor: 'constant-vus',
      vus: 10,
      duration: '30s',
      exec: 'healthCheckTest',
      tags: { test_type: 'health' },
    },
    
    // Main API load test - ramping pattern
    api_load_test: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '20s', target: 20 },  // Ramp up to 20 users
        { duration: '30s', target: 20 },  // Stay at 20 users
        { duration: '20s', target: 50 },  // Ramp up to 50 users
        { duration: '1m', target: 50 },   // Stay at 50 users
        { duration: '20s', target: 0 },   // Ramp down to 0 users
      ],
      exec: 'apiTest',
      tags: { test_type: 'api' },
    },
    
    // Spike test - sudden increase in users
    spike_test: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '10s', target: 10 },   // Warm up
        { duration: '10s', target: 100 },  // Spike
        { duration: '30s', target: 100 },  // Maintain spike
        { duration: '10s', target: 0 },    // Scale down
      ],
      exec: 'apiTest',
      tags: { test_type: 'spike' },
    },
  },
  thresholds: {
    http_req_duration: ['p(95)<2000'], // 95% of requests should complete within 2s
    http_req_failed: ['rate<0.1'],     // Less than 10% of requests should fail
    'error_rate': ['rate<0.1'],        // Custom error rate threshold
  },
};

// Test credentials - for testing purposes only
const TEST_USERS = [
  { username: 'testuser1', password: 'password123' },
  { username: 'testuser2', password: 'password123' },
  // Add more test users as needed
];

// Helper function to get an auth token
function getAuthToken() {
  const user = randomItem(TEST_USERS);
  const payload = JSON.stringify({
    username: user.username,
    password: user.password,
  });
  
  const params = {
    headers: { 'Content-Type': 'application/json' },
  };
  
  const loginRes = http.post(`${BASE_URL}/auth/login`, payload, params);
  
  try {
    const body = JSON.parse(loginRes.body);
    if (body.success && body.token) {
      return body.token;
    }
  } catch (e) {
    console.log('Failed to parse login response', e);
  }
  
  return null;
}

// Health check test
export function healthCheckTest() {
  const response = http.get(`${BASE_URL}/health`);
  
  // Record metrics
  apiResponseTime.add(response.timings.duration);
  errorRate.add(response.status !== 200);
  
  // Verify response
  check(response, {
    'Health check status is 200': (r) => r.status === 200,
    'Health check response has success field': (r) => {
      try {
        const body = JSON.parse(r.body);
        return body.success === true;
      } catch (e) {
        return false;
      }
    },
  });
  
  sleep(1);
}

// Main API test
export function apiTest() {
  let token = null;
  
  group('Authentication', () => {
    // Login test
    const loginPayload = JSON.stringify({
      username: randomItem(TEST_USERS).username,
      password: randomItem(TEST_USERS).password,
    });
    
    const loginParams = {
      headers: { 'Content-Type': 'application/json' },
    };
    
    const loginRes = http.post(`${BASE_URL}/auth/login`, loginPayload, loginParams);
    
    check(loginRes, {
      'Login status is 200': (r) => r.status === 200,
      'Login has token': (r) => {
        try {
          const body = JSON.parse(r.body);
          token = body.token;
          return body.success === true && body.token !== undefined;
        } catch (e) {
          return false;
        }
      },
    });
    
    apiResponseTime.add(loginRes.timings.duration);
    errorRate.add(loginRes.status !== 200);
  });
  
  // Skip remaining tests if login failed
  if (!token) {
    console.log('Login failed, skipping remaining tests');
    return;
  }
  
  const authHeaders = {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`,
  };
  
  group('Teams API', () => {
    const teamsRes = http.get(`${BASE_URL}/teams`, { headers: authHeaders });
    
    check(teamsRes, {
      'Teams status is 200': (r) => r.status === 200,
      'Teams response has data': (r) => {
        try {
          const body = JSON.parse(r.body);
          return Array.isArray(body.data);
        } catch (e) {
          return false;
        }
      },
    });
    
    apiResponseTime.add(teamsRes.timings.duration);
    errorRate.add(teamsRes.status !== 200);
    
    sleep(0.5);
  });
  
  group('Matches API', () => {
    const matchesRes = http.get(`${BASE_URL}/matches`, { headers: authHeaders });
    
    check(matchesRes, {
      'Matches status is 200': (r) => r.status === 200,
    });
    
    apiResponseTime.add(matchesRes.timings.duration);
    errorRate.add(matchesRes.status !== 200);
    
    sleep(0.5);
  });
  
  group('News API', () => {
    const newsRes = http.get(`${BASE_URL}/news`, { headers: authHeaders });
    
    check(newsRes, {
      'News status is 200': (r) => r.status === 200,
    });
    
    apiResponseTime.add(newsRes.timings.duration);
    errorRate.add(newsRes.status !== 200);
    
    sleep(0.5);
  });
  
  group('Leaderboard API', () => {
    const leaderboardRes = http.get(`${BASE_URL}/leaderboard`, { headers: authHeaders });
    
    check(leaderboardRes, {
      'Leaderboard status is 200': (r) => r.status === 200,
    });
    
    apiResponseTime.add(leaderboardRes.timings.duration);
    errorRate.add(leaderboardRes.status !== 200);
    
    sleep(0.5);
  });
  
  // Add small random sleep to avoid thundering herd
  sleep(Math.random() * 2);
}
