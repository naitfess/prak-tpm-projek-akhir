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

module.exports = router;
