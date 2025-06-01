const { News } = require('../models');

const getAllNews = async (req, res) => {
  try {
    const news = await News.findAll();
    res.json(news);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

const createNews = async (req, res) => {
  try {
    const { title, content, imageUrl, date } = req.body;
    const news = await News.create({ title, content, imageUrl, date });
    
    res.status(201).json({
      message: 'News created successfully',
      data: { id: news.id }
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

const getNewsById = async (req, res) => {
  try {
    const news = await News.findByPk(req.params.id);
    
    if (!news) {
      return res.status(404).json({ message: 'News not found' });
    }
    
    res.json(news);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

const updateNews = async (req, res) => {
  try {
    const { title, content, imageUrl, date } = req.body;
    const news = await News.findByPk(req.params.id);
    
    if (!news) {
      return res.status(404).json({ message: 'News not found' });
    }
    
    await news.update({ title, content, imageUrl, date });
    res.json({ message: 'News updated successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

const deleteNews = async (req, res) => {
  try {
    const news = await News.findByPk(req.params.id);
    
    if (!news) {
      return res.status(404).json({ message: 'News not found' });
    }
    
    await news.destroy();
    res.json({ message: 'News deleted successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

module.exports = {
  getAllNews,
  createNews,
  getNewsById,
  updateNews,
  deleteNews
};
