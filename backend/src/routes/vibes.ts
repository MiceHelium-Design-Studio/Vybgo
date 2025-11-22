import express from 'express';

const router = express.Router();

// Get all available vibes
router.get('/', (req, res) => {
  const vibes = [
    {
      id: 'CHILL',
      name: 'Chill',
      description: 'Relaxed vibes for a smooth ride',
      color: '#4A90E2',
    },
    {
      id: 'PARTY',
      name: 'Party',
      description: 'High energy beats to keep the party going',
      color: '#E24A90',
    },
    {
      id: 'FOCUS',
      name: 'Focus',
      description: 'Productive sounds for your journey',
      color: '#90E24A',
    },
    {
      id: 'ROMANTIC',
      name: 'Romantic',
      description: 'Intimate atmosphere for two',
      color: '#E24A4A',
    },
  ];

  res.json(vibes);
});

export default router;



