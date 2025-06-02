const { User } = require('../models');

class LeaderboardController {
  // Get top 10 users by points
  static async getLeaderboard(req, res) {
    try {
      // Get top 10 users with highest points, excluding admins
      const leaderboard = await User.findAll({
        where: {
          role: 'user' // Only include users, not admins
        },
        attributes: ['id', 'username', 'poin'],
        order: [
          ['poin', 'DESC'], // Order by points descending
          ['username', 'ASC'] // Secondary sort by username for ties
        ],
        limit: 10 // Only top 10 users
      });

      // Add ranking to each user
      const leaderboardWithRank = leaderboard.map((user, index) => ({
        rank: index + 1,
        id: user.id,
        username: user.username,
        poin: user.poin || 0
      }));

      res.json({
        success: true,
        message: 'Leaderboard retrieved successfully',
        data: leaderboardWithRank
      });
    } catch (error) {
      console.error('Error getting leaderboard:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Get user's position in leaderboard
  static async getUserRank(req, res) {
    try {
      const userId = req.user.id;

      // Get all users ordered by points (excluding admins)
      const users = await User.findAll({
        where: {
          role: 'user'
        },
        attributes: ['id', 'username', 'poin'],
        order: [
          ['poin', 'DESC'],
          ['username', 'ASC']
        ]
      });

      // Find user's rank
      const userRank = users.findIndex(user => user.id === userId) + 1;
      const userData = users.find(user => user.id === userId);

      if (!userData) {
        return res.status(404).json({
          success: false,
          message: 'User not found in leaderboard'
        });
      }

      res.json({
        success: true,
        message: 'User rank retrieved successfully',
        data: {
          rank: userRank,
          username: userData.username,
          poin: userData.poin || 0,
          totalUsers: users.length
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

  // Get leaderboard statistics
  static async getLeaderboardStats(req, res) {
    try {
      const stats = await User.findAll({
        where: {
          role: 'user'
        },
        attributes: [
          [User.sequelize.fn('COUNT', User.sequelize.col('id')), 'totalUsers'],
          [User.sequelize.fn('MAX', User.sequelize.col('poin')), 'highestScore'],
          [User.sequelize.fn('AVG', User.sequelize.col('poin')), 'averageScore'],
          [User.sequelize.fn('SUM', User.sequelize.col('poin')), 'totalPoints']
        ],
        raw: true
      });

      const topUser = await User.findOne({
        where: {
          role: 'user'
        },
        attributes: ['username', 'poin'],
        order: [['poin', 'DESC']],
        limit: 1
      });

      res.json({
        success: true,
        message: 'Leaderboard statistics retrieved successfully',
        data: {
          totalUsers: parseInt(stats[0].totalUsers) || 0,
          highestScore: parseInt(stats[0].highestScore) || 0,
          averageScore: parseFloat(stats[0].averageScore).toFixed(2) || 0,
          totalPoints: parseInt(stats[0].totalPoints) || 0,
          topUser: topUser ? {
            username: topUser.username,
            poin: topUser.poin || 0
          } : null
        }
      });
    } catch (error) {
      console.error('Error getting leaderboard stats:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }
}

module.exports = LeaderboardController;
