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
      // Debug logs for request
      console.log('==== Create Prediction Debug ====');
      console.log('Headers:', req.headers);
      console.log('Auth token:', req.headers.authorization);
      console.log('User data:', req.user);
      console.log('Request body:', req.body);

      const { error } = predictionSchema.validate(req.body);
      if (error) {
        console.log('Validation error:', error.details);
        return res.status(400).json({
          success: false,
          message: error.details[0].message,
          debug: { error: error.details }
        });
      }

      const { match_schedule_id, predicted_team_id } = req.body;
      if (!req.user || !req.user.id) {
        console.log('No user found in request');
        return res.status(401).json({
          success: false,
          message: 'Authentication required',
          debug: { user: req.user }
        });
      }

      const user_id = req.user.id;

      // Match validation with detailed logging
      const match = await MatchSchedule.findByPk(match_schedule_id);
      console.log('Match found:', match);
      
      if (!match) {
        return res.status(404).json({
          success: false,
          message: 'Match not found',
          debug: { match_schedule_id }
        });
      }

      // Additional validations with logging
      console.log('Match status:', {
        skor1: match.skor1,
        skor2: match.skor2,
        team1_id: match.team1_id,
        team2_id: match.team2_id,
        predicted_team_id
      });

      // Check if match is still upcoming (skor1 and skor2 both 0)
      console.log('Match scores:', { skor1: match.skor1, skor2: match.skor2 });
      if (match.skor1 > 0 || match.skor2 > 0) {
        return res.status(400).json({
          success: false,
          message: 'Cannot predict on finished match'
        });
      }

      // Check if predicted team is valid for this match (allow 0 for draw)
      console.log('Team validation:', { predicted_team_id, team1_id: match.team1_id, team2_id: match.team2_id });
      if (predicted_team_id !== 0 && predicted_team_id !== match.team1_id && predicted_team_id !== match.team2_id) {
        return res.status(400).json({
          success: false,
          message: 'Predicted team must be one of the teams in the match or 0 for draw'
        });
      }

      // Check if user already has prediction for this match
      const existingPrediction = await Prediction.findOne({
        where: {
          user_id,
          match_schedule_id
        }
      });

      console.log('Existing prediction:', existingPrediction ? 'Found' : 'None');
      if (existingPrediction) {
        return res.status(400).json({
          success: false,
          message: 'You have already made a prediction for this match'
        });
      }

      // Create prediction
      console.log('Creating prediction...');
      const prediction = await Prediction.create({
        user_id,
        match_schedule_id,
        predicted_team_id,
        status: null
      });

      // After successful creation
      console.log('Prediction created successfully:', {
        user_id,
        match_schedule_id,
        predicted_team_id,
        prediction_id: prediction.id
      });

      // Get prediction with associations
      const predictionWithDetails = await Prediction.findByPk(prediction.id, {
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
          // Hapus include predictedTeam karena bisa null untuk predicted_team_id = 0
        ]
      });

      console.log('Prediction with details retrieved');

      res.status(201).json({
        success: true,
        message: 'Prediction created successfully',
        data: predictionWithDetails
      });
    } catch (error) {
      console.error('Prediction creation error:', {
        message: error.message,
        stack: error.stack,
        user: req?.user?.id,
        body: req.body
      });
      
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        debug: process.env.NODE_ENV === 'development' ? error.message : undefined
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

      // Check if match is finished (has scores and updated)
      if (match.skor1 === 0 && match.skor2 === 0) {
        return res.status(400).json({
          success: false,
          message: 'Match is not finished yet'
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
        // Skor sama = seri
        isDraw = true;
        winner_team_id = 0; // 0 represents draw
      }

      console.log('Match result:', { 
        skor1: match.skor1, 
        skor2: match.skor2, 
        winner_team_id, 
        isDraw 
      });

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

        // Check if prediction matches result
        if (isDraw && prediction.predicted_team_id === 0) {
          // User predicted draw and it's a draw
          status = true;
          pointsToAdd = 10;
        } else if (!isDraw && prediction.predicted_team_id === winner_team_id) {
          // User predicted winning team correctly
          status = true;
          pointsToAdd = 10;
        }

        console.log('Prediction check:', {
          user_id: prediction.user_id,
          predicted_team_id: prediction.predicted_team_id,
          actual_result: isDraw ? 'draw' : `team_${winner_team_id}_wins`,
          status,
          pointsToAdd
        });

        await prediction.update({ status });

        if (pointsToAdd > 0) {
          await User.increment('poin', {
            by: pointsToAdd,
            where: { id: prediction.user_id }
          });
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
