const groupMessageModel = require('../models/groupMessageModel');

/**
 * Get messages for a group
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

    console.log(`[CHAT] Fetching messages for group ${id} (limit ${limit})...`);
    const messages = await groupMessageModel.getGroupMessages(id, limit);
    console.log(`[CHAT] Found ${messages.length} messages for group ${id}`);

    res.status(200).json({ ok: true, data: messages });

  } catch (error) {
    console.error('Error fetching group messages:', error);
    res.status(500).json({ ok: false, message: 'Internal server error' });
  }
}

/**
 * Send a message to a group
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

    console.log(`[CHAT] Saving message from sender ${senderId} to group ${id}: "${message.substring(0, 20)}..."`);
    const result = await groupMessageModel.createGroupMessage({
      groupId: id,
      senderId,
      message,
    });
    console.log(`[CHAT] Message saved successfully. New ID: ${result.id}`);


    res.status(201).json({ ok: true, data: result });
  } catch (error) {
    console.error('Error sending group message:', error);
    res.status(500).json({ ok: false, message: 'Internal server error' });
  }
}

module.exports = {
  getGroupMessages,
  sendGroupMessage,
};
