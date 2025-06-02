'use strict';
const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const MatchSchedule = sequelize.define('MatchSchedule', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  team1_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'teams',
      key: 'id'
    }
  },
  team2_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'teams',
      key: 'id'
    }
  },
  date: {
    type: DataTypes.DATEONLY,
    allowNull: false
  },
  time: {
    type: DataTypes.TIME,
    allowNull: false
  },
  skor1: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0
  },
  skor2: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0
  },
  is_finished: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: false
  }
}, {
  tableName: 'match_schedules',
  timestamps: true
});

module.exports = MatchSchedule;
