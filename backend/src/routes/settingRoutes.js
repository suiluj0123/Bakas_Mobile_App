const express = require('express');

const { userInfoUpdate, 
        getUserInfo,
        getWallet,
        addWallet,
        editWallet,
        changePassword,
        checkPassword,
        getRegionsList,
        getProvincesList,
        getCitiesList,
        getBarangaysList
    } = require('../controllers/settingController');

const { uploadProfilePhotos } = require('../middleware/uploadMiddleware');
const router = express.Router();

router.put('/profileUpdate', uploadProfilePhotos, userInfoUpdate);
router.get('/profile/:playerId', getUserInfo);
router.get('/wallet/:playerId', getWallet);
router.post('/addWallet', addWallet);
router.put('/editWallet', editWallet);
router.put('/changePassword', changePassword);
router.post('/checkPassword', checkPassword);

router.get('/regions', getRegionsList);
router.get('/provinces/:regionCode', getProvincesList);
router.get('/cities/:provinceCode', getCitiesList);
router.get('/barangays/:cityCode', getBarangaysList);

module.exports = router;