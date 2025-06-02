'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    // Remove the incorrect foreign key constraint
    try {
      await queryInterface.removeConstraint('predictions', 'predictions_ibfk_11');
    } catch (error) {
      console.log('Constraint predictions_ibfk_11 not found, continuing...');
    }

    // Add the correct foreign key constraint
    await queryInterface.addConstraint('predictions', {
      fields: ['match_schedule_id'],
      type: 'foreign key',
      name: 'predictions_match_schedule_fk',
      references: {
        table: 'match_schedules',
        field: 'id'
      },
      onDelete: 'CASCADE',
      onUpdate: 'CASCADE'
    });
  },

  down: async (queryInterface, Sequelize) => {
    await queryInterface.removeConstraint('predictions', 'predictions_match_schedule_fk');
  }
};
