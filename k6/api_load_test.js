import http from 'k6/http';
import { sleep, check } from 'k6';
import { Counter } from 'k6/metrics';

// Define custom metrics
const failedRequests = new Counter('failed_requests');

// Base URL from your application
const BASE_URL = 'https://be-trigger-alungnajib-1061342868557.us-central1.run.app/api';

// Test configuration
export const options = {
  stages: [
    { duration: '30s', target: 10 }, // Ramp up to 10 users over 30 seconds
    { duration: '1m', target: 10 },  // Stay at 10 users for 1 minute
    { duration: '30s', target: 20 }, // Ramp up to 20 users over 30 seconds
    { duration: '1m', target: 20 },  // Stay at 20 users for 1 minute
    { duration: '30s', target: 0 },  // Ramp down to 0 users
  ],
  thresholds: {
    http_req_duration: ['p(95)<1000'], // 95% of requests should be below 1s
    failed_requests: ['count<10'],     // Less than 10 failed requests
  },
};

// Sample test data
const testUser = {
  username: `user_${Math.floor(Math.random() * 10000)}`,
  password: 'testpassword123'
};

let authToken = null;

// Main test function
export default function() {
  // 1. Health Check
  let healthResponse = http.get(`${BASE_URL}/health`);
  check(healthResponse, {
    'health check status is 200': (r) => r.status === 200,
  }) || failedRequests.add(1);
  
  sleep(1);

  // 2. Register (if needed)
  if (Math.random() < 0.1) { // Only register in 10% of iterations
    let registerResponse = http.post(`${BASE_URL}/auth/register`, JSON.stringify({
      username: testUser.username,
      password: testUser.password,
      role: 'user'
    }), {
      headers: { 'Content-Type': 'application/json' }
    });
    
    check(registerResponse, {
      'register successful': (r) => r.status === 201,
    }) || failedRequests.add(1);
    
    sleep(1);
  }

  // 3. Login
  let loginResponse = http.post(`${BASE_URL}/auth/login`, JSON.stringify({
    username: testUser.username,
    password: testUser.password
  }), {
    headers: { 'Content-Type': 'application/json' }
  });
  
  check(loginResponse, {
    'login successful': (r) => r.status === 200,
    'login has token': (r) => JSON.parse(r.body).token !== undefined,
  }) || failedRequests.add(1);
  
  // Extract token from login response
  try {
    const loginData = JSON.parse(loginResponse.body);
    if (loginData.token) {
      authToken = loginData.token;
    }
  } catch (e) {
    console.log('Failed to parse login response', e);
  }
  
  sleep(1);

  // 4. Get Teams
  let teamsResponse = http.get(`${BASE_URL}/teams`, {
    headers: {
      'Content-Type': 'application/json',
      'Authorization': authToken ? `Bearer ${authToken}` : ''
    }
  });
  
  check(teamsResponse, {
    'get teams successful': (r) => r.status === 200,
  }) || failedRequests.add(1);
  
  sleep(1);

  // 5. Get Matches
  let matchesResponse = http.get(`${BASE_URL}/matches`, {
    headers: {
      'Content-Type': 'application/json',
      'Authorization': authToken ? `Bearer ${authToken}` : ''
    }
  });
  
  check(matchesResponse, {
    'get matches successful': (r) => r.status === 200,
  }) || failedRequests.add(1);
  
  sleep(1);

  // 6. Get News
  let newsResponse = http.get(`${BASE_URL}/news`, {
    headers: {
      'Content-Type': 'application/json',
      'Authorization': authToken ? `Bearer ${authToken}` : ''
    }
  });
  
  check(newsResponse, {
    'get news successful': (r) => r.status === 200,
  }) || failedRequests.add(1);
  
  sleep(1);

  // 7. Get Leaderboard
  let leaderboardResponse = http.get(`${BASE_URL}/leaderboard`, {
    headers: {
      'Content-Type': 'application/json',
      'Authorization': authToken ? `Bearer ${authToken}` : ''
    }
  });
  
  check(leaderboardResponse, {
    'get leaderboard successful': (r) => r.status === 200,
  }) || failedRequests.add(1);
  
  sleep(1);
}
