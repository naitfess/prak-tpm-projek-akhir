router.get('/test-auth', authMiddleware, (req, res) => {
  res.json({
    success: true,
    message: 'Authentication working',
    user: req.user,
    headers: req.headers
  });
});
