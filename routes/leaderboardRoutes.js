const express = require('express');
const router = express.Router();
const LeaderboardController = require('../controllers/leaderboardController');
const { authenticateToken } = require('../middleware/auth');

// Get top 10 leaderboard (public)
router.get('/', LeaderboardController.getLeaderboard);

// Get user's rank (authenticated users only)
router.get('/my-rank', authenticateToken, LeaderboardController.getUserRank);

// Get leaderboard statistics (public)
router.get('/stats', LeaderboardController.getLeaderboardStats);

module.exports = router;
