const pool = require('../../db');
const crypto = require('crypto');


function generateGroupCode() {
  return crypto.randomBytes(4).toString('hex').toUpperCase();
}


function mapMemberStatus(status) {
  if (typeof status === 'number') return status;
  const s = String(status).toLowerCase();
  if (s === 'active' || s === '1') return 1;
  if (s === 'pending' || s === '2') return 2;
  if (s === 'declined' || s === '3') return 3;
  return 1; 
}


async function createGroup({ name, desc, status, group_type, created_by, drawdate_id, lotterytype_id }) {
  const pgroup_code = generateGroupCode();
  const numericStatus = (status === 'Inactive' || status === 1) ? 1 : 0;

  const groupTypeFlag = (group_type === 'Private' || lotterytype_id === 2) ? 2 : 1;

  const [result] = await pool.execute(
    `INSERT INTO \`groups\` 
       (pgroup_code, lotterytype_id, drawdate_id, system_id, operator_id, name, \`desc\`, total_bets, max_per, gen_numbers, status, created_by, updated_by, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())`,
    [
      pgroup_code,
      groupTypeFlag, 
      drawdate_id || 32,            
      4,            
      null,         
      name,
      desc || null,
      0,            
      10,            
      '',           
      numericStatus,
      String(created_by),
      String(created_by)
    ]
  );

  try {
    const memberStatus = mapMemberStatus('active');
    await pool.execute(
      `INSERT INTO private_groups (pgroup_code, player_id, player_name, name, \`desc\`, status, created_by, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, NOW(), NOW())`,
      [pgroup_code, created_by, '', name, desc || '', memberStatus, String(created_by)]
    );
  } catch (memberErr) {
  }

  return { id: result.insertId, pgroup_code };
}


async function getPublicGroups(drawId) {
  const [rows] = await pool.execute(
    `SELECT id, pgroup_code, name, \`desc\`, total_bets, max_per, status, created_by, created_at, lotterytype_id,
            drawdate_id as draw_id, 'public' as type,
            (SELECT COUNT(*) FROM private_groups pg WHERE pg.pgroup_code = g.pgroup_code AND pg.status = 1 AND pg.deleted_at IS NULL) as member_count
     FROM \`groups\` g
     WHERE deleted_at IS NULL AND (status = 'Active' OR status = 0) AND lotterytype_id = 1
     ORDER BY CASE WHEN drawdate_id = ? THEN 0 ELSE 1 END, created_at DESC`,
    [drawId || 0]
  );
  return rows;
}


async function getGroupsByPlayerId(playerId) {
  const [rows] = await pool.execute(
    `SELECT g.id, g.pgroup_code, g.name, g.\`desc\`, g.total_bets, g.max_per, g.status,
            g.created_by, g.created_at, pg.status AS member_status, g.lotterytype_id,
            g.drawdate_id as draw_id, CASE WHEN g.lotterytype_id = 1 THEN 'public' ELSE 'private' END as type,
            (SELECT COUNT(*) FROM private_groups pgc WHERE pgc.pgroup_code = g.pgroup_code AND pgc.status = 1 AND pgc.deleted_at IS NULL) as member_count
     FROM \`groups\` g
     INNER JOIN private_groups pg ON g.pgroup_code = pg.pgroup_code
     WHERE pg.player_id = ? AND pg.status = 1 AND g.deleted_at IS NULL AND pg.deleted_at IS NULL
     ORDER BY g.created_at DESC`,
    [playerId]
  );
  return rows;
}


async function getGroupById(id) {
  const [rows] = await pool.execute(
    `SELECT id, pgroup_code, lotterytype_id, drawdate_id, system_id, operator_id,
            name, \`desc\`, total_bets, max_per, gen_numbers, status,
            created_by, created_at, updated_at,
            drawdate_id as draw_id, CASE WHEN lotterytype_id = 1 THEN 'public' ELSE 'private' END as type,
            (SELECT COUNT(*) FROM private_groups pg WHERE pg.pgroup_code = g.pgroup_code AND pg.status = 1 AND pg.deleted_at IS NULL) as member_count
     FROM \`groups\` g
     WHERE id = ? AND deleted_at IS NULL
     LIMIT 1`,
    [id]
  );
  return rows.length ? rows[0] : null;
}

async function getGroupByCode(code) {
  const [rows] = await pool.execute(
    `SELECT id, pgroup_code, name, \`desc\`, total_bets, max_per, status, created_by, created_at
     FROM \`groups\`
     WHERE pgroup_code = ? AND deleted_at IS NULL
     LIMIT 1`,
    [code]
  );
  return rows.length ? rows[0] : null;
}

