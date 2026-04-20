const bcrypt = require('bcryptjs');
const { profileUpdate,
    userInfo,
    get_wallet,
    add_wallet,
    edit_wallet,
    change_password,
    check_password,
    getRegions,
    getProvinces,
    getCities,
    getBarangays
} = require('../models/settingModel');

//profile controller
async function userInfoUpdate(req, res) {
    try {
        const data = { ...req.body };
        const playerId = data.playerId;

        if (!playerId) {
            return res.status(400).json({ ok: false, message: 'playerId is required' });
        }

        const baseUrl = `${req.protocol}://${req.get('host')}`;

        if (req.files) {
            if (req.files['profile_photo']) {
                const profilePhoto = req.files['profile_photo'][0];
                data.picture = `${baseUrl}/uploads/profiles/${profilePhoto.filename}`;
            }
            if (req.files['id_photo']) {
                const idPhoto = req.files['id_photo'][0];
                data.id_photo = `${baseUrl}/uploads/profiles/${idPhoto.filename}`;
            }
        }

        const infoUpdated = await profileUpdate(data);
        if (!infoUpdated) {
            return res.status(400).json({ ok: false, message: 'query error' });
        }

        return res.status(200).json({
            ok: true,
            message: 'profile updated successfully',
            data: infoUpdated
        })

    } catch (err) {
        console.error('[PROFILE UPDATE ERROR]:', err);
        return res.status(500).json({ ok: false, message: err?.message || 'Server error' });
    }
}

async function getUserInfo(req, res) {
    try {
        const { playerId } = req.params;

        if (!playerId) {
            console.log('playerId not found');
            return res.status(400).json({ ok: false, message: 'playerId is required' });
        }

        const userData = await userInfo(playerId);
        if (!userData) {
            console.log('userdata not found');
            return res.status(404).json({ ok: false, message: 'User not found' });
        }

        return res.status(200).json({
            ok: true,
            message: 'Get profile successfully',
            data: userData
        })
    } catch (err) {
        return res.status(500).json({ ok: false, message: err?.message || 'Server error' });
    }
}

//wallet controller
async function getWallet(req, res) {
    try {
        const { playerId } = req.params;

        if (!playerId) {
            return res.status(400).json({ ok: false, message: 'playerId required' });
        }

        const wallet = await get_wallet(playerId);
        if (!wallet) {
            return res.status(200).json({
                ok: true,
                message: 'No wallet found',
                data: []
            })
        }

        return res.status(200).json({
            ok: true,
            message: 'get wallet success',
            data: wallet
        })

    } catch (err) {
        console.log(err);
        return res.status(500).json({ ok: false, message: err?.message || 'Server error' });
    }
}

async function addWallet(req, res) {
    try {
        const data = req.body;
        if (!data || !data.playerId) {
            return res.status(400).json({ ok: false, message: 'playerId required' });
        }

        const wallet = await add_wallet(data);
        if (!wallet) {
            return res.status(400).json({ ok: false, message: 'query error' })
        }

        return res.status(200).json({
            ok: true,
            message: 'add wallet successfully',
            data: wallet
        })
    } catch (err) {
        console.log(err);
        return res.status(500).json({ ok: false, message: err?.message || 'Server error' });
    }
}

async function editWallet(req, res) {
    try {
        const { playerId, walletId, wallet_number } = req.body;
        if (!playerId) {
            return res.status(400).json({ ok: false, message: 'playerId required' });
        }

        if (!walletId || !wallet_number) {
            return res.status(400).json({ ok: false, message: 'walletId and wallet_number required' });
        }

        const wallet = await edit_wallet(playerId, walletId, wallet_number);
        if (!wallet) {
            return res.status(400).json({ ok: false, message: 'query error' })
        }

        return res.status(200).json({
            ok: true,
            message: 'edit wallet successfully',
            data: wallet
        })
    } catch (err) {
        console.log(err);
        return res.status(500).json({ ok: false, message: err?.message || 'Server error' });
    }
}

//Security
async function checkPassword(req, res) {
    try {
        const { password, playerId } = req.body;
        if (!playerId) {
            return res.status(400).json({ ok: false, message: 'playerId required' });
        }
        
        const userData = await userInfo(playerId);
        if (!userData) {
            return res.status(404).json({ ok: false, message: 'User not found' });
        }
        
        let matches = false;
        if (userData.password && userData.password.startsWith('$2')) {
            matches = await bcrypt.compare(password, userData.password);
        } else {
            matches = (password === userData.password);
        }

        if (!matches) {
            return res.status(400).json({ ok: false, message: 'Incorrect password' });
        }

        return res.status(200).json({
            ok: true,
            message: 'Password verified',
        })

    } catch (err) {
        console.log(err);
        return res.status(500).json({ ok: false, message: err?.message || 'Server error' });
    }
}

async function changePassword(req, res) {
    try {
        const data = req.body;
        if (!data || !data.playerId) {
            return res.status(400).json({ ok: false, message: 'playerId is required' });
        }

        const hashedPassword = await bcrypt.hash(data.confirmPassword, 10);
        const success = await change_password({ ...data, confirmPassword: hashedPassword });
        if (!success) {
            return res.status(400).json({ ok: false, message: 'error query' });
        }

        return res.status(200).json({
            ok: true,
            message: 'Change password success',
        })

    } catch (err) {
        console.log(err);
        return res.status(500).json({ ok: false, message: err?.message || 'Server error' });
    }
}

// Locations
async function getRegionsList(req, res) {
    console.log('GET /api/settings/regions');
    try {
        const data = await getRegions();
        return res.status(200).json({ ok: true, data });
    } catch (err) {
        console.error('Error fetching regions:', err.message);
        return res.status(500).json({ ok: false, message: err.message });
    }
}

async function getProvincesList(req, res) {
    const { regionCode } = req.params;
    console.log('GET /api/settings/provinces/' + regionCode);
    try {
        const data = await getProvinces(regionCode);
        return res.status(200).json({ ok: true, data });
    } catch (err) {
        console.error('Error fetching provinces:', err.message);
        return res.status(500).json({ ok: false, message: err.message });
    }
}

async function getCitiesList(req, res) {
    const { provinceCode } = req.params;
    console.log('GET /api/settings/cities/' + provinceCode);
    try {
        const data = await getCities(provinceCode);
        return res.status(200).json({ ok: true, data });
    } catch (err) {
        console.error('Error fetching cities:', err.message);
        return res.status(500).json({ ok: false, message: err.message });
    }
}

async function getBarangaysList(req, res) {
    const { cityCode } = req.params;
    console.log('GET /api/settings/barangays/' + cityCode);
    try {
        const data = await getBarangays(cityCode);
        return res.status(200).json({ ok: true, data });
    } catch (err) {
        console.error('Error fetching barangays:', err.message);
        return res.status(500).json({ ok: false, message: err.message });
    }
}

module.exports = {
    userInfoUpdate,
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
}