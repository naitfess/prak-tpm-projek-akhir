const { sequelize } = require('../config/database');

// Import all models directly (tidak dipanggil sebagai function)
const User = require('./user');
const Team = require('./team');
const MatchSchedule = require('./matchSchedule');
const News = require('./news');
const Prediction = require('./prediction');

// Define associations but don't create foreign key for predicted_team_id
User.hasMany(Prediction, { foreignKey: 'user_id' });
Prediction.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

MatchSchedule.hasMany(Prediction, { foreignKey: 'match_schedule_id' });
Prediction.belongsTo(MatchSchedule, { foreignKey: 'match_schedule_id', as: 'match' });

// Don't create association for predicted_team_id to allow draw predictions (value = 0)
// Team.hasMany(Prediction, { foreignKey: 'predicted_team_id' }); // Remove this line
// Prediction.belongsTo(Team, { foreignKey: 'predicted_team_id', as: 'predictedTeam' }); // Remove this line

Team.hasMany(MatchSchedule, { foreignKey: 'team1_id', as: 'homeMatches' });
Team.hasMany(MatchSchedule, { foreignKey: 'team2_id', as: 'awayMatches' });
MatchSchedule.belongsTo(Team, { foreignKey: 'team1_id', as: 'team1' });
MatchSchedule.belongsTo(Team, { foreignKey: 'team2_id', as: 'team2' });

module.exports = {
  sequelize,
  User,
  Team,
  MatchSchedule,
  News,
  Prediction
};
