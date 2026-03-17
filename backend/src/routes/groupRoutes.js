const express = require('express');
const router = express.Router();
const groupController = require('../controllers/groupController');

router.post('/', groupController.createGroup);
router.get('/public', groupController.getPublicGroups);
router.get('/my/:playerId', groupController.getMyGroups);
router.get('/private/available/:playerId', groupController.getAvailablePrivateGroups);
router.get('/:id', groupController.getGroupById);
router.put('/:id', groupController.updateGroup);
router.delete('/:id', groupController.deleteGroup);

router.post('/:id/join', groupController.joinGroup);
router.post('/join-code', groupController.joinByCode);


router.get('/:id/members', groupController.getGroupMembers);
router.delete('/members/:id', groupController.removeMember);

router.post('/:id/invite', groupController.invitePlayer);
router.get('/invitations/:playerId', groupController.getInvitations);
router.put('/invitations/:id/respond', groupController.respondToInvitation);

module.exports = router;
