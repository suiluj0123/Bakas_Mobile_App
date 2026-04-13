const pool = require('../../db');

//profile
async function userInfo(playerId) {
    const [rows] = await pool.query('SELECT * FROM players WHERE id = ?', [playerId]);

    if (!rows || rows.length === 0) return null;
    return rows[0];
}

async function profileUpdate(data) {
    const {
        playerId,
        last_name,
        first_name,
        middle_name,
        contact_num,
        email,
        region_code,
        provincial_code,
        city_code,
        address,
        barangay_code,
        picture,
        id_code,
        id_number,
        id_photo
    } = data;
    console.log(data);
    const [result] = await pool.execute(
        `UPDATE players
            SET
                last_name = IFNULL(NULLIF(?, ''), last_name),
                first_name = IFNULL(NULLIF(?, ''), first_name),
                middle_name = IFNULL(NULLIF(?, ''), middle_name),
                contact_num = IFNULL(NULLIF(?, ''), contact_num),
                email = IFNULL(NULLIF(?, ''), email),
                region_code = IFNULL(NULLIF(?, ''), region_code),
                provincial_code = IFNULL(NULLIF(?, ''), provincial_code),
                city_code = IFNULL(NULLIF(?, ''), city_code),
                address = IFNULL(NULLIF(?, ''), address),
                barangay_code = IFNULL(NULLIF(?, ''), barangay_code),
                picture = IFNULL(NULLIF(?, ''), picture),
                id_code = IFNULL(NULLIF(?, ''), id_code),
                id_number = IFNULL(NULLIF(?, ''), id_number),
                id_photo = IFNULL(NULLIF(?, ''), id_photo),
                updated_at = NOW()
         WHERE id = ?`,
        [
            last_name || null,
            first_name || null,
            middle_name || null,
            contact_num || null,
            email || null,
            region_code || null,
            provincial_code || null,
            city_code || null,
            address || null,
            barangay_code || null,
            picture || null,
            id_code || null,
            id_number || null,
            id_photo || null,
            playerId || null
        ]
    );

    if (!result) return null;
    return result;
}

//wallet
async function get_wallet(playerId) {
    const [rows] = await pool.query(`
        SELECT 
            pw.id as walletId, 
            pw.player_id, 
            pw.wallet_id, 
            pw.account_number as wallet_number, 
            wt.name as wallet_type,
            pw.link_status
        FROM player_wallets pw
        JOIN wallet_types wt ON pw.wallet_id = wt.id
        WHERE pw.player_id = ? AND pw.deleted_at IS NULL
    `, [playerId]);

    if (!rows || rows.length === 0) return null;
    return rows;
}

async function add_wallet(data) {
    const { playerId,
            wallet_type,
            wallet_number
        } = data;

    if (!playerId) {
        throw new Error('Player ID is required to add a wallet');
    }

    // 1. Find the wallet_id from wallet_types based on name
    const [types] = await pool.query('SELECT id FROM wallet_types WHERE name = ? LIMIT 1', [wallet_type]);
    if (!types || types.length === 0) {
        throw new Error(`Wallet type "${wallet_type}" not found in database`);
    }
    const walletId = types[0].id;

    // 2. Insert into player_wallets
    const [result] = await pool.query(
        `INSERT INTO player_wallets (player_id, wallet_id, account_number, link_status, created_by, created_at) 
         VALUES (?, ?, ?, 1, ?, NOW())`,
        [playerId, walletId, wallet_number, playerId]
    );

    if (!result || result.affectedRows === 0) return null;
    return result;
}

async function edit_wallet(playerId, playerWalletId, wallet_number) {
    const [result] = await pool.query(`
        UPDATE player_wallets 
        SET account_number = ?, updated_by = ?, updated_at = NOW()
        WHERE player_id = ? AND id = ?`, 
        [wallet_number, playerId, playerId, playerWalletId]
    );
    if (!result) return null;
    return result;
}

//Secuurity
async function check_password(playerId, oldPassword) {
    const [rows] = await pool.query('SELECT * FROM players WHERE id = ? AND password = ?', [playerId, oldPassword]);

    if (!rows || rows.length === 0) return null;
    return rows[0];
}

async function change_password(data) {
    const { playerId, confirmPassword } = data;
    const [result] = await pool.execute('UPDATE players SET password = ?, updated_at = NOW() WHERE id = ?', [confirmPassword, playerId]);

    if (!result) return null;
    return result;
}

async function getRegions() {
    const [rows] = await pool.execute('SELECT region_code as code, region_description as name FROM philippine_regions ORDER BY region_description');
    return rows;
}

async function getProvinces(regionCode) {
    const [rows] = await pool.execute('SELECT province_code as code, province_description as name FROM philippine_provinces WHERE region_code = ? ORDER BY province_description', [regionCode]);
    return rows;
}

async function getCities(provinceCode) {
    const [rows] = await pool.execute('SELECT city_municipality_code as code, city_municipality_description as name FROM philippine_cities WHERE province_code = ? ORDER BY city_municipality_description', [provinceCode]);
    return rows;
}

async function getBarangays(cityCode) {
    const [rows] = await pool.execute('SELECT barangay_code as code, barangay_description as name FROM philippine_barangays WHERE city_municipality_code = ? ORDER BY barangay_description', [cityCode]);
    return rows;
}

module.exports = {
    profileUpdate,
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
}