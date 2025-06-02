const { Prediction, User, MatchSchedule, Team } = require('../models');
const Joi = require('joi');

// Validation schemas
const predictionSchema = Joi.object({
  match_schedule_id: Joi.number().integer().positive().required(),
  predicted_team_id: Joi.number().integer().min(0).required() // Ubah dari positive() ke min(0)
});

class PredictionController {
  // Create prediction
  static async createPrediction(req, res) {
    try {
      const { match_schedule_id, predicted_team_id } = req.body;
      const user_id = req.user.id;

      console.log('Creating prediction:', {
        user_id,
        match_schedule_id,
        predicted_team_id,
        predicted_team_id_type: typeof predicted_team_id
      });

      // Validation
      if (!match_schedule_id) {
        return res.status(400).json({
          success: false,
          message: 'Match schedule ID is required'
        });
      }

      // Allow predicted_team_id to be 0 for draw, or positive integer for team selection
      if (predicted_team_id !== 0 && (!predicted_team_id || predicted_team_id < 0)) {
        return res.status(400).json({
          success: false,
          message: 'Invalid team selection'
        });
      }

      // Check if match exists and is not finished
      const match = await MatchSchedule.findByPk(match_schedule_id, {
        include: [
          { model: Team, as: 'team1' },
          { model: Team, as: 'team2' }
        ]
      });

      if (!match) {
        return res.status(404).json({
          success: false,
          message: 'Match not found'
        });
      }

      if (match.is_finished) {
        return res.status(400).json({
          success: false,
          message: 'Cannot predict on finished match'
        });
      }

      // Validate team selection (only if not draw)
      if (predicted_team_id !== 0) {
        if (predicted_team_id !== match.team1_id && predicted_team_id !== match.team2_id) {
          return res.status(400).json({
            success: false,
            message: 'Invalid team selection for this match'
          });
        }
      }

      // Check if user already made a prediction for this match
      const existingPrediction = await Prediction.findOne({
        where: {
          user_id,
          match_schedule_id
        }
      });

      if (existingPrediction) {
        // Update existing prediction
        await existingPrediction.update({
          predicted_team_id,
          status: null // Reset status since match result might change
        });

        console.log('Updated existing prediction:', existingPrediction.toJSON());

        return res.json({
          success: true,
          message: 'Prediction updated successfully',
          data: existingPrediction
        });
      }

      // Create new prediction
      const prediction = await Prediction.create({
        user_id,
        match_schedule_id,
        predicted_team_id,
        status: null
      });

      console.log('Created new prediction:', prediction.toJSON());

      res.status(201).json({
        success: true,
        message: 'Prediction created successfully',
        data: prediction
      });
    } catch (error) {
      console.error('Error creating prediction:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        debug: error.message
      });
    }
  }

  // Get user predictions
  static async getUserPredictions(req, res) {
    try {
      const user_id = req.user.id;
      const page = parseInt(req.query.page) || 1;
      const limit = parseInt(req.query.limit) || 10;
      const offset = (page - 1) * limit;

      const { count, rows } = await Prediction.findAndCountAll({
        where: { user_id },
        include: [
          { 
            model: MatchSchedule, 
            as: 'match', 
            include: [
              { model: Team, as: 'team1', attributes: ['id', 'name'] },
              { model: Team, as: 'team2', attributes: ['id', 'name'] }
            ]
          }
          // Hapus include predictedTeam karena tidak ada association
        ],
        order: [['createdAt', 'DESC']],
        limit,
        offset
      });

      res.json({
        success: true,
        data: rows,
        pagination: {
          total: count,
          page,
          limit,
          totalPages: Math.ceil(count / limit)
        }
      });
    } catch (error) {
      console.error('Error getting user predictions:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Get all predictions (admin only)
  static async getAllPredictions(req, res) {
    try {
      const page = parseInt(req.query.page) || 1;
      const limit = parseInt(req.query.limit) || 10;
      const offset = (page - 1) * limit;
      const match_id = req.query.match_id;

      const whereCondition = {};
      if (match_id) {
        whereCondition.match_schedule_id = match_id;
      }

      const { count, rows } = await Prediction.findAndCountAll({
        where: whereCondition,
        include: [
          { model: User, as: 'user', attributes: ['id', 'username'] },
          { 
            model: MatchSchedule, 
            as: 'match', 
            include: [
              { model: Team, as: 'team1', attributes: ['id', 'name'] },
              { model: Team, as: 'team2', attributes: ['id', 'name'] }
            ]
          }
          // Hapus include predictedTeam karena tidak ada association
        ],
        order: [['createdAt', 'DESC']],
        limit,
        offset
      });

      res.json({
        success: true,
        data: rows,
        pagination: {
          total: count,
          page,
          limit,
          totalPages: Math.ceil(count / limit)
        }
      });
    } catch (error) {
      console.error('Error getting all predictions:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Update prediction statuses when match ends (admin only)
  static async updatePredictionStatuses(req, res) {
    try {
      const { match_id } = req.params;

      // Get match details
      const match = await MatchSchedule.findByPk(match_id);
      if (!match) {
        return res.status(404).json({
          success: false,
          message: 'Match not found'
        });
      }

      // Check if match is finished
      if (!match.is_finished || (match.skor1 === 0 && match.skor2 === 0)) {
        return res.status(400).json({
          success: false,
          message: 'Match is not finished yet or has no score'
        });
      }

      // Determine winner
      let winner_team_id = null;
      let isDraw = false;
      
      if (match.skor1 > match.skor2) {
        winner_team_id = match.team1_id;
      } else if (match.skor2 > match.skor1) {
        winner_team_id = match.team2_id;
      } else {
        isDraw = true;
        winner_team_id = 0;
      }

      // Get all predictions for this match
      const predictions = await Prediction.findAll({
        where: { match_schedule_id: match_id },
        include: [{ model: User, as: 'user' }]
      });

      // Update prediction statuses and user points
      const updates = [];
      for (const prediction of predictions) {
        let status = false;
        let pointsToAdd = 0;

        if (isDraw && prediction.predicted_team_id === 0) {
          status = true;
          pointsToAdd = 10;
        } else if (!isDraw && prediction.predicted_team_id === winner_team_id) {
          status = true;
          pointsToAdd = 10;
        }

        await prediction.update({ status });

        if (pointsToAdd > 0) {
          const user = await User.findByPk(prediction.user_id);
          if (user) {
            const newPoints = user.poin + pointsToAdd;
            await user.update({ poin: newPoints });
          }
        }

        updates.push({
          user_id: prediction.user_id,
          username: prediction.user.username,
          predicted_team_id: prediction.predicted_team_id,
          status,
          points_awarded: pointsToAdd
        });
      }

      res.json({
        success: true,
        message: 'Prediction statuses updated successfully',
        data: {
          match_id,
          winner_team_id,
          isDraw,
          total_predictions: predictions.length,
          updates
        }
      });
    } catch (error) {
      console.error('Error updating prediction statuses:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }
}

module.exports = PredictionController;
