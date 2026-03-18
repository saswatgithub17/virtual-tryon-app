// =============================================
// DRESS CONTROLLER
// Handles all dress-related operations
// =============================================

const db = require('../config/database');

// =============================================
// GET ALL DRESSES (with optional filters)
// GET /api/dresses?category=Casual&minPrice=1000&maxPrice=5000
// =============================================
const getAllDresses = (req, res) => {
    const { category, minPrice, maxPrice, brand, sortBy = 'created_at', order = 'DESC' } = req.query;

    let query = `
        SELECT 
            d.*,
            GROUP_CONCAT(
                CONCAT(ds.size_name, ':', ds.stock_quantity) 
                SEPARATOR ','
            ) as sizes
        FROM dresses d
        LEFT JOIN dress_sizes ds ON d.dress_id = ds.dress_id
        WHERE d.is_active = TRUE
    `;

    const params = [];

    // Add filters
    if (category) {
        query += ' AND d.category = ?';
        params.push(category);
    }

    if (minPrice) {
        query += ' AND d.price >= ?';
        params.push(parseFloat(minPrice));
    }

    if (maxPrice) {
        query += ' AND d.price <= ?';
        params.push(parseFloat(maxPrice));
    }

    if (brand) {
        query += ' AND d.brand = ?';
        params.push(brand);
    }

    query += ' GROUP BY d.dress_id';

    // Add sorting
    const validSortFields = ['price', 'created_at', 'average_rating', 'name'];
    const sortField = validSortFields.includes(sortBy) ? sortBy : 'created_at';
    const sortOrder = order.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';
    query += ` ORDER BY d.${sortField} ${sortOrder}`;

    db.query(query, params, (err, results) => {
        if (err) {
            console.error('Error fetching dresses:', err);
            return res.status(500).json({
                success: false,
                message: 'Error fetching dresses',
                error: err.message
            });
        }

        // Format sizes from string to array of objects
        const formattedResults = results.map(dress => {
            const sizesArray = dress.sizes ? dress.sizes.split(',').map(size => {
                const [name, stock] = size.split(':');
                return { size: name, stock: parseInt(stock) };
            }) : [];

            return {
                ...dress,
                sizes: sizesArray
            };
        });

        res.json({
            success: true,
            count: formattedResults.length,
            data: formattedResults
        });
    });
};

// =============================================
// GET DRESS BY ID (with reviews)
// GET /api/dresses/:id
// =============================================
const getDressById = (req, res) => {
    const { id } = req.params;

    const dressQuery = `
        SELECT 
            d.*,
            GROUP_CONCAT(
                CONCAT(ds.size_name, ':', ds.stock_quantity) 
                SEPARATOR ','
            ) as sizes
        FROM dresses d
        LEFT JOIN dress_sizes ds ON d.dress_id = ds.dress_id
        WHERE d.dress_id = ?
        GROUP BY d.dress_id
    `;

    const reviewsQuery = `
        SELECT * FROM reviews 
        WHERE dress_id = ? 
        ORDER BY created_at DESC
    `;

    db.query(dressQuery, [id], (err, dressResults) => {
        if (err) {
            console.error('Error fetching dress:', err);
            return res.status(500).json({
                success: false,
                message: 'Error fetching dress details',
                error: err.message
            });
        }

        if (dressResults.length === 0) {
            return res.status(200).json({
                success: false,
                message: 'Dress not found',
                data: null
            });
        }

        const dress = dressResults[0];

        // Format sizes
        const sizesArray = dress.sizes ? dress.sizes.split(',').map(size => {
            const [name, stock] = size.split(':');
            return { size: name, stock: parseInt(stock) };
        }) : [];

        // Fetch reviews
        db.query(reviewsQuery, [id], (err, reviews) => {
            if (err) {
                console.error('Error fetching reviews:', err);
                reviews = [];
            }

            res.status(200).json({
                success: true,
                data: {
                    ...dress,
                    sizes: sizesArray,
                    reviews: reviews
                }
            });
        });
    });
};

// =============================================
// SEARCH DRESSES
// GET /api/dresses/search/query?q=black&category=Evening
// =============================================
const searchDresses = (req, res) => {
    const { q, category } = req.query;

    if (!q) {
        return res.status(400).json({
            success: false,
            message: 'Search query parameter "q" is required'
        });
    }

    let query = `
        SELECT 
            d.*,
            GROUP_CONCAT(
                CONCAT(ds.size_name, ':', ds.stock_quantity) 
                SEPARATOR ','
            ) as sizes
        FROM dresses d
        LEFT JOIN dress_sizes ds ON d.dress_id = ds.dress_id
        WHERE d.is_active = TRUE
        AND (d.name LIKE ? OR d.description LIKE ? OR d.brand LIKE ?)
    `;

    const searchTerm = `%${q}%`;
    const params = [searchTerm, searchTerm, searchTerm];

    if (category) {
        query += ' AND d.category = ?';
        params.push(category);
    }

    query += ' GROUP BY d.dress_id ORDER BY d.average_rating DESC';

    db.query(query, params, (err, results) => {
        if (err) {
            console.error('Error searching dresses:', err);
            return res.status(500).json({
                success: false,
                message: 'Error searching dresses',
                error: err.message
            });
        }

        const formattedResults = results.map(dress => {
            const sizesArray = dress.sizes ? dress.sizes.split(',').map(size => {
                const [name, stock] = size.split(':');
                return { size: name, stock: parseInt(stock) };
            }) : [];

            return {
                ...dress,
                sizes: sizesArray
            };
        });

        res.json({
            success: true,
            count: formattedResults.length,
            query: q,
            data: formattedResults
        });
    });
};

