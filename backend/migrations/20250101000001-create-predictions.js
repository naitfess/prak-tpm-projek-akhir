'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('predictions', {
      id: {
        allowNull: false,
        autoIncrement: true,
        primaryKey: true,
        type: Sequelize.INTEGER
      },
      user_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'users',
          key: 'id'
        },
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE'
      },
      match_schedule_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'match_schedules',
          key: 'id'
        },
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE'
      },
      predicted_team_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'teams',
          key: 'id'
        },
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE'
      },
      status: {
        type: Sequelize.BOOLEAN,
        allowNull: true,
        defaultValue: null,
        comment: 'null=pending, true=correct, false=incorrect'
      },
      createdAt: {
        allowNull: false,
        type: Sequelize.DATE
      },
      updatedAt: {
        allowNull: false,
        type: Sequelize.DATE
      }
    });

    // Add unique constraint to prevent duplicate predictions
    await queryInterface.addIndex('predictions', {
      unique: true,
      fields: ['user_id', 'match_schedule_id'],
      name: 'unique_user_match_prediction'
    });
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('predictions');
  }
};
