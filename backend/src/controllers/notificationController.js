const notificationModel = require('../models/notificationModel');

async function getNotifications(req, res) {
  try {
    const { playerId } = req.query;
    if (!playerId) {
      return res.status(400).json({ ok: false, message: 'playerId is required' });
    }
    const notifications = await notificationModel.getNotificationsByUserId(playerId);
    res.json({ ok: true, data: notifications });
  } catch (error) {
    res.status(500).json({ ok: false, message: error.message });
  }
}

async function getUnreadCount(req, res) {
  try {
    const { playerId } = req.query;
    if (!playerId) {
      return res.status(400).json({ ok: false, message: 'playerId is required' });
    }
    const count = await notificationModel.getUnreadCount(playerId);
    res.json({ ok: true, data: { count } });
  } catch (error) {
    res.status(500).json({ ok: false, message: error.message });
  }
}

async function markRead(req, res) {
  try {
    const { id } = req.params;
    const success = await notificationModel.markAsRead(id);
    if (!success) {
      return res.status(404).json({ ok: false, message: 'Notification not found' });
    }
    res.json({ ok: true, message: 'Notification marked as read' });
  } catch (error) {
    res.status(500).json({ ok: false, message: error.message });
  }
}

async function markAllRead(req, res) {
  try {
    const { playerId } = req.body;
    if (!playerId) {
      return res.status(400).json({ ok: false, message: 'playerId is required' });
    }
    await notificationModel.markAllAsRead(playerId);
    res.json({ ok: true, message: 'All notifications marked as read' });
  } catch (error) {
    res.status(500).json({ ok: false, message: error.message });
  }
}

async function triggerOngoingNotifications(req, res) {
  try {
    const draws = await notificationModel.getImpendingCutoffs();
    let sentCount = 0;
    
    for (const draw of draws) {
      const title = `Ongoing Game: ${draw.game_name}`;
      const message = `Don't miss out! The cutoff for ${draw.game_name} (${draw.name}) is in less than an hour. Play now!`;
      await notificationModel.broadcastNotification(title, message, 'ongoing');
      sentCount++;
    }
    
    res.json({ ok: true, message: `Sent ${sentCount} broadcast notifications for ongoing games.` });
  } catch (error) {
    res.status(500).json({ ok: false, message: error.message });
  }
}

async function deleteNotification(req, res) {
  try {
    const { id } = req.params;
    const success = await notificationModel.deleteNotification(id);
    if (!success) {
      return res.status(404).json({ ok: false, message: 'Notification not found' });
    }
    res.json({ ok: true, message: 'Notification deleted' });
  } catch (error) {
    res.status(500).json({ ok: false, message: error.message });
  }
}

async function deleteAll(req, res) {
  try {
    const { playerId } = req.body;
    if (!playerId) {
      return res.status(400).json({ ok: false, message: 'playerId is required' });
    }
    await notificationModel.deleteAllNotifications(playerId);
    res.json({ ok: true, message: 'All notifications deleted' });
  } catch (error) {
    res.status(500).json({ ok: false, message: error.message });
  }
}

module.exports = {
  getNotifications,
  getUnreadCount,
  markRead,
  markAllRead,
  triggerOngoingNotifications,
  deleteNotification,
  deleteAll,
};
