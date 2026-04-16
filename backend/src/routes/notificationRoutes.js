const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');

router.get('/', notificationController.getNotifications);
router.get('/unread-count', notificationController.getUnreadCount);
router.put('/:id/read', notificationController.markRead);
router.post('/mark-all-read', notificationController.markAllRead);
router.post('/trigger-ongoing', notificationController.triggerOngoingNotifications);
router.delete('/delete-all', notificationController.deleteAll);
router.delete('/:id', notificationController.deleteNotification);

module.exports = router;
