const express = require('express');
const router = express.Router();
const MatchScheduleController = require('../controllers/matchScheduleController');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

// Get all matches (public)
router.get('/', MatchScheduleController.getAllMatches);

// Get match by ID (public)
router.get('/:id', MatchScheduleController.getMatchById);

// Create match (admin only)
router.post('/', authenticateToken, requireAdmin, MatchScheduleController.createMatch);

// Update match (admin only)
router.put('/:id', authenticateToken, requireAdmin, MatchScheduleController.updateMatch);

// Update match schedule (admin only) - for more complex updates
router.patch('/:id', authenticateToken, requireAdmin, MatchScheduleController.updateMatchSchedule);

// Delete match (admin only)
router.delete('/:id', authenticateToken, requireAdmin, MatchScheduleController.deleteMatch);

// Manually finish a match (admin only)
router.put('/:id/finish', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const { MatchSchedule } = require('../models');
    
    const match = await MatchSchedule.findByPk(id);
    if (!match) {
      return res.status(404).json({
        success: false,
        message: 'Match not found'
      });
    }

    if (match.is_finished) {
      return res.status(400).json({
        success: false,
        message: 'Match is already finished'
      });
    }
    
    await match.update({ is_finished: true });

    // Trigger prediction updates for any score (including 0-0)
    await MatchScheduleController.updatePredictionStatusesForMatch(
      id,
      match.skor1,
      match.skor2,
      match.team1_id,
      match.team2_id
    );
    
    res.json({
      success: true,
      message: 'Match marked as finished',
      data: match
    });
  } catch (error) {
    console.error('Error finishing match:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

module.exports = router;
