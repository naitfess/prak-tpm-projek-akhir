'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    try {
      // Disable foreign key checks
      await queryInterface.sequelize.query('SET FOREIGN_KEY_CHECKS = 0;');
      
      // List of known constraint names to try removing
      const possibleConstraints = [
        'predictions_ibfk_3',
        'predictions_ibfk_33',
        'fk_predictions_predicted_team',
        'predictions_predicted_team_id_foreign'
      ];

      for (const constraint of possibleConstraints) {
        try {
          await queryInterface.sequelize.query(`
            ALTER TABLE predictions DROP FOREIGN KEY ${constraint}
          `);
          console.log(`✓ Removed constraint: ${constraint}`);
        } catch (error) {
          console.log(`Constraint ${constraint} not found`);
        }
      }

      // Find any remaining constraints
      const [remainingConstraints] = await queryInterface.sequelize.query(`
        SELECT CONSTRAINT_NAME 
        FROM information_schema.KEY_COLUMN_USAGE 
        WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'predictions' 
        AND COLUMN_NAME = 'predicted_team_id'
        AND REFERENCED_TABLE_NAME = 'teams'
      `);

      // Remove any remaining constraints
      for (const constraint of remainingConstraints) {
        try {
          await queryInterface.sequelize.query(`
            ALTER TABLE predictions DROP FOREIGN KEY ${constraint.CONSTRAINT_NAME}
          `);
          console.log(`✓ Removed remaining constraint: ${constraint.CONSTRAINT_NAME}`);
        } catch (error) {
          console.log(`Could not remove ${constraint.CONSTRAINT_NAME}:`, error.message);
        }
      }

      // Re-enable foreign key checks
      await queryInterface.sequelize.query('SET FOREIGN_KEY_CHECKS = 1;');

      console.log('✓ Foreign key removal completed');
    } catch (error) {
      console.error('Migration error:', error);
      throw error;
    }
  },

  down: async (queryInterface, Sequelize) => {
    console.log('Down migration - not adding foreign key back');
  }
};
