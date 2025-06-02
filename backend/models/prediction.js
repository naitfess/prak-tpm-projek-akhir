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
      model: 'users', // Make sure this matches your users table name
      key: 'id'
    }
  },
  match_schedule_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'match_schedules', // Fix: was probably 'matchschedules'
      key: 'id'
    }
  },
  predicted_team_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0, // Allow 0 for draw, positive integers for team IDs
    validate: {
      min: 0
    }
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