// =============================================
// ADD NEW DRESS (Admin Only)
// POST /api/dresses
// =============================================
const addDress = (req, res) => {
    const {
        name,
        description,
        price,
        category,
        brand,
        color,
        material,
        image_url,
        sizes // Array: [{size: 'S', stock: 10}, {size: 'M', stock: 15}]
    } = req.body;

    // Validation
    if (!name || !price || !image_url) {
        return res.status(400).json({
            success: false,
            message: 'Name, price, and image_url are required'
        });
    }

    const insertDressQuery = `
        INSERT INTO dresses 
        (name, description, price, category, brand, color, material, image_url)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `;

    const dressParams = [
        name,
        description || null,
        price,
        category || null,
        brand || null,
        color || null,
        material || null,
        image_url
    ];

    db.query(insertDressQuery, dressParams, (err, result) => {
        if (err) {
            console.error('Error adding dress:', err);
            return res.status(500).json({
                success: false,
                message: 'Error adding dress',
                error: err.message
            });
        }

        const dressId = result.insertId;

        // Add sizes if provided
        if (sizes && Array.isArray(sizes) && sizes.length > 0) {
            const insertSizesQuery = `
                INSERT INTO dress_sizes (dress_id, size_name, stock_quantity)
                VALUES ?
            `;

            const sizesParams = sizes.map(s => [dressId, s.size, s.stock || 0]);

            db.query(insertSizesQuery, [sizesParams], (err) => {
                if (err) {
                    console.error('Error adding sizes:', err);
                }
            });
        }

        res.status(201).json({
            success: true,
            message: 'Dress added successfully',
            data: {
                dress_id: dressId,
                name,
                price
            }
        });
    });
};

// =============================================
// UPDATE DRESS (Admin Only)
// PUT /api/dresses/:id
// =============================================
const updateDress = (req, res) => {
    const { id } = req.params;
    const {
        name,
        description,
        price,
        category,
        brand,
        color,
        material,
        image_url,
        is_active
    } = req.body;

    const updateQuery = `
        UPDATE dresses 
        SET 
            name = COALESCE(?, name),
            description = COALESCE(?, description),
            price = COALESCE(?, price),
            category = COALESCE(?, category),
            brand = COALESCE(?, brand),
            color = COALESCE(?, color),
            material = COALESCE(?, material),
            image_url = COALESCE(?, image_url),
            is_active = COALESCE(?, is_active)
        WHERE dress_id = ?
    `;

    const params = [
        name,
        description,
        price,
        category,
        brand,
        color,
        material,
        image_url,
        is_active,
        id
    ];

    db.query(updateQuery, params, (err, result) => {
        if (err) {
            console.error('Error updating dress:', err);
            return res.status(500).json({
                success: false,
                message: 'Error updating dress',
                error: err.message
            });
        }

        if (result.affectedRows === 0) {
            return res.status(404).json({
                success: false,
                message: 'Dress not found'
            });
        }

        res.json({
            success: true,
            message: 'Dress updated successfully'
        });
    });
};

// =============================================
// DELETE DRESS (Admin Only)
// DELETE /api/dresses/:id
// =============================================
const deleteDress = (req, res) => {
    const { id } = req.params;

    const deleteQuery = 'DELETE FROM dresses WHERE dress_id = ?';

    db.query(deleteQuery, [id], (err, result) => {
        if (err) {
            console.error('Error deleting dress:', err);
            return res.status(500).json({
                success: false,
                message: 'Error deleting dress',
                error: err.message
            });
        }

        if (result.affectedRows === 0) {
            return res.status(404).json({
                success: false,
                message: 'Dress not found'
            });
        }

        res.json({
            success: true,
            message: 'Dress deleted successfully'
        });
    });
};

// =============================================
// UPLOAD DRESS IMAGE (Admin Only)
// POST /api/dresses/upload
// =============================================
const uploadDressImage = (req, res) => {
    if (!req.file) {
        return res.status(400).json({
            success: false,
            message: 'No image file uploaded'
        });
    }

    const imageUrl = `/uploads/dresses/${req.file.filename}`;

    res.json({
        success: true,
        message: 'Image uploaded successfully',
        data: {
            filename: req.file.filename,
            url: imageUrl,
            size: req.file.size
        }
    });
};

module.exports = {
    getAllDresses,
    getDressById,
    searchDresses,
    addDress,
    updateDress,
    deleteDress,
    uploadDressImage
};