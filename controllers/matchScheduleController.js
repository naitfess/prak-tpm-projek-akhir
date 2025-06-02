const { MatchSchedule, Team, Prediction, User } = require('../models');
const Joi = require('joi');

// Add validation schemas
const matchScheduleUpdateSchema = Joi.object({
  team1_id: Joi.number().integer().positive().optional(),
  team2_id: Joi.number().integer().positive().optional(),
  date: Joi.date().optional(),
  time: Joi.string().pattern(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?$/).optional(), // Allow optional seconds
  skor1: Joi.number().integer().min(0).optional(),
  skor2: Joi.number().integer().min(0).optional(),
  is_finished: Joi.boolean().optional()
});

const matchCreateSchema = Joi.object({
  team1_id: Joi.number().integer().positive().required(),
  team2_id: Joi.number().integer().positive().required(),
  date: Joi.date().required(),
  time: Joi.string().pattern(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?$/).required(), // Allow optional seconds
  skor1: Joi.number().integer().min(0).default(0),
  skor2: Joi.number().integer().min(0).default(0)
});

class MatchScheduleController {
  static async getAllMatches(req, res) {
    try {
      const page = parseInt(req.query.page) || 1;
      const limit = parseInt(req.query.limit) || 10;
      const offset = (page - 1) * limit;

      const { count, rows } = await MatchSchedule.findAndCountAll({
        include: [
          { model: Team, as: 'team1', attributes: ['id', 'name'] },
          { model: Team, as: 'team2', attributes: ['id', 'name'] }
        ],
        order: [['date', 'ASC'], ['time', 'ASC']],
        limit,
        offset
      });

      // Format data untuk konsistensi
      const formattedRows = rows.map(match => ({
        ...match.toJSON(),
        date: match.date, // Pastikan format YYYY-MM-DD
        time: match.time  // Pastikan format HH:MM:SS
      }));

      res.json({
        success: true,
        data: formattedRows,
        pagination: {
          total: count,
          page,
          limit,
          totalPages: Math.ceil(count / limit)
        }
      });
    } catch (error) {
      console.error('Error getting matches:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  static async createMatch(req, res) {
    try {
      console.log('Create match request body:', req.body);

      const { error, value } = matchCreateSchema.validate(req.body);
      if (error) {
        console.log('Validation error:', error.details[0].message);
        return res.status(400).json({
          success: false,
          message: error.details[0].message
        });
      }

      // Check if teams exist and are different
      if (value.team1_id === value.team2_id) {
        return res.status(400).json({
          success: false,
          message: 'A team cannot play against itself'
        });
      }

      // Verify teams exist
      const [team1, team2] = await Promise.all([
        Team.findByPk(value.team1_id),
        Team.findByPk(value.team2_id)
      ]);

      if (!team1) {
        return res.status(404).json({
          success: false,
          message: 'Team 1 not found'
        });
      }

      if (!team2) {
        return res.status(404).json({
          success: false,
          message: 'Team 2 not found'
        });
      }

      // Format time to include seconds if not present
      let formattedTime = value.time;
      if (formattedTime && !formattedTime.includes(':00') && formattedTime.split(':').length === 2) {
        formattedTime = formattedTime + ':00';
      }

      // Create match with explicit field mapping
      const matchData = {
        team1_id: value.team1_id,
        team2_id: value.team2_id,
        date: value.date,
        time: formattedTime,
        skor1: value.skor1 || 0,
        skor2: value.skor2 || 0,
        is_finished: false
      };

      console.log('Creating match with data:', matchData);

      const match = await MatchSchedule.create(matchData);
      
      console.log('Match created successfully:', match.toJSON());

      res.status(201).json({
        success: true,
        message: 'Match schedule created successfully',
        data: match
      });
    } catch (error) {
      console.error('Error creating match:', error);
      console.error('Error stack:', error.stack);
      res.status(500).json({ 
        success: false,
        message: 'Server error', 
        error: error.message 
      });
    }
  }

  static async getMatchById(req, res) {
    try {
      const match = await MatchSchedule.findByPk(req.params.id, {
        include: [
          { model: Team, as: 'team1', attributes: ['name'] },
          { model: Team, as: 'team2', attributes: ['name'] }
        ]
      });
      
      if (!match) {
        return res.status(404).json({ message: 'Match not found' });
      }
      
      res.json(match);
    } catch (error) {
      res.status(500).json({ message: 'Server error', error: error.message });
    }
  }

  static async updateMatch(req, res) {
    try {
      const { error, value } = matchScheduleUpdateSchema.validate(req.body);
      if (error) {
        return res.status(400).json({
          success: false,
          message: error.details[0].message
        });
      }

      const match = await MatchSchedule.findByPk(req.params.id);
      
      if (!match) {
        return res.status(404).json({ 
          success: false,
          message: 'Match not found' 
        });
      }

      const oldIsFinished = match.is_finished;
      
      // Set is_finished to true when scores are explicitly updated (including 0-0)
      const updateData = { ...value };
      if ((value.hasOwnProperty('skor1') || value.hasOwnProperty('skor2')) && !match.is_finished) {
        updateData.is_finished = true;
      }
      
      await match.update(updateData);

      // Auto-update prediction statuses if match is being finished
      if (!oldIsFinished && updateData.is_finished) {
        await MatchScheduleController.updatePredictionStatusesForMatch(
          req.params.id, 
          updateData.skor1 !== undefined ? updateData.skor1 : match.skor1, 
          updateData.skor2 !== undefined ? updateData.skor2 : match.skor2, 
          match.team1_id, 
          match.team2_id
        );
      }

      res.json({ 
        success: true,
        message: 'Match updated successfully',
        data: match
      });
    } catch (error) {
      console.error('Error updating match:', error);
      res.status(500).json({ 
        success: false,
        message: 'Server error', 
        error: error.message 
      });
    }
  }

  static async deleteMatch(req, res) {
    try {
      const match = await MatchSchedule.findByPk(req.params.id);
      
      if (!match) {
        return res.status(404).json({ message: 'Match not found' });
      }
      
      await match.destroy();
      res.json({ message: 'Match deleted successfully' });
    } catch (error) {
      res.status(500).json({ message: 'Server error', error: error.message });
    }
  }

  static async updateMatchSchedule(req, res) {
    try {
      const { id } = req.params;
      const { error } = matchScheduleUpdateSchema.validate(req.body);
      
      if (error) {
        return res.status(400).json({
          success: false,
          message: error.details[0].message
        });
      }

      const matchSchedule = await MatchSchedule.findByPk(id);
      if (!matchSchedule) {
        return res.status(404).json({
          success: false,
          message: 'Match schedule not found'
        });
      }

      const oldIsFinished = matchSchedule.is_finished;
      
      // Prepare update data
      const updateData = { ...req.body };
      const { skor1, skor2 } = req.body;
      
      // Auto-set is_finished if scores are provided (including 0-0)
      if ((skor1 !== undefined || skor2 !== undefined) && !matchSchedule.is_finished) {
        updateData.is_finished = true;
      }

      await matchSchedule.update(updateData);

      // Auto-update prediction statuses if match is being finished
      if (!oldIsFinished && updateData.is_finished) {
        await MatchScheduleController.updatePredictionStatusesForMatch(
          id, 
          updateData.skor1 !== undefined ? updateData.skor1 : matchSchedule.skor1, 
          updateData.skor2 !== undefined ? updateData.skor2 : matchSchedule.skor2, 
          matchSchedule.team1_id, 
          matchSchedule.team2_id
        );
      }

      const updatedMatch = await MatchSchedule.findByPk(id, {
        include: [
          { model: Team, as: 'team1', attributes: ['id', 'name'] },
          { model: Team, as: 'team2', attributes: ['id', 'name'] }
        ]
      });

      res.json({
        success: true,
        message: 'Match schedule updated successfully',
        data: updatedMatch
      });
    } catch (error) {
      console.error('Error updating match schedule:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error'
      });
    }
  }

  // Helper method to update prediction statuses
  static async updatePredictionStatusesForMatch(matchId, skor1, skor2, team1Id, team2Id) {
    try {
      // Determine winner (0-0 is also a valid result - draw)
      let winner_team_id = null;
      let isDraw = false;
      
      if (skor1 > skor2) {
        winner_team_id = team1Id;
      } else if (skor2 > skor1) {
        winner_team_id = team2Id;
      } else {
        // skor1 === skor2 (including 0-0) = draw
        isDraw = true;
        winner_team_id = 0; // 0 represents draw
      }

      console.log('Match result:', { 
        matchId,
        skor1, 
        skor2, 
        winner_team_id, 
        isDraw,
        team1Id,
        team2Id 
      });

      // Get all predictions for this match
      const predictions = await Prediction.findAll({
        where: { match_schedule_id: matchId },
        include: [{ model: User, as: 'user' }]
      });

      console.log(`Found ${predictions.length} predictions for match ${matchId}`);

      // Update prediction statuses and user points
      for (const prediction of predictions) {
        let status = false;
        let pointsToAdd = 0;

        // Check if prediction matches result
        if (isDraw && prediction.predicted_team_id === 0) {
          // User predicted draw and it's a draw (including 0-0)
          status = true;
          pointsToAdd = 10;
          console.log(`User ${prediction.user_id} predicted draw correctly (0-0)`);
        } else if (!isDraw && prediction.predicted_team_id === winner_team_id) {
          // User predicted winning team correctly
          status = true;
          pointsToAdd = 10;
          console.log(`User ${prediction.user_id} predicted winner correctly`);
        }

        console.log('Prediction check:', {
          user_id: prediction.user_id,
          predicted_team_id: prediction.predicted_team_id,
          actual_result: isDraw ? 'draw (0-0)' : `team_${winner_team_id}_wins`,
          status,
          pointsToAdd
        });

        // Update prediction status
        await prediction.update({ status });

        // Award points if prediction was correct
        if (pointsToAdd > 0) {
          const user = await User.findByPk(prediction.user_id);
          if (user) {
            const newPoints = user.poin + pointsToAdd;
            await user.update({ poin: newPoints });
            console.log(`Updated user ${prediction.user_id} points from ${user.poin} to ${newPoints}`);
          }
        }
      }

      console.log(`Updated ${predictions.length} predictions for match ${matchId}`);
      return true;
    } catch (error) {
      console.error('Error updating prediction statuses:', error);
      return false;
    }
  }
}

module.exports = MatchScheduleController;
