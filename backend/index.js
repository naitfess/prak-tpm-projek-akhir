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
const matchScheduleRoutes = require('./routes/matchScheduleRoutes');
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
app.use('/api/matches', matchScheduleRoutes);
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

// Test database connection
async function testConnection() {
  try {
    await sequelize.authenticate();
    console.log(`✓ Database connection established successfully to ${process.env.DB_HOST}/${process.env.DB_NAME}`);
    return true;
  } catch (error) {
    console.error('✗ Unable to connect to database:', error.message);
    console.log(`Connection attempted to: ${process.env.DB_HOST}/${process.env.DB_NAME}`);
    console.log('Make sure MySQL is running and database exists');
    return false;
  }
}

// Sync database
async function syncDatabase() {
  try {
    await sequelize.sync({ alter: true });
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
    console.log('Database connection failed. Please check your .env file or MySQL server.');
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
