require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { sequelize } = require('./models');

// Import all models explicitly with error handling
const models = {};
const modelFiles = ['user', 'team', 'matchSchedule', 'news', 'prediction'];

modelFiles.forEach(modelFile => {
  try {
    const model = require(`./models/${modelFile}`);
    const modelName = modelFile.charAt(0).toUpperCase() + modelFile.slice(1);
    models[modelName] = model;
    console.log(`✓ ${modelName} model loaded`);
  } catch (err) {
    console.error(`✗ ${modelFile} model failed to load:`, err.message);
  }
});

// Import routes
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const teamRoutes = require('./routes/teams');
const matchScheduleRoutes = require('./routes/matchScheduleRoutes'); // Fixed: was './routes/matchSchedules'
const newsRoutes = require('./routes/news');
const predictionRoutes = require('./routes/predictionRoutes');
const leaderboardRoutes = require('./routes/leaderboardRoutes');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Try to load Swagger documentation (optional)
try {
  const swaggerUi = require('swagger-ui-express');
  const YAML = require('yamljs');
  const swaggerDocument = YAML.load('./swagger.yaml');
  app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));
  console.log('Swagger documentation available at /api-docs');
} catch (error) {
  console.log('Swagger documentation not available (missing dependencies)');
}

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ message: 'API is running successfully!' });
});

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/teams', teamRoutes);
app.use('/api/matches', matchScheduleRoutes); // Changed from /api/match-schedules to /api/matches
app.use('/api/news', newsRoutes);
app.use('/api/predictions', predictionRoutes);
app.use('/api/leaderboard', leaderboardRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ message: 'Something went wrong!' });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ message: 'Route not found' });
});

// Alternative database configuration
const createAlternativeSequelize = () => {
  // Using in-memory SQLite as fallback
  const { Sequelize } = require('sequelize');
  return new Sequelize('sqlite::memory:', {
    dialect: 'sqlite',
    dialectModule: require('better-sqlite3'),
    logging: false,
  });
};

// Test database connection
async function testConnection() {
  try {
    await sequelize.authenticate();
    console.log('✓ MySQL database connection established successfully.');
    return true;
  } catch (error) {
    console.error('✗ Unable to connect to MySQL database:', error.message);
    console.log('Make sure MySQL is running and database "api_tpm" exists');
    return false;
  }
}

