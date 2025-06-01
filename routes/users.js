const express = require('express');
const { 
  getAllUsers, 
  createUser, 
  getUserById, 
  updateUser, 
  deleteUser 
} = require('../controllers/userController');
const { authenticateToken, requireAdmin, requireOwnerOrAdmin } = require('../middleware/auth');

const router = express.Router();

router.get('/', authenticateToken, requireAdmin, getAllUsers);
router.post('/', authenticateToken, requireAdmin, createUser);
router.get('/:id', authenticateToken, requireOwnerOrAdmin, getUserById);
router.put('/:id', authenticateToken, requireOwnerOrAdmin, updateUser);
router.delete('/:id', authenticateToken, requireAdmin, deleteUser);

module.exports = router;
