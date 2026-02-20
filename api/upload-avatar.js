import { put } from '@vercel/blob';

export const config = {
    api: {
        bodyParser: false,
    },
};

/**
 * POST /api/upload-avatar?uid=<uid>
 * Body: raw image bytes (image/jpeg or image/png)
 * Returns: { url: "https://..." }
 */
export default async function handler(req, res) {
    // CORS headers so Flutter app can call this from any origin
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') return res.status(200).end();
    if (req.method !== 'POST') {
        return res.status(405).json({ error: 'Method not allowed' });
    }

    try {
        const uid = req.query.uid ?? 'unknown';
        const contentType = req.headers['content-type']?.split(';')[0] ?? 'image/jpeg';
        const ext = contentType === 'image/png' ? 'png' : 'jpg';

        // Read raw body
        const chunks = [];
        for await (const chunk of req) {
            chunks.push(chunk);
        }
        const buffer = Buffer.concat(chunks);

        const blob = await put(`avatars/${uid}/profile.${ext}`, buffer, {
            access: 'public',
            contentType,
            addRandomSuffix: false, // Always overwrite same user's avatar
        });

        return res.status(200).json({ url: blob.url });
    } catch (error) {
        console.error('[upload-avatar] Error:', error);
        return res.status(500).json({ error: error.message });
    }
}
