require('dotenv').config();
const { Sequelize } = require('sequelize');

const sequelize = new Sequelize(process.env.DB_NAME, process.env.DB_USER, process.env.DB_PASS, {
  host: process.env.DB_HOST,
  port: 3306,
  dialect: 'mysql',
  logging: false, 
  define: {
    timestamps: true,
    underscored: false
  }
});

module.exports = { sequelize };