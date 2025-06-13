import http from 'k6/http';
import { check, group, sleep } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';
import { randomItem, randomIntBetween } from 'https://jslib.k6.io/k6-utils/1.2.0/index.js';

// Custom metrics for detailed analysis
const errorRate = new Rate('error_rate');
const totalRequests = new Counter('total_requests');

// Endpoint-specific response time metrics
const authResponseTime = new Trend('auth_response_time');
const teamsResponseTime = new Trend('teams_response_time');
const matchesResponseTime = new Trend('matches_response_time');
const newsResponseTime = new Trend('news_response_time');
const leaderboardResponseTime = new Trend('leaderboard_response_time');
const predictionsResponseTime = new Trend('predictions_response_time');
const userProfileResponseTime = new Trend('user_profile_response_time');

// Base URL for API - change this to your actual API endpoint
const BASE_URL = 'https://be-trigger-alungnajib-1061342868557.us-central1.run.app/api';

// Define load test configuration
export const options = {
  scenarios: {
    // Normal load test with realistic user behavior
    normal_load: {
      executor: 'ramping-arrival-rate',
      startRate: 5,
      timeUnit: '1m',
      preAllocatedVUs: 50,
      maxVUs: 100,
      stages: [
        { target: 10, duration: '5m' },   // Gradually increase to 10 requests per minute
        { target: 20, duration: '10m' },  // Gradually increase to 20 requests per minute
        { target: 30, duration: '10m' },  // Gradually increase to 30 requests per minute
        { target: 20, duration: '5m' },   // Gradually decrease to 20 requests per minute
        { target: 10, duration: '5m' },   // Gradually decrease to 10 requests per minute
        { target: 5, duration: '5m' },    // Gradually decrease to 5 requests per minute
      ],
    },
  },
  thresholds: {
    http_req_duration: ['p(95)<3000'],    // 95% of requests should complete within 3s
    'auth_response_time': ['p(95)<2000'],  // Authentication should be faster
    'teams_response_time': ['p(95)<2000'],
    'matches_response_time': ['p(95)<2000'],
    'news_response_time': ['p(95)<3000'],
    'leaderboard_response_time': ['p(95)<2000'],
    'predictions_response_time': ['p(95)<2500'],
    'user_profile_response_time': ['p(95)<1500'],
    http_req_failed: ['rate<0.05'],       // Less than 5% of requests should fail
    'error_rate': ['rate<0.05'],          // Custom error rate threshold
  },
};

// Test credentials - replace with actual test accounts
const TEST_USERS = [
  { username: 'admin', password: 'password', type: 'admin' },
  { username: 'rijal', password: 'password', type: 'user' },
  // Add more test users as needed
];

// Helper function to get an auth token
function getAuthToken(userType = 'user') {
  // Get a user of the specified type, or any user if no matching type
  let user = TEST_USERS.find(u => u.type === userType) || randomItem(TEST_USERS);
  
  const payload = JSON.stringify({
    username: user.username,
    password: user.password,
  });
  
  const params = {
    headers: { 'Content-Type': 'application/json' },
  };
  
  const loginRes = http.post(`${BASE_URL}/auth/login`, payload, params);
  totalRequests.add(1);
  authResponseTime.add(loginRes.timings.duration);
  
  try {
    const body = JSON.parse(loginRes.body);
    if (body.token) {
      return { token: body.token, userType: user.type };
    }
  } catch (e) {
    console.log('Failed to parse login response', e);
  }
  
  return { token: null, userType: null };
}