async function updateGroup(id, { name, desc, status }) {
  const numericStatus = (status === 'Inactive' || status === 1) ? 1 : 0;
  const [result] = await pool.execute(
    `UPDATE \`groups\`
     SET name = ?, \`desc\` = ?, status = ?, updated_at = NOW()
     WHERE id = ? AND deleted_at IS NULL`,
    [name, desc || '', numericStatus, id]
  );
  return result.affectedRows > 0;
}


async function deleteGroup(id) {
  const [result] = await pool.execute(
    `UPDATE \`groups\` SET deleted_at = NOW() WHERE id = ? AND deleted_at IS NULL`,
    [id]
  );
  return result.affectedRows > 0;
}

async function addMember({ pgroup_code, player_id, player_name, user_code, name, desc, status, created_by }) {
  const numericStatus = mapMemberStatus(status || 'active');

  const [existing] = await pool.execute(
    `SELECT id, status FROM private_groups
     WHERE pgroup_code = ? AND player_id = ? AND deleted_at IS NULL
     LIMIT 1`,
    [pgroup_code, player_id]
  );

  if (existing.length) {
    if (existing[0].status === 1) {
      return { alreadyMember: true };
    }
    await pool.execute(
      `UPDATE private_groups SET status = ?, updated_at = NOW() WHERE id = ?`,
      [numericStatus, existing[0].id]
    );
    return { id: existing[0].id, reactivated: true };
  }

  const [result] = await pool.execute(
    `INSERT INTO private_groups
       (pgroup_code, player_id, player_name, user_code, name, \`desc\`, forum, status, created_by, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, '', ?, ?, NOW(), NOW())`,
    [pgroup_code, player_id, player_name || '', user_code || '', name || '', desc || '', numericStatus, created_by || player_id]
  );
  return { id: result.insertId };
}

/**
 * Get members of a group
 */
async function getMembers(pgroupCode) {
  const [rows] = await pool.execute(
    `SELECT pg.id, pg.pgroup_code, pg.player_id, 
            CONCAT(p.first_name, ' ', p.last_name) as player_name, 
            pg.user_code, pg.status, pg.created_at
     FROM private_groups pg
     INNER JOIN players p ON pg.player_id = p.id
     WHERE pg.pgroup_code = ? AND pg.deleted_at IS NULL
     ORDER BY pg.created_at ASC`,
    [pgroupCode]
  );
  return rows;
}

/**
 * Pending invitations for a player
 */
async function getPendingInvitations(playerId) {
  const [rows] = await pool.execute(
    `SELECT pg.id, pg.pgroup_code, pg.name, pg.\`desc\`, pg.status, pg.created_by, pg.created_at,
            g.name AS group_name, g.\`desc\` AS group_desc, g.lotterytype_id,
            CONCAT(p.first_name, ' ', p.last_name) AS invited_by_name
     FROM private_groups pg
     LEFT JOIN \`groups\` g ON pg.pgroup_code = g.pgroup_code
     LEFT JOIN players p ON pg.created_by = p.id
     WHERE pg.player_id = ? AND pg.status = 2 AND pg.deleted_at IS NULL
     ORDER BY pg.created_at DESC`,
    [playerId]
  );
  return rows;
}

/**
 * Respond to invitation (accept / decline)
 */
async function respondToInvitation(id, status) {
  const numericStatus = mapMemberStatus(status);
  const [result] = await pool.execute(
    `UPDATE private_groups SET status = ?, updated_at = NOW() WHERE id = ? AND deleted_at IS NULL`,
    [numericStatus, id]
  );
  return result.affectedRows > 0;
}

/**
 * Remove member (soft-delete)
 */
async function removeMember(id) {
  const [result] = await pool.execute(
    `UPDATE private_groups SET deleted_at = NOW() WHERE id = ? AND deleted_at IS NULL`,
    [id]
  );
  return result.affectedRows > 0;
}

async function getAvailablePrivateGroups(playerId) {
  const [rows] = await pool.execute(
    `SELECT g.id, g.pgroup_code, g.name, g.\`desc\`, g.total_bets, g.max_per, g.status, 
            g.created_by, g.created_at,
            (SELECT COUNT(*) FROM private_groups pg WHERE pg.pgroup_code = g.pgroup_code AND pg.player_id = ? AND pg.status = 1 AND pg.deleted_at IS NULL) as is_member
     FROM \`groups\` g
     WHERE g.deleted_at IS NULL AND (g.status = 'Active' OR g.status = 0) AND g.lotterytype_id = 2
     ORDER BY g.created_at DESC`,
    [playerId]
  );
  return rows;
}

module.exports = {
  generateGroupCode,
  createGroup,
  getPublicGroups,
  getGroupsByPlayerId,
  getGroupById,
  getGroupByCode,
  updateGroup,
  deleteGroup,
  addMember,
  getMembers,
  getPendingInvitations,
  respondToInvitation,
  removeMember,
  getAvailablePrivateGroups,
};
