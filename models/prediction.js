'use strict';
const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database'); // Destructure sequelize from config

const Prediction = sequelize.define('Prediction', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  user_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'Users',
      key: 'id'
    }
  },
  match_schedule_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'MatchSchedules',
      key: 'id'
    }
  },
  predicted_team_id: {
    type: DataTypes.INTEGER,
    allowNull: false
    // Hapus references constraint untuk allow 0 (draw prediction)
  },
  status: {
    type: DataTypes.BOOLEAN,
    allowNull: true,
    defaultValue: null
  }
}, {
  tableName: 'predictions',
  timestamps: true
});

module.exports = Prediction;
