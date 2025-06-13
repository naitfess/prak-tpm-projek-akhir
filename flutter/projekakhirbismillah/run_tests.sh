#!/bin/bash

# Generate mock files
flutter pub run build_runner build --delete-conflicting-outputs

# Run all tests with coverage
flutter test --coverage

# Generate coverage report (optional, requires lcov)
# genhtml coverage/lcov.info -o coverage/html

echo "Tests completed"