// Sync database
async function syncDatabase() {
  try {
    // Disable foreign key checks untuk MySQL
    await sequelize.query('SET FOREIGN_KEY_CHECKS = 0;');
    
    // First, let's check if the table exists and what columns it has
    try {
      const [results] = await sequelize.query(`
        DESCRIBE match_schedules
      `);
      console.log('Current match_schedules table structure:', results);
      
      // Check if is_finished column exists
      const hasIsFinished = results.some(column => column.Field === 'is_finished');
      
      if (!hasIsFinished) {
        await sequelize.query(`
          ALTER TABLE match_schedules 
          ADD COLUMN is_finished BOOLEAN NOT NULL DEFAULT FALSE
        `);
        console.log('✓ Added is_finished column to match_schedules table');
      } else {
        console.log('✓ is_finished column already exists');
      }
    } catch (error) {
      console.log('Error checking/adding is_finished column:', error.message);
    }

    // Fix foreign key constraints for predictions table
    try {
      // Drop existing foreign key constraints that might be wrong
      await sequelize.query(`
        SELECT CONSTRAINT_NAME 
        FROM information_schema.KEY_COLUMN_USAGE 
        WHERE TABLE_SCHEMA = 'api_tpm' 
        AND TABLE_NAME = 'predictions' 
        AND REFERENCED_TABLE_NAME LIKE '%match%'
      `).then(async ([constraints]) => {
        for (const constraint of constraints) {
          try {
            await sequelize.query(`
              ALTER TABLE predictions DROP FOREIGN KEY ${constraint.CONSTRAINT_NAME}
            `);
            console.log(`✓ Dropped foreign key constraint: ${constraint.CONSTRAINT_NAME}`);
          } catch (err) {
            console.log(`Note: Could not drop constraint ${constraint.CONSTRAINT_NAME}:`, err.message);
          }
        }
      });

      // Add correct foreign key constraint
      await sequelize.query(`
        ALTER TABLE predictions 
        ADD CONSTRAINT predictions_match_schedule_fk 
        FOREIGN KEY (match_schedule_id) 
        REFERENCES match_schedules(id) 
        ON DELETE CASCADE ON UPDATE CASCADE
      `);
      console.log('✓ Added correct foreign key constraint for predictions');
    } catch (error) {
      console.log('Note: Foreign key constraint already exists or error:', error.message);
    }

    // Remove foreign key constraint on predicted_team_id to allow draw predictions (value = 0)
    try {
      // Force remove the specific constraint with the correct name
      await sequelize.query(`
        ALTER TABLE predictions DROP FOREIGN KEY predicted_team_id
      `).catch(() => {
        console.log('predicted_team_id constraint already removed or does not exist');
      });

      // Also try common variations
      const constraintsToTry = [
        'predicted_team_id',
        'predictions_predicted_team_id_foreign',
        'fk_predictions_predicted_team_id'
      ];

      for (const constraintName of constraintsToTry) {
        await sequelize.query(`
          ALTER TABLE predictions DROP FOREIGN KEY ${constraintName}
        `).catch(() => {
          console.log(`${constraintName} constraint not found`);
        });
      }

      // Check if constraint still exists and force remove it
      const [checkConstraints] = await sequelize.query(`
        SELECT CONSTRAINT_NAME 
        FROM information_schema.KEY_COLUMN_USAGE 
        WHERE TABLE_SCHEMA = 'api_tpm' 
        AND TABLE_NAME = 'predictions' 
        AND COLUMN_NAME = 'predicted_team_id'
        AND REFERENCED_TABLE_NAME = 'teams'
      `);

      console.log('Current predicted_team_id constraints:', checkConstraints);

      for (const constraint of checkConstraints) {
        await sequelize.query(`
          ALTER TABLE predictions DROP FOREIGN KEY ${constraint.CONSTRAINT_NAME}
        `).catch(err => {
          console.log(`Could not remove ${constraint.CONSTRAINT_NAME}:`, err.message);
        });
      }

      // Test if draw prediction works now
      try {
        await sequelize.query(`
          INSERT INTO predictions (user_id, match_schedule_id, predicted_team_id, status, createdAt, updatedAt) 
          VALUES (999, 1, 0, NULL, NOW(), NOW())
        `);
        console.log('✓ Draw prediction test successful');
        
        await sequelize.query(`
          DELETE FROM predictions WHERE user_id = 999 AND predicted_team_id = 0
        `);
        console.log('✓ Test record cleaned up');
      } catch (testError) {
        console.log('Draw prediction test failed:', testError.message);
      }

      console.log('✓ Completed foreign key constraint removal for predicted_team_id');
    } catch (error) {
      console.log('Note: predicted_team_id constraint handling:', error.message);
    }
    
    // Sync database with alter option to update existing tables
    await sequelize.sync({ alter: true });
    
    // Re-enable foreign key checks
    await sequelize.query('SET FOREIGN_KEY_CHECKS = 1;');
    
    console.log('✓ Database synced successfully');
    return true;
  } catch (error) {
    console.error('✗ Error syncing database:', error.message);
    return false;
  }
}

// Initialize database
async function initializeDatabase() {
  const connected = await testConnection();
  if (!connected) {
    console.log('Retrying with alternative database configuration...');
    return false;
  }
  
  const synced = await syncDatabase();
  return synced;
}

// Start server
async function startServer() {
  const dbReady = await initializeDatabase();
  
  if (!dbReady) {
    console.error('Failed to initialize database. Exiting...');
    process.exit(1);
  }
  
  app.listen(PORT, () => {
    console.log(`✓ Server running on port ${PORT}`);
    console.log(`✓ API Documentation: http://localhost:${PORT}/api-docs`);
  });
}

startServer();
