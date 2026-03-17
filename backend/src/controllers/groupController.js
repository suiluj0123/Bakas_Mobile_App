const groupModel = require('../models/groupModel');


async function createGroup(req, res) {
  try {
    const { name, desc, status, group_type, created_by } = req.body;

    if (!name || !created_by) {
      return res.status(400).json({ ok: false, message: 'Name and created_by are required' });
    }

    const result = await groupModel.createGroup({
      name, desc, status, group_type, created_by
    });

    res.status(201).json({ ok: true, data: result });
  } catch (error) {
    console.error('[Groups] Create error:', error.message);
    res.status(500).json({ ok: false, message: error.message });
  }
}

async function getPublicGroups(req, res) {
  try {
    const groups = await groupModel.getPublicGroups();
    res.status(200).json({ ok: true, data: groups });
  } catch (error) {
    res.status(500).json({ ok: false, message: error.message });
  }
}


async function getMyGroups(req, res) {
  try {
    const { playerId } = req.params;
    if (!playerId) {
      return res.status(400).json({ ok: false, message: 'Player ID is required' });
    }

    const groups = await groupModel.getGroupsByPlayerId(playerId);
    res.status(200).json({ ok: true, data: groups });
  } catch (error) {
    res.status(500).json({ ok: false, message: error.message });
  }
}

async function getAvailablePrivateGroups(req, res) {
  try {
    const { playerId } = req.params;
    if (!playerId) {
       return res.status(400).json({ ok: false, message: 'Player ID is required' });
    }
    const groups = await groupModel.getAvailablePrivateGroups(playerId);
    res.status(200).json({ ok: true, data: groups });
  } catch (error) {
    res.status(500).json({ ok: false, message: error.message });
  }
}

async function getGroupById(req, res) {
  try {
    const { id } = req.params;
    const group = await groupModel.getGroupById(id);

    if (!group) {
      return res.status(404).json({ ok: false, message: 'Group not found' });
    }

    res.status(200).json({ ok: true, data: group });
  } catch (error) {
    res.status(500).json({ ok: false, message: error.message });
  }
}


async function updateGroup(req, res) {
  try {
    const { id } = req.params;
    const { name, desc, status } = req.body;

    if (!name) {
      return res.status(400).json({ ok: false, message: 'Name is required' });
    }

    const success = await groupModel.updateGroup(id, { name, desc, status });

    if (success) {
      res.status(200).json({ ok: true, message: 'Group updated' });
    } else {
      res.status(404).json({ ok: false, message: 'Group not found' });
    }
  } catch (error) {
    res.status(500).json({ ok: false, message: error.message });
  }
}

async function deleteGroup(req, res) {
  try {
    const { id } = req.params;
    const success = await groupModel.deleteGroup(id);

    if (success) {
      res.status(200).json({ ok: true, message: 'Group deleted' });
    } else {
      res.status(404).json({ ok: false, message: 'Group not found' });
    }
  } catch (error) {
    res.status(500).json({ ok: false, message: error.message });
  }
}


async function joinGroup(req, res) {
  try {
    const { id } = req.params;
    const { player_id, player_name } = req.body;

    if (!player_id) {
      return res.status(400).json({ ok: false, message: 'Player ID is required' });
    }

    const group = await groupModel.getGroupById(id);
    if (!group) {
      return res.status(404).json({ ok: false, message: 'Group not found' });
    }

    const result = await groupModel.addMember({
      pgroup_code: group.pgroup_code,
      player_id,
      player_name: player_name || '',
      user_code: '',
      name: group.name,
      desc: group.desc,
      status: 'active',
      created_by: player_id
    });

    if (result.alreadyMember) {
      return res.status(409).json({ ok: false, message: 'Already a member of this group' });
    }

    res.status(200).json({ ok: true, message: 'Joined group successfully', data: result });
  } catch (error) {
    res.status(500).json({ ok: false, message: error.message });
  }
}

