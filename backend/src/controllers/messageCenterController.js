const messageCenterModel = require('../models/messageCenterModel');

/**
 * 
 */
async function getPlayerMessages(req, res) {
  try {
    const { playerId } = req.params;

    if (!playerId) {
      return res.status(400).json({
        ok: false,
        message: 'Player ID is required'
      });
    }

    const messages = await messageCenterModel.getMessagesByPlayerId(playerId);

    res.status(200).json({
      ok: true,
      data: messages,
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: error.message
    });
  }
}

/**
 * Mark a message as read
 */
async function markAsRead(req, res) {
  try {
    const { id } = req.params;

    const success = await messageCenterModel.markMessageAsRead(id);

    if (success) {
      res.status(200).json({
        ok: true,
        message: 'Message marked as read'
      });
    } else {
      res.status(404).json({
        ok: false,
        message: 'Message not found'
      });
    }
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: error.message
    });
  }
}

/**
 * Delete a message
 */
async function deleteMessage(req, res) {
  try {
    const { id } = req.params;

    const success = await messageCenterModel.deleteMessage(id);

    if (success) {
      res.status(200).json({
        ok: true,
        message: 'Message deleted'
      });
    } else {
      res.status(404).json({
        ok: false,
        message: 'Message not found'
      });
    }
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: error.message
    });
  }
}

module.exports = {
  getPlayerMessages,
  markAsRead,
  deleteMessage,
};
