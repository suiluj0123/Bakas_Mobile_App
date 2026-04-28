const groupMessageModel = require('../models/groupMessageModel');

/**
 * 
 * @param {import('express').Request} req 
 * @param {import('express').Response} res 
 */
async function getGroupMessages(req, res) {
  try {
    const { id } = req.params;
    const limit = parseInt(req.query.limit) || 50;

    if (!id) {
      return res.status(400).json({ ok: false, message: 'Group ID is required' });
    }

    const messages = await groupMessageModel.getGroupMessages(id, limit);

    res.status(200).json({ ok: true, data: messages });

  } catch (error) {
    res.status(500).json({ ok: false, message: 'Internal server error' });
  }
}

/**
 * 
 * @param {import('express').Request} req 
 * @param {import('express').Response} res 
 */
async function sendGroupMessage(req, res) {
  try {
    const { id } = req.params;
    const { senderId, message } = req.body;

    if (!id || !senderId || !message) {
      return res.status(400).json({ ok: false, message: 'Group ID, sender ID, and message are required' });
    }

    const result = await groupMessageModel.createGroupMessage({
      groupId: id,
      senderId,
      message,
    });


    res.status(201).json({ ok: true, data: result });
  } catch (error) {
    res.status(500).json({ ok: false, message: 'Internal server error' });
  }
}

module.exports = {
  getGroupMessages,
  sendGroupMessage,
};
