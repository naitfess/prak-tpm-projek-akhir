'use strict';
const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
  class MatchSchedule extends Model {
    static associate(models) {
      MatchSchedule.hasMany(models.Prediction, {
        foreignKey: 'match_schedule_id',
        as: 'predictions'
      });
    }
  }

  MatchSchedule.init({
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
      defaultValue: 0
    },
    skor2: {
      type: DataTypes.INTEGER,
      defaultValue: 0
    }
  }, {
    sequelize,
    modelName: 'MatchSchedule',
    tableName: 'match_schedules'
  });

  return MatchSchedule;
};
