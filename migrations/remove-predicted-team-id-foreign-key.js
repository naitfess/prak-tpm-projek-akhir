'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    try {
      // Find all foreign key constraints for predicted_team_id
      const [constraints] = await queryInterface.sequelize.query(`
        SELECT CONSTRAINT_NAME 
        FROM information_schema.KEY_COLUMN_USAGE 
        WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'predictions' 
        AND COLUMN_NAME = 'predicted_team_id'
        AND REFERENCED_TABLE_NAME = 'teams'
      `);

      console.log('Found constraints to remove:', constraints);

      // Remove each constraint
      for (const constraint of constraints) {
        try {
          await queryInterface.sequelize.query(`
            ALTER TABLE predictions DROP FOREIGN KEY ${constraint.CONSTRAINT_NAME}
          `);
          console.log(`✓ Removed constraint: ${constraint.CONSTRAINT_NAME}`);
        } catch (error) {
          console.log(`Could not remove ${constraint.CONSTRAINT_NAME}:`, error.message);
        }
      }

      // Try to remove the specific one mentioned in error
      try {
        await queryInterface.sequelize.query(`
          ALTER TABLE predictions DROP FOREIGN KEY predictions_ibfk_3
        `);
        console.log('✓ Removed predictions_ibfk_3');
      } catch (error) {
        console.log('predictions_ibfk_3 not found or already removed');
      }

    } catch (error) {
      console.log('Migration error:', error.message);
    }
  },

  down: async (queryInterface, Sequelize) => {
    // We don't want to add the constraint back
    console.log('Down migration - not adding foreign key back');
  }
};
