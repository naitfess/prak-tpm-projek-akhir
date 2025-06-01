const express = require('express');
const { 
  getAllMatches, 
  createMatch, 
  getMatchById, 
  updateMatch, 
  deleteMatch 
} = require('../controllers/matchScheduleController');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

const router = express.Router();

router.get('/', getAllMatches);
router.post('/', authenticateToken, requireAdmin, createMatch);
router.get('/:id', getMatchById);
router.put('/:id', authenticateToken, requireAdmin, updateMatch);
router.delete('/:id', authenticateToken, requireAdmin, deleteMatch);

module.exports = router;
