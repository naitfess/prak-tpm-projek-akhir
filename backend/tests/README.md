# API Testing with K6

This folder contains test scripts for the backend API using [K6](https://k6.io/), a modern load testing tool.

## Prerequisites

1. Install K6: https://k6.io/docs/getting-started/installation/

## Test Types

### Stress Test

The stress test (`stress_test.js`) is designed to test the system's resilience under extreme conditions:
- Rapidly increasing user load
- Sudden spikes in traffic
- Testing system limits and breaking points

### Load Test

The load test (`load_test.js`) simulates realistic user behavior under expected load:
- Gradual, sustained traffic patterns
- Different user behavior profiles (casual, active, admin)
- Realistic think times between actions
- Longer duration to test stability over time

## Running the Tests

To run the tests:

```bash
# Navigate to the tests directory
cd backend/tests

# Run stress test
k6 run stress_test.js

# Run load test
k6 run load_test.js

# Run specific test scenario
k6 run --tag test_type=health stress_test.js
```

## Test Scenarios

### Stress Test Scenarios

1. **Health Check Test**: Constant load of 10 virtual users for 30 seconds
2. **API Load Test**: Ramping pattern from 0 to 50 users and back down
3. **Spike Test**: Sudden spike to 100 users to test how the system handles peak loads

### Load Test Scenarios

1. **Normal Load**: Realistic traffic pattern over an extended period (40 minutes)
2. **User Behaviors**:
   - Casual users (60%): Browse content only
   - Active users (30%): Browse content and make predictions
   - Admin users (10%): Perform administrative tasks

## Thresholds

The tests include various performance thresholds:
- Response time limits for different endpoints
- Error rate thresholds
- Request failure rates

## Customizing Tests

Before running the tests:

1. Update the `BASE_URL` constant to point to your API
2. Create actual test users or update the `TEST_USERS` array with valid credentials
3. Adjust the test durations and user counts based on your expected traffic

## Interpreting Results

K6 provides detailed metrics after each test run:
- Request rates and response times by endpoint
- Error rates and failure points
- Performance against defined thresholds
- Resource utilization patterns
