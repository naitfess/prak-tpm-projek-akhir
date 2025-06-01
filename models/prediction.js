'use strict';
const { DataTypes } = require('sequelize');
const { sequelize } = require('./index');

const Prediction = sequelize.define('Prediction', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  userId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'users',
      key: 'id'
    }
  },
  matchScheduleId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'match_schedules',
      key: 'id'
    }
  },
  homeTeamScore: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0
  },
  awayTeamScore: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0
  },
  points: {
    type: DataTypes.INTEGER,
    allowNull: true,
    defaultValue: 0
  },
  isCorrect: {
    type: DataTypes.BOOLEAN,
    allowNull: true,
    defaultValue: false
  }
}, {
  tableName: 'predictions',
  timestamps: true
});

// Define associations
Prediction.associate = function(models) {
  // Prediction belongs to User
  Prediction.belongsTo(models.User, {
    foreignKey: 'userId',
    as: 'user'
  });
  
  // Prediction belongs to MatchSchedule
  Prediction.belongsTo(models.MatchSchedule, {
    foreignKey: 'matchScheduleId',
    as: 'matchSchedule'
  });
};

module.exports = Prediction;
