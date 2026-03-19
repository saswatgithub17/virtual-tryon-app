// =============================================
// VIRTUAL TRY-ON CONTROLLER
// AI-powered dress try-on
// =============================================

const db = require('../config/database');
const tryonService = require('../services/tryonService');
const path = require('path');
const fs = require('fs');

// =============================================
// PROCESS VIRTUAL TRY-ON
// POST /api/tryon
// Body: { userPhoto: file, dress_ids: [1, 2, 3] }
// =============================================
const processTryOn = async (req, res) => {
    try {
        const { dress_ids } = req.body;

        // Validate user photo upload
        if (!req.file) {
            return res.status(400).json({
                success: false,
                message: 'User photo is required'
            });
        }

        // Validate dress IDs
        if (!dress_ids || !Array.isArray(JSON.parse(dress_ids)) || JSON.parse(dress_ids).length === 0) {
            return res.status(400).json({
                success: false,
                message: 'At least one dress ID is required'
            });
        }

        const dressIdsArray = JSON.parse(dress_ids);
        const userPhotoPath = req.file.path;

        console.log('📸 User photo uploaded:', userPhotoPath);
        console.log('👗 Processing dresses:', dressIdsArray);

        // Get dress image paths from database
        const placeholders = dressIdsArray.map(() => '?').join(',');
        const query = `SELECT dress_id, name, image_url FROM dresses WHERE dress_id IN (${placeholders})`;

        db.query(query, dressIdsArray, async (err, dresses) => {
            if (err) {
                console.error('Error fetching dresses:', err);
                return res.status(500).json({
                    success: false,
                    message: 'Error fetching dress information',
                    error: err.message
                });
            }

            if (dresses.length === 0) {
                return res.status(404).json({
                    success: false,
                    message: 'No valid dresses found'
                });
            }

            // Build dress meta (ids/names + file path) while keeping indexes aligned.
            // Only keep dresses whose image file exists on disk.
            const dressMeta = dresses
                .map(dress => {
                    let imagePath = dress.image_url;

                    // If it's a relative path starting with /uploads
                    if (imagePath.startsWith('/uploads')) {
                        imagePath = '.' + imagePath;
                    }

                    if (!fs.existsSync(imagePath)) {
                        console.warn(`⚠️ Dress image not found: ${imagePath}`);
                        return null;
                    }

                    return {
                        dressId: dress.dress_id,
                        dressName: dress.name,
                        originalDressImage: dress.image_url,
                        imagePath,
                    };
                })
                .filter(Boolean);

            const dressImagePaths = dressMeta.map(m => m.imagePath);

            if (dressImagePaths.length === 0) {
                return res.status(404).json({
                    success: false,
                    message: 'No valid dress images found. Please upload dress images first.'
                });
            }

            console.log('📁 Dress image paths:', dressImagePaths);

            try {
                // ALWAYS try AI - don't check availability first
                console.log('✅ Attempting AI-powered try-on');

                const results = await tryonService.processMultipleTryOns(
                    userPhotoPath,
                    dressImagePaths
                );

                // Merge service results with dress metadata by index.
                const enrichedResults = results.map((r, index) => ({
                    success: r.success === true,
                    resultUrl: r.resultUrl ?? null,
                    method: r.method ?? 'Fallback',
                    error: r.error ?? null,
                    dressId: dressMeta[index].dressId,
                    dressName: dressMeta[index].dressName,
                    originalDressImage: dressMeta[index].originalDressImage,
                }));

                // Save try-on history to database (optional)
                const sessionId = `SESSION-${Date.now()}`;
                const insertHistoryQuery = `
                    INSERT INTO tryon_history 
                    (session_id, dress_ids, user_image_path, result_image_paths)
                    VALUES (?, ?, ?, ?)
                `;

                const resultPaths = enrichedResults
                    .filter(r => r.success)
                    .map(r => r.resultUrl)
                    .filter(Boolean)
                    .join(',');

                db.query(
                    insertHistoryQuery,
                    [
                        sessionId,
                        dressIdsArray.join(','),
                        userPhotoPath,
                        resultPaths,
                    ],
                    (err) => {
                        if (err) console.error('Error saving try-on history:', err);
                    }
                );

                const successCount = enrichedResults.filter(r => r.success).length;

                const tryonResults = enrichedResults.map(result => ({
                    success: result.success,
                    dressId: result.dressId,
                    dressName: result.dressName,
                    originalDressImage: result.originalDressImage,
                    tryonResultUrl: result.success ? result.resultUrl : null,
                    method: result.method,
                    error: result.error,
                }));

                const firstSuccessfulResult = tryonResults.find(
                    r => r.success && r.tryonResultUrl
                );
                const mainTryonResultUrl = firstSuccessfulResult
                    ? firstSuccessfulResult.tryonResultUrl
                    : null;

                const hasAnySuccess = successCount > 0;
                const firstError = tryonResults.find(r => !r.success && r.error)?.error;
                const fallbackMessage = firstError
                    ? `AI try-on failed: ${String(firstError).slice(0, 200)}`
                    : 'AI try-on failed: no output images were generated.';
                res.json({
                    success: hasAnySuccess,
                    message: hasAnySuccess
                        ? `Try-on completed for ${successCount}/${dressImagePaths.length} dresses`
                        : fallbackMessage,
                    sessionId,
                    tryonResultUrl: hasAnySuccess ? mainTryonResultUrl : null,
                    userPhoto: `/uploads/user-photos/${path.basename(userPhotoPath)}`,
                    totalDresses: dressImagePaths.length,
                    successfulTryOns: successCount,
                    results: tryonResults,
                });

            } catch (error) {
                console.error('❌ Error processing try-on:', error);
                
                // Check if it's a model loading error
                if (error.message.includes('model is loading')) {
                    return res.status(503).json({
                        success: false,
                        message: 'AI model is loading. Please try again in 20-30 seconds.',
                        retryAfter: 30
                    });
                }

                res.status(500).json({
                    success: false,
                    message: 'Error processing virtual try-on',
                    error: error.message
                });
            }
        });

    } catch (error) {
        console.error('❌ Error in processTryOn:', error);
        res.status(500).json({
            success: false,
            message: 'Error processing try-on request',
            error: error.message
        });
    }
};

module.exports = {
    processTryOn
};