async function joinByCode(req, res) {
  try {
    const { code, player_id, player_name } = req.body;

    if (!code || !player_id) {
      return res.status(400).json({ ok: false, message: 'Code and Player ID are required' });
    }

    const group = await groupModel.getGroupByCode(code);
    if (!group) {
      return res.status(404).json({ ok: false, message: 'Invalid group code' });
    }

    const result = await groupModel.addMember({
      pgroup_code: code,
      player_id,
      player_name: player_name || '',
      user_code: '',
      name: group.name,
      desc: group.desc,
      status: 'active',
      created_by: player_id
    });

    if (result.alreadyMember) {
      return res.status(409).json({ ok: false, message: 'Already a member of this group' });
    }

    res.status(200).json({ ok: true, message: 'Joined group successfully', data: { ...result, group_name: group.name } });
  } catch (error) {
    res.status(500).json({ ok: false, message: error.message });
  }
}

async function getGroupMembers(req, res) {
  try {
    const { id } = req.params;
    const group = await groupModel.getGroupById(id);

    if (!group) {
      return res.status(404).json({ ok: false, message: 'Group not found' });
    }

    const members = await groupModel.getMembers(group.pgroup_code);
    res.status(200).json({ ok: true, data: members });
  } catch (error) {
    res.status(500).json({ ok: false, message: error.message });
  }
}

async function removeMember(req, res) {
  try {
    const { id } = req.params;
    const success = await groupModel.removeMember(id);

    if (success) {
      res.status(200).json({ ok: true, message: 'Member removed' });
    } else {
      res.status(404).json({ ok: false, message: 'Member not found' });
    }
  } catch (error) {
    res.status(500).json({ ok: false, message: error.message });
  }
}

async function invitePlayer(req, res) {
  try {
    const { id } = req.params;
    const { player_id, player_name, invited_by } = req.body;

    if (!player_id || !invited_by) {
      return res.status(400).json({ ok: false, message: 'Player ID and invited_by are required' });
    }

    const group = await groupModel.getGroupById(id);
    if (!group) {
      return res.status(404).json({ ok: false, message: 'Group not found' });
    }

    const result = await groupModel.addMember({
      pgroup_code: group.pgroup_code,
      player_id,
      player_name: player_name || '',
      user_code: '',
      name: group.name,
      desc: group.desc,
      status: 'pending',
      created_by: invited_by
    });

    if (result.alreadyMember) {
      return res.status(409).json({ ok: false, message: 'Player is already a member' });
    }

    res.status(200).json({ ok: true, message: 'Invitation sent', data: result });
  } catch (error) {
    res.status(500).json({ ok: false, message: error.message });
  }
}

async function getInvitations(req, res) {
  try {
    const { playerId } = req.params;
    if (!playerId) {
      return res.status(400).json({ ok: false, message: 'Player ID is required' });
    }

    const invitations = await groupModel.getPendingInvitations(playerId);
    res.status(200).json({ ok: true, data: invitations });
  } catch (error) {
    res.status(500).json({ ok: false, message: error.message });
  }
}

async function respondToInvitation(req, res) {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!status || !['active', 'declined'].includes(status)) {
      return res.status(400).json({ ok: false, message: 'Status must be "active" or "declined"' });
    }

    const success = await groupModel.respondToInvitation(id, status);

    if (success) {
      res.status(200).json({ ok: true, message: status === 'active' ? 'Invitation accepted' : 'Invitation declined' });
    } else {
      res.status(404).json({ ok: false, message: 'Invitation not found' });
    }
  } catch (error) {
    res.status(500).json({ ok: false, message: error.message });
  }
}

module.exports = {
  createGroup,
  getPublicGroups,
  getMyGroups,
  getGroupById,
  updateGroup,
  deleteGroup,
  joinGroup,
  joinByCode,
  getGroupMembers,
  removeMember,
  invitePlayer,
  getInvitations,
  respondToInvitation,
  getAvailablePrivateGroups,
};
