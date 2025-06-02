const express = require('express');
const router = express.Router();
const PredictionController = require('../controllers/predictionController');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

// Create prediction (user only)
router.post('/', authenticateToken, PredictionController.createPrediction);

// Get user's own predictions
router.get('/', authenticateToken, PredictionController.getUserPredictions);

// Get all predictions (admin only)
router.get('/all', authenticateToken, requireAdmin, PredictionController.getAllPredictions);

// Update prediction statuses when match ends (admin only)
router.put('/update-status/:match_id', authenticateToken, requireAdmin, PredictionController.updatePredictionStatuses);

// Manual trigger to update all finished matches (admin only) - for testing
router.post('/update-all-finished', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const { MatchSchedule } = require('../models');
    const MatchScheduleController = require('../controllers/matchScheduleController');
    
    // Get all finished matches (including those with 0-0 scores)
    const finishedMatches = await MatchSchedule.findAll({
      where: {
        is_finished: true
      }
    });

    const results = [];
    for (const match of finishedMatches) {
      // Process all finished matches regardless of score (including 0-0)
      const success = await MatchScheduleController.updatePredictionStatusesForMatch(
        match.id,
        match.skor1,
        match.skor2,
        match.team1_id,
        match.team2_id
      );
      results.push({
        match_id: match.id,
        score: `${match.skor1}-${match.skor2}`,
        success
      });
    }

    res.json({
      success: true,
      message: 'Updated predictions for all finished matches',
      data: results
    });
  } catch (error) {
    console.error('Error updating all finished matches:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

module.exports = router;
