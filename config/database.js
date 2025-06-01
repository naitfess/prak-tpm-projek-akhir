require('dotenv').config();
const { Sequelize } = require('sequelize');

const sequelize = new Sequelize('api_tpm', 'root', '', {
  host: 'localhost',
  dialect: 'mysql',
  logging: false, // Set to console.log to see SQL queries
  define: {
    timestamps: true,
    underscored: false
  }
});

module.exports = { sequelize };
