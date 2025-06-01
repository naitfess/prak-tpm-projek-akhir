const { sequelize } = require('../config/database');

// Import all models directly (tidak dipanggil sebagai function)
const User = require('./user');
const Team = require('./team');
const MatchSchedule = require('./matchSchedule');
const News = require('./news');
const Prediction = require('./prediction');

// Define associations
User.hasMany(Prediction, { foreignKey: 'user_id', as: 'predictions' });
Prediction.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

MatchSchedule.hasMany(Prediction, { foreignKey: 'match_schedule_id', as: 'predictions' });
Prediction.belongsTo(MatchSchedule, { foreignKey: 'match_schedule_id', as: 'match' });

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
