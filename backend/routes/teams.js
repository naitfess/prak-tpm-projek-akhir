const express = require('express');
const { 
  getAllTeams, 
  createTeam, 
  getTeamById, 
  updateTeam, 
  deleteTeam 
} = require('../controllers/teamController');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

const router = express.Router();

router.get('/', getAllTeams);
router.post('/', authenticateToken, requireAdmin, createTeam);
router.get('/:id', getTeamById);
router.put('/:id', authenticateToken, requireAdmin, updateTeam);
router.delete('/:id', authenticateToken, requireAdmin, deleteTeam);

module.exports = router;
