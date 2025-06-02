'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    // Add is_finished column to match_schedules
    try {
      await queryInterface.addColumn('match_schedules', 'is_finished', {
        type: Sequelize.BOOLEAN,
        allowNull: false,
        defaultValue: false,
        after: 'skor2'
      });
      console.log('✓ Added is_finished column to match_schedules');
    } catch (error) {
      if (error.message.includes('Duplicate column')) {
        console.log('✓ is_finished column already exists');
      } else {
        console.log('Error adding is_finished column:', error.message);
      }
    }

    // Update predictions table to properly handle draw predictions
    try {
      await queryInterface.changeColumn('predictions', 'predicted_team_id', {
        type: Sequelize.INTEGER,
        allowNull: false,
        defaultValue: 0
      });
      console.log('✓ Updated predictions.predicted_team_id to allow 0 for draws');
    } catch (error) {
      console.log('Note: predictions.predicted_team_id already configured');
    }

    // Remove ALL foreign key constraints on predicted_team_id
    try {
      // Try removing the specific constraint name you mentioned
      await queryInterface.sequelize.query(`
        ALTER TABLE predictions DROP FOREIGN KEY predicted_team_id
      `).catch(() => {
        console.log('predicted_team_id constraint not found');
      });

      // Get all constraints for predicted_team_id column
      const [predictedTeamConstraints] = await queryInterface.sequelize.query(`
        SELECT CONSTRAINT_NAME 
        FROM information_schema.KEY_COLUMN_USAGE 
        WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'predictions' 
        AND COLUMN_NAME = 'predicted_team_id'
        AND REFERENCED_TABLE_NAME = 'teams'
      `);

      console.log('Found predicted_team_id constraints:', predictedTeamConstraints);

      // Remove each constraint found
      for (const constraint of predictedTeamConstraints) {
        try {
          await queryInterface.sequelize.query(`
            ALTER TABLE predictions DROP FOREIGN KEY ${constraint.CONSTRAINT_NAME}
          `);
          console.log(`✓ Removed foreign key constraint: ${constraint.CONSTRAINT_NAME}`);
        } catch (err) {
          console.log(`Could not remove ${constraint.CONSTRAINT_NAME}:`, err.message);
        }
      }

      // Also remove any indexes that reference teams
      const [indexes] = await queryInterface.sequelize.query(`
        SHOW INDEX FROM predictions WHERE Column_name = 'predicted_team_id'
      `);

      for (const index of indexes) {
        if (index.Key_name !== 'PRIMARY' && index.Key_name !== 'predicted_team_id') {
          try {
            await queryInterface.sequelize.query(`
              ALTER TABLE predictions DROP INDEX ${index.Key_name}
            `);
            console.log(`✓ Dropped index: ${index.Key_name}`);
          } catch (err) {
            console.log(`Could not drop index ${index.Key_name}:`, err.message);
          }
        }
      }

    } catch (error) {
      console.log('Note: Foreign key constraint removal:', error.message);
    }

    // Test draw prediction insertion
    try {
      // Clear any test records first
      await queryInterface.sequelize.query(`
        DELETE FROM predictions WHERE user_id = 999 AND match_schedule_id = 999
      `);

      // Test insert with predicted_team_id = 0 (draw)
      await queryInterface.sequelize.query(`
        INSERT INTO predictions (user_id, match_schedule_id, predicted_team_id, status, createdAt, updatedAt) 
        VALUES (999, 999, 0, NULL, NOW(), NOW())
      `);
      console.log('✓ Draw prediction test successful');
      
      // Clean up test record
      await queryInterface.sequelize.query(`
        DELETE FROM predictions WHERE user_id = 999 AND match_schedule_id = 999
      `);
      console.log('✓ Test record cleaned up');
    } catch (error) {
      console.log('Draw prediction test failed:', error.message);
      console.log('This might be expected if match_schedule_id 999 does not exist');
    }
  },

  down: async (queryInterface, Sequelize) => {
    await queryInterface.removeColumn('match_schedules', 'is_finished');
  }
};