// Define user behaviors based on user types
export default function() {
  // Randomly select a user type scenario
  const scenario = randomItem([
    { name: 'casual_user', weight: 0.6 },  // 60% casual users
    { name: 'active_user', weight: 0.3 },  // 30% active users
    { name: 'admin_user', weight: 0.1 },   // 10% admin users
  ]);
  
  const userType = scenario.name === 'admin_user' ? 'admin' : 'user';
  const { token, userType: actualUserType } = getAuthToken(userType);
  
  if (!token) {
    console.log('Login failed, skipping user scenario');
    return;
  }
  
  const authHeaders = {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`,
  };
  
  // Add a random think time between actions (simulates real user)
  sleep(randomIntBetween(1, 3));
  
  // Casual user - just browses content
  if (scenario.name === 'casual_user') {
    casualUserBehavior(authHeaders);
  }
  
  // Active user - browses content and sometimes makes predictions
  else if (scenario.name === 'active_user') {
    activeUserBehavior(authHeaders);
  }
  
  // Admin user - accesses admin functionality
  else if (scenario.name === 'admin_user' && actualUserType === 'admin') {
    adminUserBehavior(authHeaders);
  }
  else {
    // Fallback to casual user behavior if admin credentials didn't work
    casualUserBehavior(authHeaders);
  }
}

// Casual user behavior - just browsing
function casualUserBehavior(authHeaders) {
  // View teams
  group('Teams Browsing', () => {
    const teamsRes = http.get(`${BASE_URL}/teams`, { headers: authHeaders });
    totalRequests.add(1);
    teamsResponseTime.add(teamsRes.timings.duration);
    errorRate.add(teamsRes.status >= 400);
    
    check(teamsRes, {
      'Teams status is 200': (r) => r.status === 200,
      'Teams response has data': (r) => {
        try {
          const body = JSON.parse(r.body);
          return Array.isArray(body);
        } catch (e) {
          return false;
        }
      },
    });
    
    sleep(randomIntBetween(2, 5));
  });
  
  // View upcoming matches
  group('Matches Browsing', () => {
    const matchesRes = http.get(`${BASE_URL}/matches`, { headers: authHeaders });
    totalRequests.add(1);
    matchesResponseTime.add(matchesRes.timings.duration);
    errorRate.add(matchesRes.status >= 400);
    
    check(matchesRes, {
      'Matches status is 200': (r) => r.status === 200,
    });
    
    // Sometimes view a specific match detail
    if (Math.random() < 0.3) {
      try {
        const matchesData = JSON.parse(matchesRes.body);
        if (matchesData.success && matchesData.data && matchesData.data.length > 0) {
          const randomMatch = randomItem(matchesData.data);
          
          sleep(randomIntBetween(1, 3)); // User thinks before clicking
          
          const matchDetailRes = http.get(`${BASE_URL}/matches/${randomMatch.id}`, { 
            headers: authHeaders 
          });
          totalRequests.add(1);
          matchesResponseTime.add(matchDetailRes.timings.duration);
          errorRate.add(matchDetailRes.status >= 400);
        }
      } catch (e) {
        console.log('Failed to parse matches response', e);
      }
    }
    
    sleep(randomIntBetween(2, 5));
  });
  
  // View news
  group('News Browsing', () => {
    const newsRes = http.get(`${BASE_URL}/news`, { headers: authHeaders });
    totalRequests.add(1);
    newsResponseTime.add(newsRes.timings.duration);
    errorRate.add(newsRes.status >= 400);
    
    check(newsRes, {
      'News status is 200': (r) => r.status === 200,
    });
    
    sleep(randomIntBetween(3, 7)); // Reading news takes longer
  });
  
  // View leaderboard
  group('Leaderboard Browsing', () => {
    const leaderboardRes = http.get(`${BASE_URL}/leaderboard`, { headers: authHeaders });
    totalRequests.add(1);
    leaderboardResponseTime.add(leaderboardRes.timings.duration);
    errorRate.add(leaderboardRes.status >= 400);
    
    check(leaderboardRes, {
      'Leaderboard status is 200': (r) => r.status === 200,
    });
    
    sleep(randomIntBetween(1, 3));
  });
  
  // View own profile
  group('Profile Viewing', () => {
    const profileRes = http.get(`${BASE_URL}/users/profile`, { headers: authHeaders });
    totalRequests.add(1);
    userProfileResponseTime.add(profileRes.timings.duration);
    errorRate.add(profileRes.status >= 400);
    
    check(profileRes, {
      'Profile status is 200': (r) => r.status === 200,
    });
  });
}

// Active user behavior - browsing and predictions
function activeUserBehavior(authHeaders) {
  // First browse some content like a casual user
  casualUserBehavior(authHeaders);
  
  // Then make predictions (active behavior)
  group('Predictions', () => {
    // View current predictions
    const predictionsRes = http.get(`${BASE_URL}/predictions`, { headers: authHeaders });
    totalRequests.add(1);
    predictionsResponseTime.add(predictionsRes.timings.duration);
    errorRate.add(predictionsRes.status >= 400);
    
    // Make a new prediction (50% chance)
    if (Math.random() < 0.5) {
      // Get matches to find active ones
      const matchesRes = http.get(`${BASE_URL}/matches`, { headers: authHeaders });
      totalRequests.add(1);
      matchesResponseTime.add(matchesRes.timings.duration);
      
      try {
        const matchesData = JSON.parse(matchesRes.body);
        if (matchesData.success && matchesData.data && matchesData.data.length > 0) {
          // Find matches that aren't finished
          const activeMatches = matchesData.data.filter(m => !m.is_finished);
          
          if (activeMatches.length > 0) {
            // Simulate user thinking about which match to predict
            sleep(randomIntBetween(2, 5));
            
            // Select a random match
            const randomMatch = randomItem(activeMatches);
            
            // Randomly predict team1, team2, or draw (0) with different probabilities
            let predictOptions;
            if (randomMatch.team1_id && randomMatch.team2_id) {
              // 40% chance for team1, 40% chance for team2, 20% chance for draw
              const roll = Math.random();
              if (roll < 0.4) {
                predictOptions = randomMatch.team1_id;
              } else if (roll < 0.8) {
                predictOptions = randomMatch.team2_id;
              } else {
                predictOptions = 0; // Draw
              }
            } else {
              predictOptions = 0; // Default to draw if no valid team IDs
            }
            
            const predictionPayload = JSON.stringify({
              match_schedule_id: randomMatch.id,
              predicted_team_id: predictOptions
            });
            
            // Think time before submitting
            sleep(randomIntBetween(1, 3));
            
            // Submit prediction
            const predictionRes = http.post(
              `${BASE_URL}/predictions`, 
              predictionPayload, 
              { headers: authHeaders }
            );
            totalRequests.add(1);
            predictionsResponseTime.add(predictionRes.timings.duration);
            errorRate.add(predictionRes.status >= 400);
            
            check(predictionRes, {
              'Prediction creation successful': (r) => r.status >= 200 && r.status < 300,
            });
          }
        }
      } catch (e) {
        console.log('Failed to parse matches for prediction', e);
      }
    }
    
    // Check leaderboard after making prediction
    const leaderboardRes = http.get(`${BASE_URL}/leaderboard`, { headers: authHeaders });
    totalRequests.add(1);
    leaderboardResponseTime.add(leaderboardRes.timings.duration);
  });
}

// Admin user behavior - administrative tasks
function adminUserBehavior(authHeaders) {
  // View all users (admin feature)
  group('Admin - User Management', () => {
    const usersRes = http.get(`${BASE_URL}/users`, { headers: authHeaders });
    totalRequests.add(1);
    errorRate.add(usersRes.status >= 400);
    
    check(usersRes, {
      'Users list status is 200': (r) => r.status === 200,
    });
    
    sleep(randomIntBetween(2, 4));
  });
  
  // View all predictions (admin feature)
  group('Admin - Predictions Management', () => {
    const allPredictionsRes = http.get(`${BASE_URL}/predictions/all`, { headers: authHeaders });
    totalRequests.add(1);
    predictionsResponseTime.add(allPredictionsRes.timings.duration);
    errorRate.add(allPredictionsRes.status >= 400);
    
    sleep(randomIntBetween(2, 4));
  });
  
  // Occasionally update a match (20% chance)
  if (Math.random() < 0.2) {
    group('Admin - Match Management', () => {
      // Get all matches
      const matchesRes = http.get(`${BASE_URL}/matches`, { headers: authHeaders });
      totalRequests.add(1);
      matchesResponseTime.add(matchesRes.timings.duration);
      
      try {
        const matchesData = JSON.parse(matchesRes.body);
        if (matchesData.success && matchesData.data && matchesData.data.length > 0) {
          // Pick a random match to update
          const randomMatch = randomItem(matchesData.data);
          
          // Admin thinking about what to update
          sleep(randomIntBetween(3, 7));
          
          // Update match - could be score or other details
          const updatePayload = JSON.stringify({
            skor1: randomIntBetween(0, 5),
            skor2: randomIntBetween(0, 5),
            is_finished: Math.random() < 0.5 // 50% chance to mark as finished
          });
          
          const updateMatchRes = http.put(
            `${BASE_URL}/matches/${randomMatch.id}`, 
            updatePayload, 
            { headers: authHeaders }
          );
          totalRequests.add(1);
          matchesResponseTime.add(updateMatchRes.timings.duration);
          errorRate.add(updateMatchRes.status >= 400);
          
          check(updateMatchRes, {
            'Match update successful': (r) => r.status >= 200 && r.status < 300,
          });
        }
      } catch (e) {
        console.log('Failed to parse matches for admin update', e);
      }
    });
  }
  
  // Browse other sections like a normal user
  casualUserBehavior(authHeaders);
}
