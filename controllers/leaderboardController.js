const { User, Prediction, MatchSchedule, Team } = require('../models');
const { Op } = require('sequelize');

class LeaderboardController {
  // Get top 10 users by points
  static async getLeaderboard(req, res) {
    try {
      const limit = parseInt(req.query.limit) || 10;
      
      const users = await User.findAll({
        where: {
          role: 'user' // Only include regular users, not admins
        },
        attributes: [
          'id',
          'username',
          'poin',
          'createdAt'
        ],
        order: [
          ['poin', 'DESC'],
          ['createdAt', 'ASC'] // If points are equal, earlier user wins
        ],
        limit
      });

      // Add ranking
      const leaderboard = users.map((user, index) => ({
        rank: index + 1,
        id: user.id,
        username: user.username,
        points: user.poin,
        joined_date: user.createdAt
      }));

      res.json({
        success: true,
        message: 'Leaderboard retrieved successfully',
        data: leaderboard
      });
    } catch (error) {
      console.error('Error getting leaderboard:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Get detailed leaderboard with prediction stats
  static async getDetailedLeaderboard(req, res) {
    try {
      const limit = parseInt(req.query.limit) || 10;
      
      const users = await User.findAll({
        where: {
          role: 'user'
        },
        attributes: [
          'id',
          'username',
          'poin',
          'createdAt'
        ],
        include: [{
          model: Prediction,
          as: 'predictions',
          attributes: ['status'],
          required: false
        }],
        order: [
          ['poin', 'DESC'],
          ['createdAt', 'ASC']
        ],
        limit
      });

      // Calculate prediction statistics
      const leaderboard = users.map((user, index) => {
        const predictions = user.predictions || [];
        const totalPredictions = predictions.length;
        const correctPredictions = predictions.filter(p => p.status === true).length;
        const incorrectPredictions = predictions.filter(p => p.status === false).length;
        const pendingPredictions = predictions.filter(p => p.status === null).length;
        const accuracy = totalPredictions > 0 ? Math.round((correctPredictions / (correctPredictions + incorrectPredictions)) * 100) || 0 : 0;

        return {
          rank: index + 1,
          id: user.id,
          username: user.username,
          points: user.poin,
          total_predictions: totalPredictions,
          correct_predictions: correctPredictions,
          incorrect_predictions: incorrectPredictions,
          pending_predictions: pendingPredictions,
          accuracy_percentage: accuracy,
          joined_date: user.createdAt
        };
      });

      res.json({
        success: true,
        message: 'Detailed leaderboard retrieved successfully',
        data: leaderboard
      });
    } catch (error) {
      console.error('Error getting detailed leaderboard:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Get user's position in leaderboard
  static async getUserRank(req, res) {
    try {
      const user_id = req.user.id;

      // Get user's current points
      const user = await User.findByPk(user_id, {
        attributes: ['id', 'username', 'poin', 'createdAt']
      });

      if (!user) {
        return res.status(404).json({
          success: false,
          message: 'User not found'
        });
      }

      // Count users with higher points
      const higherRankedCount = await User.count({
        where: {
          role: 'user',
          [Op.or]: [
            { poin: { [Op.gt]: user.poin } },
            {
              poin: user.poin,
              createdAt: { [Op.lt]: user.createdAt }
            }
          ]
        }
      });

      const rank = higherRankedCount + 1;

      // Get total number of users
      const totalUsers = await User.count({
        where: { role: 'user' }
      });

      // Get user's prediction stats
      const predictions = await Prediction.findAll({
        where: { user_id },
        attributes: ['status']
      });

      const totalPredictions = predictions.length;
      const correctPredictions = predictions.filter(p => p.status === true).length;
      const incorrectPredictions = predictions.filter(p => p.status === false).length;
      const pendingPredictions = predictions.filter(p => p.status === null).length;
      const accuracy = totalPredictions > 0 ? Math.round((correctPredictions / (correctPredictions + incorrectPredictions)) * 100) || 0 : 0;

      res.json({
        success: true,
        message: 'User rank retrieved successfully',
        data: {
          user: {
            id: user.id,
            username: user.username,
            points: user.poin
          },
          rank,
          total_users: totalUsers,
          prediction_stats: {
            total_predictions: totalPredictions,
            correct_predictions: correctPredictions,
            incorrect_predictions: incorrectPredictions,
            pending_predictions: pendingPredictions,
            accuracy_percentage: accuracy
          }
        }
      });
    } catch (error) {
      console.error('Error getting user rank:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }
}

module.exports = LeaderboardController;
