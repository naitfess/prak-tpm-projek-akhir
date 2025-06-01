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
    
    // Hanya sync normal, tidak drop table lagi
    await sequelize.sync({ force: false });
    
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
