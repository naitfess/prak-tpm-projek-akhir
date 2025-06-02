const express = require('express');
const { 
  getAllNews, 
  createNews, 
  getNewsById, 
  updateNews, 
  deleteNews 
} = require('../controllers/newsController');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

const router = express.Router();

router.get('/', getAllNews);
router.post('/', authenticateToken, requireAdmin, createNews);
router.get('/:id', getNewsById);
router.put('/:id', authenticateToken, requireAdmin, updateNews);
router.delete('/:id', authenticateToken, requireAdmin, deleteNews);

module.exports = router;
