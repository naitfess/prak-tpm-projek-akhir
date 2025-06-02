const { Team } = require('../models');

const getAllTeams = async (req, res) => {
  try {
    const teams = await Team.findAll();
    res.json(teams);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

const createTeam = async (req, res) => {
  try {
    const { name, logoUrl } = req.body;
    const team = await Team.create({ name, logoUrl });
    
    res.status(201).json({
      message: 'Team created successfully',
      data: { id: team.id }
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

const getTeamById = async (req, res) => {
  try {
    const team = await Team.findByPk(req.params.id);
    
    if (!team) {
      return res.status(404).json({ message: 'Team not found' });
    }
    
    res.json(team);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

const updateTeam = async (req, res) => {
  try {
    const { name, logoUrl } = req.body;
    const team = await Team.findByPk(req.params.id);
    
    if (!team) {
      return res.status(404).json({ message: 'Team not found' });
    }
    
    await team.update({ name, logoUrl });
    res.json({ message: 'Team updated successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

const deleteTeam = async (req, res) => {
  try {
    const team = await Team.findByPk(req.params.id);
    
    if (!team) {
      return res.status(404).json({ message: 'Team not found' });
    }
    
    await team.destroy();
    res.json({ message: 'Team deleted successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

module.exports = {
  getAllTeams,
  createTeam,
  getTeamById,
  updateTeam,
  deleteTeam
};
