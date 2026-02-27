const express = require('express');
const router = express.Router();
const messageCenterController = require('../controllers/messageCenterController');

router.get('/:playerId', messageCenterController.getPlayerMessages);

router.put('/:id/read', messageCenterController.markAsRead);

router.delete('/:id', messageCenterController.deleteMessage);

module.exports = router;
