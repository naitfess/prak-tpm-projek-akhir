const { MatchSchedule, Team, Prediction, User } = require('../models');

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
      const { team1_id, team2_id, date, time, skor1 = 0, skor2 = 0 } = req.body;
      const match = await MatchSchedule.create({ team1_id, team2_id, date, time, skor1, skor2 });
      
      res.status(201).json({
        message: 'Match schedule created successfully',
        data: { id: match.id }
      });
    } catch (error) {
      res.status(500).json({ message: 'Server error', error: error.message });
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
      const { skor1, skor2 } = req.body;
      const match = await MatchSchedule.findByPk(req.params.id);
      
      if (!match) {
        return res.status(404).json({ message: 'Match not found' });
      }
      
      await match.update({ skor1, skor2 });
      res.json({ message: 'Match updated successfully' });
    } catch (error) {
      res.status(500).json({ message: 'Server error', error: error.message });
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

      const oldSkor1 = matchSchedule.skor1;
      const oldSkor2 = matchSchedule.skor2;

      await matchSchedule.update(req.body);

      // Auto-update prediction statuses if match is being finished
      const { skor1, skor2 } = req.body;
      if ((skor1 || skor2) && (oldSkor1 === 0 && oldSkor2 === 0)) {
        await this.updatePredictionStatusesForMatch(id, skor1, skor2, matchSchedule.team1_id, matchSchedule.team2_id);
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
      // Determine winner
      let winner_team_id = null;
      if (skor1 > skor2) {
        winner_team_id = team1Id;
      } else if (skor2 > skor1) {
        winner_team_id = team2Id;
      }

      // Get all predictions for this match
      const predictions = await Prediction.findAll({
        where: { match_schedule_id: matchId }
      });

      // Update prediction statuses and user points
      for (const prediction of predictions) {
        let status = false;
        let pointsToAdd = 0;

        if (winner_team_id && prediction.predicted_team_id === winner_team_id) {
          status = true;
          pointsToAdd = 10;
        }

        await prediction.update({ status });

        if (pointsToAdd > 0) {
          await User.increment('poin', {
            by: pointsToAdd,
            where: { id: prediction.user_id }
          });
        }
      }

      console.log(`Updated ${predictions.length} predictions for match ${matchId}`);
    } catch (error) {
      console.error('Error updating prediction statuses:', error);
    }
  }
}

module.exports = MatchScheduleController;
