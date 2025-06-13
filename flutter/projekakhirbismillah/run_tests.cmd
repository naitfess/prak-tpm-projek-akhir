@echo off
echo Cleaning build files...
flutter clean

echo Getting dependencies...
flutter pub get

echo Generating mocks...
flutter pub run build_runner build --delete-conflicting-outputs

echo Running tests...
flutter test

echo Tests completed
