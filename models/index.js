const { Sequelize, DataTypes } = require('sequelize');
const config = require('../config/database')[process.env.NODE_ENV || 'development'];

const sequelize = new Sequelize(config.database, config.username, config.password, config);

const db = {};

// Import models
db.User = require('./user')(sequelize, DataTypes);
db.Team = require('./team')(sequelize, DataTypes);
db.MatchSchedule = require('./matchSchedule')(sequelize, DataTypes);
db.News = require('./news')(sequelize, DataTypes);

// Define associations
db.MatchSchedule.belongsTo(db.Team, { foreignKey: 'team1_id', as: 'team1' });
db.MatchSchedule.belongsTo(db.Team, { foreignKey: 'team2_id', as: 'team2' });

db.sequelize = sequelize;
db.Sequelize = Sequelize;

module.exports = db;
