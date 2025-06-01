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
const matchScheduleRoutes = require('./routes/matchSchedules');
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
app.use('/api/match-schedules', matchScheduleRoutes);
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

// Database connection and server start
sequelize.authenticate()
  .then(() => {
    console.log('Database connected successfully');
    
    // Force require the Prediction model if it wasn't loaded
    if (!sequelize.models.Prediction) {
      console.log('Attempting to manually load Prediction model...');
      try {
        require('./models/prediction');
        console.log('✓ Prediction model manually loaded');
      } catch (err) {
        console.error('✗ Failed to manually load Prediction model:', err.message);
      }
    }
    
    // Log all defined models
    const definedModels = Object.keys(sequelize.models);
    console.log('Defined models:', definedModels);
    
    // Expected models
    const expectedModels = ['User', 'Team', 'MatchSchedule', 'News', 'Prediction'];
    const missingModels = expectedModels.filter(model => !definedModels.includes(model));
    
    if (missingModels.length > 0) {
      console.error('Missing models:', missingModels);
      console.log('Please check if these model files exist and are properly exported');
    } else {
      console.log('✓ All expected models are loaded');
    }
    
    // Drop all tables first to avoid foreign key conflicts in development
    if (process.env.NODE_ENV !== 'production') {
      console.log('Dropping all tables in development mode...');
      return sequelize.drop();
    }
    return Promise.resolve();
  })
  .then(() => {
    // Set up associations only if all required models exist
    Object.keys(sequelize.models).forEach(modelName => {
      if (sequelize.models[modelName].associate) {
        try {
          sequelize.models[modelName].associate(sequelize.models);
          console.log(`✓ ${modelName} associations set up`);
        } catch (err) {
          console.error(`✗ Failed to set up ${modelName} associations:`, err.message);
          console.log('This might be due to missing related models');
        }
      }
    });
    
    // Sync models in correct order to handle dependencies
    const syncOptions = process.env.NODE_ENV === 'production' 
      ? { alter: true } 
      : { force: true, logging: console.log };
    
    // Sync base tables first (no foreign keys)
    console.log('Syncing base models...');
    return Promise.all([
      sequelize.models.User.sync(syncOptions),
      sequelize.models.Team.sync(syncOptions),
      sequelize.models.News.sync(syncOptions)
    ]);
  })
  .then(() => {
    // Sync models with foreign keys
    console.log('Syncing models with dependencies...');
    return sequelize.models.MatchSchedule.sync({ force: true, logging: console.log });
  })
  .then(() => {
    // Finally sync Prediction model
    if (sequelize.models.Prediction) {
      console.log('Syncing Prediction model...');
      return sequelize.models.Prediction.sync({ force: true, logging: console.log });
    }
    return Promise.resolve();
  })
  .then(() => {
    console.log('Database synchronized');
    
    // Log created tables
    return sequelize.getQueryInterface().showAllTables();
  })
  .then((tables) => {
    console.log('Created tables:', tables);
    
    // Check for all expected tables (use lowercase names to match actual table names)
    const expectedTables = ['users', 'teams', 'match_schedules', 'news', 'predictions'];
    expectedTables.forEach(table => {
      if (tables.includes(table)) {
        console.log(`✓ ${table} table created successfully`);
      } else {
        console.error(`✗ ${table} table NOT created`);
      }
    });
    
    app.listen(PORT, () => {
      console.log(`Server is running on port ${PORT}`);
      console.log(`Health check available at: http://localhost:${PORT}/api/health`);
      if (process.env.NODE_ENV !== 'production') {
        console.log(`API docs available at: http://localhost:${PORT}/api-docs`);
      }
    });
  })
  .catch(err => {
    console.error('Unable to connect to database:', err);
    process.exit(1);
  });

// Sync database
sequelize.sync({ force: false }).then(() => {
  console.log('Database synced successfully');
}).catch((error) => {
  console.error('Error syncing database:', error);
});
