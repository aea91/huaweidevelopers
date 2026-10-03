const functions = require('firebase-functions');
const admin = require('firebase-admin');
const crypto = require('crypto');

admin.initializeApp();

const SUGGESTION_SCHEMA = `{
  "summary": "string",
  "layoutDescription": "string",
  "widgets": [{"id": "catalog widget id", "reason": "why this widget"}],
  "managerIds": ["catalog manager id"],
  "primaryColor": "#RRGGBB",
  "secondaryColor": "#RRGGBB",
  "tertiaryColor": "#RRGGBB",
  "isDarkMode": true,
  "models": [{"name": "ModelName", "sampleJson": {}, "reason": "why"}],
  "projectName": "PascalCaseAppName",
  "projectDescription": "short description"
}`;

function parseJsonFromModelText(text) {
  const fenced = text.match(/```json\s*([\s\S]*?)```/i);
  const candidate = fenced ? fenced[1] : text;
  const start = candidate.indexOf('{');
  const end = candidate.lastIndexOf('}');
  if (start === -1 || end === -1 || end <= start) {
    throw new Error('Model response did not contain JSON');
  }
  return JSON.parse(candidate.slice(start, end + 1));
}

function sanitizeSuggestion(raw, catalog) {
  const validWidgetIds = new Set((catalog.widgets || []).map((w) => w.id));
  const validManagerIds = new Set((catalog.managers || []).map((m) => m.id));

  const widgets = Array.isArray(raw.widgets)
    ? raw.widgets
        .filter((item) => item && validWidgetIds.has(item.id))
        .slice(0, 10)
    : [];

  const managerIds = Array.isArray(raw.managerIds)
    ? raw.managerIds.filter((id) => validManagerIds.has(id))
    : [];

  const hex = (value, fallback) =>
    typeof value === 'string' && /^#[0-9A-Fa-f]{6}$/.test(value) ? value : fallback;

  return {
    summary: typeof raw.summary === 'string' ? raw.summary : 'AI catalog proposal is ready.',
    layoutDescription:
      typeof raw.layoutDescription === 'string' ? raw.layoutDescription : '',
    widgets,
    managerIds,
    primaryColor: hex(raw.primaryColor, '#6200EE'),
    secondaryColor: hex(raw.secondaryColor, '#03DAC6'),
    tertiaryColor: hex(raw.tertiaryColor, '#FF6B6B'),
    isDarkMode: raw.isDarkMode === true,
    models: Array.isArray(raw.models) ? raw.models.slice(0, 5) : [],
    projectName: typeof raw.projectName === 'string' ? raw.projectName : undefined,
    projectDescription:
      typeof raw.projectDescription === 'string' ? raw.projectDescription : undefined,
    usedCloudAi: true,
  };
}

/**
 * AI assistant for App Builder.
 * Selects widgets/managers/models from the provided catalog only.
 *
 * Configure Gemini:
 * firebase functions:config:set gemini.key="YOUR_GEMINI_API_KEY"
 */
exports.suggestAppDesign = functions.https.onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  if (req.method !== 'POST') {
    res.status(405).send('Method Not Allowed');
    return;
  }

  const description = (req.body?.description || '').trim();
  const catalog = req.body?.catalog || {};

  if (!description) {
    res.status(400).json({ error: 'description is required' });
    return;
  }

  const apiKey =
    functions.config().gemini?.key || process.env.GEMINI_API_KEY || '';

  if (!apiKey) {
    res.status(503).json({ error: 'Gemini API key is not configured' });
    return;
  }

  const widgetCatalog = (catalog.widgets || [])
    .map((w) => ({
      id: w.id,
      title: w.title,
      description: w.description,
      category: w.category,
      mainCategory: w.mainCategory,
      tags: w.tags || [],
    }))
    .slice(0, 120);

  const managerCatalog = (catalog.managers || [])
    .map((m) => ({
      id: m.id,
      title: m.title,
      description: m.description,
      className: m.className,
    }))
    .slice(0, 40);

  const prompt = [
    'You are an ArkUI app design assistant.',
    'Choose ONLY ids that exist in the provided catalogs.',
    'Never invent widget ids or manager ids.',
    'Prefer 4-8 widgets with a clear dashboard/page layout.',
    'Return JSON only, matching this schema:',
    SUGGESTION_SCHEMA,
    '',
    `User description: ${description}`,
    `Widget catalog: ${JSON.stringify(widgetCatalog)}`,
    `Manager catalog: ${JSON.stringify(managerCatalog)}`,
  ].join('\n');

  try {
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${apiKey}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: {
            temperature: 0.2,
            responseMimeType: 'application/json',
          },
        }),
      }
    );

    if (!response.ok) {
      const errorText = await response.text();
      console.error('Gemini error:', errorText);
      res.status(500).json({ error: 'Gemini request failed' });
      return;
    }

    const payload = await response.json();
    const text =
      payload?.candidates?.[0]?.content?.parts?.[0]?.text ||
      payload?.candidates?.[0]?.content?.parts?.map((p) => p.text).join('\n');

    if (!text) {
      res.status(500).json({ error: 'Empty Gemini response' });
      return;
    }

    const parsed = parseJsonFromModelText(text);
    const suggestion = sanitizeSuggestion(parsed, {
      widgets: widgetCatalog,
      managers: managerCatalog,
    });

    if (!suggestion.widgets.length) {
      res.status(422).json({ error: 'No valid widgets selected from catalog' });
      return;
    }

    res.status(200).json(suggestion);
  } catch (error) {
    console.error('suggestAppDesign failed:', error);
    res.status(500).json({ error: 'Failed to generate suggestion' });
  }
});

/**
 * Proxy an RSS feed and return parsed JSON items.
 * Used for Google News / Medium RSS where browser CORS blocks direct fetch.
 *
 * GET ?url=<encoded rss url>
 */
exports.proxyRss = functions.https.onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }
  if (req.method !== 'GET') {
    res.status(405).send('Method Not Allowed');
    return;
  }

  const feedUrl = (req.query.url || '').toString();
  if (!feedUrl.startsWith('https://')) {
    res.status(400).json({ error: 'url must be https' });
    return;
  }

  const allowedHosts = [
    'news.google.com',
    'medium.com',
    'cdn-1.medium.com',
    'youtube.com',
    'www.youtube.com',
  ];
  let host;
  try {
    host = new URL(feedUrl).hostname;
  } catch (_) {
    res.status(400).json({ error: 'invalid url' });
    return;
  }
  if (!allowedHosts.some((h) => host === h || host.endsWith(`.${h}`))) {
    res.status(400).json({ error: 'host not allowed' });
    return;
  }

  try {
    const response = await fetch(feedUrl, {
      headers: {
        'User-Agent':
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        Accept: 'application/rss+xml, application/xml, text/xml, */*',
      },
    });
    if (!response.ok) {
      res.status(502).json({ error: `upstream ${response.status}` });
      return;
    }
    const xml = await response.text();
    const items = parseRssItems(xml);
    res.set('Cache-Control', 'public, max-age=600');
    res.status(200).json({ status: 'ok', count: items.length, items });
  } catch (error) {
    console.error('proxyRss failed:', error);
    res.status(500).json({ error: 'Failed to fetch RSS' });
  }
});

/**
 * Resolve a Google News article redirect URL to the original publisher URL.
 *
 * GET ?url=<google news article url>
 */
exports.resolveGoogleNewsUrl = functions
  .runWith({ timeoutSeconds: 30, memory: '256MB' })
  .https.onRequest(async (req, res) => {
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }
    if (req.method !== 'GET') {
      res.status(405).send('Method Not Allowed');
      return;
    }

    const articleUrl = (req.query.url || '').toString();
    if (!articleUrl.includes('news.google.com')) {
      res.status(400).json({ error: 'url must be a Google News article link' });
      return;
    }

    try {
      const decoded = await resolveGoogleNewsArticleUrl(articleUrl);
      if (!decoded) {
        res.status(422).json({ error: 'Could not resolve article URL' });
        return;
      }
      res.set('Cache-Control', 'public, max-age=86400');
      res.status(200).json({ status: 'ok', url: decoded });
    } catch (error) {
      console.error('resolveGoogleNewsUrl failed:', error);
      res.status(500).json({ error: 'Failed to resolve URL' });
    }
  });

/**
 * Full Wearables Medium archive: merge Medium tag feeds + Google News results,
 * resolve Google News links to Medium URLs, cache in Firestore for 6 hours.
 */
exports.getMediumWearableArticles = functions
  .runWith({ timeoutSeconds: 300, memory: '1GB' })
  .https.onRequest(async (req, res) => {
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }
    if (req.method !== 'GET') {
      res.status(405).send('Method Not Allowed');
      return;
    }

    const forceRefresh = req.query.refresh === '1';
    const offset = Math.max(0, parseInt(String(req.query.offset || '0'), 10) || 0);
    const rawLimit = parseInt(String(req.query.limit || '0'), 10) || 0;
    // limit=0 or omitted ⇒ return full archive (legacy). Else page size 1–50.
    const limit = rawLimit <= 0 ? 0 : Math.min(50, Math.max(1, rawLimit));
    const cacheRef = admin.firestore().collection('cache').doc('medium_wearables');

    try {
      let articles = null;
      let cached = false;

      if (!forceRefresh) {
        const snap = await cacheRef.get();
        if (snap.exists) {
          const data = snap.data() || {};
          const updatedAt = data.updatedAt?.toMillis?.() || data.updatedAtMs || 0;
          if (Date.now() - updatedAt < 6 * 60 * 60 * 1000 && Array.isArray(data.articles)) {
            articles = data.articles;
            cached = true;
          }
        }
      }

      if (!articles) {
        articles = await buildMediumWearableArchive();
        await cacheRef.set({
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAtMs: Date.now(),
          articles,
        });
      }

      const total = articles.length;
      const page = limit === 0 ? articles : articles.slice(offset, offset + limit);
      const nextOffset = limit === 0 ? total : offset + page.length;

      res.set('Cache-Control', 'private, no-store');
      res.status(200).json({
        status: 'ok',
        cached,
        total,
        offset,
        limit: limit === 0 ? total : limit,
        count: page.length,
        hasMore: nextOffset < total,
        articles: page,
      });
    } catch (error) {
      console.error('getMediumWearableArticles failed:', error);
      res.status(500).json({ error: 'Failed to build Medium archive' });
    }
  });

/**
 * Guest scrape of a LinkedIn company overview feed (no login).
 * Cached in Firestore for 2 hours.
 *
 * GET ?company=hsdturkiye&limit=5
 */
exports.getLinkedInCompanyPosts = functions
  .runWith({ timeoutSeconds: 60, memory: '512MB' })
  .https.onRequest(async (req, res) => {
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }
    if (req.method !== 'GET') {
      res.status(405).send('Method Not Allowed');
      return;
    }

    const company = String(req.query.company || 'hsdturkiye')
      .trim()
      .toLowerCase()
      .replace(/[^a-z0-9_-]/g, '');
    if (!company) {
      res.status(400).json({ error: 'company is required' });
      return;
    }

    const limit = Math.min(20, Math.max(1, parseInt(String(req.query.limit || '5'), 10) || 5));
    const forceRefresh = req.query.refresh === '1';
    const cacheRef = admin.firestore().collection('cache').doc(`linkedin_${company}`);

    try {
      let posts = null;
      let cached = false;

      if (!forceRefresh) {
        const snap = await cacheRef.get();
        if (snap.exists) {
          const data = snap.data() || {};
          const updatedAt = data.updatedAt?.toMillis?.() || data.updatedAtMs || 0;
          if (Date.now() - updatedAt < 2 * 60 * 60 * 1000 && Array.isArray(data.posts)) {
            posts = data.posts;
            cached = true;
          }
        }
      }

      if (!posts) {
        posts = await fetchLinkedInCompanyPosts(company);
        await cacheRef.set({
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAtMs: Date.now(),
          posts,
          company,
        });
      }

      const page = posts.slice(0, limit);
      res.set('Cache-Control', 'private, no-store');
      res.status(200).json({
        status: 'ok',
        cached,
        company,
        total: posts.length,
        count: page.length,
        posts: page,
        companyUrl: `https://www.linkedin.com/company/${company}/posts/?feedView=all`,
      });
    } catch (error) {
      console.error('getLinkedInCompanyPosts failed:', error);
      res.status(500).json({ error: 'Failed to fetch LinkedIn posts' });
    }
  });

async function fetchLinkedInCompanyPosts(company) {
  const urls = [
    `https://www.linkedin.com/company/${company}/`,
    `https://tr.linkedin.com/company/${company}/`,
  ];

  let html = '';
  for (const url of urls) {
    try {
      const response = await fetch(url, {
        headers: {
          'User-Agent':
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          Accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.9,tr;q=0.8',
        },
        redirect: 'follow',
      });
      if (!response.ok) continue;
      const body = await response.text();
      if (body.includes('main-feed-activity-card')) {
        html = body;
        break;
      }
      if (!html && body.length > 1000) html = body;
    } catch (err) {
      console.warn('linkedin fetch failed', url, err?.message || err);
    }
  }

  if (!html) {
    throw new Error('LinkedIn company page unavailable');
  }

  return parseLinkedInCompanyPosts(html, company);
}

function parseLinkedInCompanyPosts(html, company) {
  const parts = html.split(/(?=<article\b[^>]*main-feed-activity-card)/i);
  const posts = [];
  const seen = new Set();

  for (const part of parts) {
    if (!/main-feed-activity-card/i.test(part.slice(0, 240))) continue;
    const block = part.split(/<\/article>/i)[0] || '';
    const urnMatch = /data-activity-urn="(urn:li:activity:\d+)"/i.exec(block);
    if (!urnMatch) continue;
    const urn = urnMatch[1];
    const id = urn.split(':').pop();
    if (!id || seen.has(id)) continue;
    seen.add(id);

    const texts = [];
    const pRegex = /<p[^>]*class="[^"]*break-words[^"]*"[^>]*>([\s\S]*?)<\/p>/gi;
    let pMatch;
    while ((pMatch = pRegex.exec(block)) !== null) {
      const text = stripHtml(pMatch[1]);
      if (text) texts.push(text);
    }

    const images = [];
    const imgRegex =
      /data-delayed-url="(https:\/\/media\.licdn\.com\/dms\/image\/[^"]+)"/gi;
    let imgMatch;
    while ((imgMatch = imgRegex.exec(block)) !== null) {
      const url = decodeXml(imgMatch[1]);
      if (/company-logo|ghost|static\.licdn/i.test(url)) continue;
      images.push(url);
    }

    const excerpt = texts[0] || '';
    if (!excerpt && images.length === 0) continue;

    let title = excerpt || 'LinkedIn post';
    if (title.length > 90) {
      title = `${title.slice(0, 87).replace(/\s+\S*$/, '')}...`;
    }

    posts.push({
      id,
      title,
      excerpt: excerpt.length > 220 ? `${excerpt.slice(0, 217).trim()}...` : excerpt,
      url: `https://www.linkedin.com/feed/update/${urn}/`,
      imageUrl: images[0] || null,
      author: 'HSD Türkiye',
      publishedAt: null,
      source: 'linkedin',
      company,
    });
  }

  return posts;
}

/**
 * Recent videos from a YouTube channel via public Atom feed.
 * Cached in Firestore for 2 hours.
 *
 * GET ?channelId=UCxxxx&limit=5
 */
exports.getYouTubeChannelVideos = functions
  .runWith({ timeoutSeconds: 30, memory: '256MB' })
  .https.onRequest(async (req, res) => {
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }
    if (req.method !== 'GET') {
      res.status(405).send('Method Not Allowed');
      return;
    }

    const channelId = String(req.query.channelId || 'UCoNPnz0C7LUt4Klng8fvDGA')
      .trim()
      .replace(/[^A-Za-z0-9_-]/g, '');
    if (!channelId.startsWith('UC')) {
      res.status(400).json({ error: 'channelId must look like UCxxxx' });
      return;
    }

    const limit = Math.min(20, Math.max(1, parseInt(String(req.query.limit || '5'), 10) || 5));
    const forceRefresh = req.query.refresh === '1';
    const cacheRef = admin.firestore().collection('cache').doc(`youtube_${channelId}`);

    try {
      let videos = null;
      let cached = false;

      if (!forceRefresh) {
        const snap = await cacheRef.get();
        if (snap.exists) {
          const data = snap.data() || {};
          const updatedAt = data.updatedAt?.toMillis?.() || data.updatedAtMs || 0;
          if (Date.now() - updatedAt < 2 * 60 * 60 * 1000 && Array.isArray(data.videos)) {
            videos = data.videos;
            cached = true;
          }
        }
      }

      if (!videos) {
        videos = await fetchYouTubeChannelVideos(channelId);
        await cacheRef.set({
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAtMs: Date.now(),
          videos,
          channelId,
        });
      }

      const page = videos.slice(0, limit);
      res.set('Cache-Control', 'private, no-store');
      res.status(200).json({
        status: 'ok',
        cached,
        channelId,
        total: videos.length,
        count: page.length,
        videos: page,
        channelUrl: `https://www.youtube.com/channel/${channelId}/streams`,
      });
    } catch (error) {
      console.error('getYouTubeChannelVideos failed:', error);
      res.status(500).json({ error: 'Failed to fetch YouTube videos' });
    }
  });

async function fetchYouTubeChannelVideos(channelId) {
  const feedUrl = `https://www.youtube.com/feeds/videos.xml?channel_id=${channelId}`;
  const response = await fetch(feedUrl, {
    headers: {
      'User-Agent':
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      Accept: 'application/atom+xml, application/xml, text/xml, */*',
    },
  });
  if (!response.ok) {
    throw new Error(`YouTube feed ${response.status}`);
  }
  return parseYouTubeAtomFeed(await response.text(), channelId);
}

function parseYouTubeAtomFeed(xml, channelId) {
  const videos = [];
  const entryRegex = /<entry>([\s\S]*?)<\/entry>/gi;
  let match;
  while ((match = entryRegex.exec(xml)) !== null) {
    const block = match[1];
    const videoId = extractTag(block, 'yt:videoId');
    const title = decodeXml(extractTag(block, 'title'));
    const link =
      extractAttrHref(block, 'link') ||
      (videoId ? `https://www.youtube.com/watch?v=${videoId}` : '');
    const published = extractTag(block, 'published') || extractTag(block, 'updated');
    const author = decodeXml(extractTag(block, 'name')) || 'YouTube';
    const thumbMatch =
      /<media:thumbnail[^>]*url=["']([^"']+)["']/i.exec(block) ||
      /url=["'](https:\/\/i\.ytimg\.com\/vi\/[^"']+)["']/i.exec(block);
    const imageUrl = thumbMatch ? thumbMatch[1] : videoId
      ? `https://i.ytimg.com/vi/${videoId}/hqdefault.jpg`
      : null;
    const description = decodeXml(
      extractTag(block, 'media:description') || extractTag(block, 'summary') || ''
    );

    if (!videoId || !title) continue;
    videos.push({
      id: videoId,
      title,
      excerpt: description.slice(0, 220),
      url: link.startsWith('http') ? link : `https://www.youtube.com/watch?v=${videoId}`,
      imageUrl,
      author,
      publishedAt: published ? new Date(published).toISOString() : null,
      source: 'youtube',
      channelId,
    });
  }
  return videos;
}

function extractAttrHref(block, tag) {
  const re = new RegExp(`<${tag}[^>]*href=["']([^"']+)["'][^>]*>`, 'i');
  const m = re.exec(block);
  return m ? m[1].trim() : '';
}

function parseRssItems(xml) {
  const items = [];
  const itemRegex = /<item>([\s\S]*?)<\/item>/gi;
  let match;
  while ((match = itemRegex.exec(xml)) !== null) {
    const block = match[1];
    const title = decodeXml(extractTag(block, 'title'));
    const link = decodeXml(extractTag(block, 'link') || extractAttr(block, 'guid'));
    const guid = decodeXml(extractTag(block, 'guid') || link);
    const pubDate = extractTag(block, 'pubDate');
    const author =
      decodeXml(extractTag(block, 'dc:creator')) ||
      decodeXml(extractTag(block, 'author')) ||
      '';
    const description = decodeXml(
      extractTag(block, 'description') || extractTag(block, 'content:encoded') || ''
    );
    const categories = [];
    const catRegex = /<category[^>]*>([\s\S]*?)<\/category>/gi;
    let catMatch;
    while ((catMatch = catRegex.exec(block)) !== null) {
      const value = decodeXml(catMatch[1]).trim();
      if (value) categories.push(value);
    }
    if (!title || !link) continue;
    items.push({
      title,
      link,
      guid,
      pubDate,
      author,
      description,
      categories,
    });
  }
  return items;
}

function extractTag(block, tag) {
  const re = new RegExp(`<${tag}[^>]*><!\\[CDATA\\[([\\s\\S]*?)\\]\\]><\\/${tag}>|<${tag}[^>]*>([\\s\\S]*?)<\\/${tag}>`, 'i');
  const m = re.exec(block);
  return m ? (m[1] || m[2] || '').trim() : '';
}

function extractAttr(block, tag) {
  const re = new RegExp(`<${tag}[^>]*>([\\s\\S]*?)<\\/${tag}>`, 'i');
  const m = re.exec(block);
  return m ? m[1].trim() : '';
}

function decodeXml(value) {
  return String(value || '')
    .replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, '$1')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&nbsp;/g, ' ')
    .trim();
}

function stripHtml(html) {
  return decodeXml(html)
    .replace(/<script[\s\S]*?<\/script>/gi, ' ')
    .replace(/<style[\s\S]*?<\/style>/gi, ' ')
    .replace(/<[^>]+>/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function excerpt(html, max = 180) {
  const text = stripHtml(html);
  if (text.length <= max) return text;
  return `${text.slice(0, max - 3).trim()}...`;
}

function firstImage(html) {
  const m = /<img[^>]+src=["']([^"']+)["']/i.exec(html || '');
  return m ? m[1] : null;
}

function normalizeMediumId(value) {
  const match = /(?:\/p\/|-)([a-f0-9]{8,})$/i.exec(String(value || ''));
  return match ? match[1].toLowerCase() : String(value || '').toLowerCase();
}

function normalizeTitle(title) {
  return String(title || '')
    .toLowerCase()
    .replace(/\s*\|\s*by\s+.*/i, '')
    .replace(/\s*-\s*medium\s*$/i, '')
    .replace(/[^a-z0-9]+/g, ' ')
    .trim();
}

function parseGoogleNewsTitle(title) {
  // Title | by Author | Huawei Developers | Mon, 2026 - Medium
  const parts = String(title || '').split('|').map((p) => p.trim());
  let cleanTitle = parts[0] || title;
  let author = null;
  for (const part of parts) {
    const by = /^by\s+(.+)$/i.exec(part);
    if (by) author = by[1].replace(/\s*-\s*Medium$/i, '').trim();
  }
  cleanTitle = cleanTitle.replace(/\s*-\s*Medium\s*$/i, '').trim();
  return { title: cleanTitle, author };
}

async function fetchRss(feedUrl) {
  const response = await fetch(feedUrl, {
    headers: {
      'User-Agent':
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      Accept: 'application/rss+xml, application/xml, text/xml, */*',
    },
  });
  if (!response.ok) return [];
  return parseRssItems(await response.text());
}

async function resolveGoogleNewsArticleUrl(articleUrl) {
  const articleId = articleUrl.split('/articles/').pop().split('?')[0];
  const pageResp = await fetch(articleUrl, {
    headers: {
      'User-Agent':
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    },
  });
  if (!pageResp.ok) return null;
  const pageText = await pageResp.text();
  const sigMatch =
    pageText.match(/data-n-a-sg="([^"]+)"/) ||
    pageText.match(/data-n-a-sg\\":\\"([^\\]+)\\"/);
  const tsMatch =
    pageText.match(/data-n-a-ts="([^"]+)"/) ||
    pageText.match(/data-n-a-ts\\":\\"([^\\]+)\\"/);
  if (!sigMatch || !tsMatch) return null;

  const signature = sigMatch[1];
  const timestamp = Number(tsMatch[1]);
  const rpcInner = JSON.stringify([
    'garturlreq',
    [
      ['X', 'X', ['X', 'X'], null, null, 1, 1, 'US:en', null, 1, null, null, null, null, null, 0, 1],
      'X',
      'X',
      1,
      [1, 1, 1],
      1,
      1,
      null,
      0,
      0,
      null,
      0,
    ],
    articleId,
    timestamp,
    signature,
  ]);
  const payload = [[['Fbv4je', rpcInner, null, 'generic']]];
  const body = `f.req=${encodeURIComponent(JSON.stringify(payload))}`;
  const rpcResp = await fetch('https://news.google.com/_/DotsSplashUi/data/batchexecute', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
      'User-Agent':
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      Referer: articleUrl,
    },
    body,
  });
  if (!rpcResp.ok) return null;
  let text = await rpcResp.text();
  text = text.replace(/^\)\]\}'\s*/, '');
  const envelopes = JSON.parse(text);
  for (const env of envelopes) {
    if (Array.isArray(env) && env[0] === 'wrb.fr' && env[1] === 'Fbv4je') {
      const payloadJson = JSON.parse(env[2]);
      if (payloadJson && payloadJson[0] === 'garturlres') {
        return payloadJson[1];
      }
    }
  }
  return null;
}

async function mapPool(items, concurrency, mapper) {
  const results = new Array(items.length);
  let index = 0;
  async function worker() {
    while (index < items.length) {
      const current = index++;
      results[current] = await mapper(items[current], current);
    }
  }
  await Promise.all(Array.from({ length: Math.min(concurrency, items.length) }, () => worker()));
  return results;
}

function googleNewsSearchUrl(query) {
  // Google News RSS from Cloud prefers + separators over %20.
  const encoded = encodeURIComponent(query).replace(/%20/g, '+');
  return `https://news.google.com/rss/search?q=${encoded}&hl=en-US&gl=US&ceid=US:en`;
}

async function buildMediumWearableArchive() {
  const strictFeeds = [
    'https://medium.com/feed/huawei-developers/tagged/wearables',
    'https://medium.com/feed/huawei-developers/tagged/harmonyos-next-wearables',
    'https://medium.com/feed/huawei-developers/tagged/smartwatch',
    'https://medium.com/feed/huawei-developers/tagged/litewearable',
    'https://medium.com/feed/huawei-developers/tagged/lite-wearable',
    'https://medium.com/feed/huawei-developers/tagged/wear-engine',
    'https://medium.com/feed/huawei-developers/tagged/wearengine',
    'https://medium.com/feed/huawei-developers/tagged/huawei-watch',
    'https://medium.com/feed/huawei-developers/tagged/watch5',
    'https://medium.com/feed/huawei-developers/tagged/watch',
  ];

  // Google News RSS caps ~100/query — split keywords + date windows to cover more.
  const googleQueries = [
    'site:medium.com/huawei-developers (wearable OR wearables OR smartwatch OR litewearable OR "wear engine" OR watch)',
    'site:medium.com/huawei-developers (wearable OR wearables) before:2025-01-01 after:2023-01-01',
    'site:medium.com/huawei-developers wearable before:2024-01-01 after:2022-01-01',
    'site:medium.com/huawei-developers (litewearable OR wearengine OR "wear engine" OR "wear-engine")',
    'site:medium.com/huawei-developers ("harmonyos next wearables" OR watch5 OR "watch face" OR "crown gesture")',
  ];

  const feedResults = await Promise.all(
    strictFeeds.map(async (url) => {
      try {
        return await fetchRss(url);
      } catch (err) {
        console.warn('feed failed', url, err?.message || err);
        return [];
      }
    })
  );

  const googleResults = await Promise.all(
    googleQueries.map(async (q) => {
      const url = googleNewsSearchUrl(q);
      try {
        const items = await fetchRss(url);
        console.log('gnews', items.length, q.slice(0, 60));
        return items;
      } catch (err) {
        console.warn('gnews failed', q.slice(0, 60), err?.message || err);
        return [];
      }
    })
  );

  // Legacy raw query form that previously returned ~100 from Cloud.
  if (googleResults.every((g) => g.length === 0)) {
    const legacy =
      'https://news.google.com/rss/search?q=site:medium.com/huawei-developers+(wearable+OR+wearables+OR+smartwatch+OR+litewearable+OR+%22wear+engine%22+OR+watch)&hl=en-US&gl=US&ceid=US:en';
    try {
      const items = await fetchRss(legacy);
      console.log('gnews legacy', items.length);
      googleResults.push(items);
    } catch (err) {
      console.warn('gnews legacy failed', err?.message || err);
    }
  }

  const googleItems = [];
  const seenGoogle = new Set();
  for (const group of googleResults) {
    for (const item of group) {
      const key = item.guid || item.link;
      if (!key || seenGoogle.has(key)) continue;
      seenGoogle.add(key);
      googleItems.push(item);
    }
  }

  console.log(
    'archive sources',
    JSON.stringify({
      feedItems: feedResults.reduce((n, g) => n + g.length, 0),
      googleItems: googleItems.length,
    })
  );

  const byKey = new Map();

  function upsert(article) {
    // When we learn the Medium id, drop the temporary title-keyed Google row.
    if (article.mediumId && article.titleKey) {
      const byTitle = byKey.get(article.titleKey);
      if (byTitle && byTitle.mediumId !== article.mediumId) {
        byKey.delete(article.titleKey);
      }
    }

    const key = article.mediumId || article.titleKey;
    if (!key) return;
    const existing = byKey.get(key);
    if (!existing) {
      byKey.set(key, article);
      return;
    }
    // Prefer real Medium URL over Google News URL.
    if (!existing.url.includes('medium.com') && article.url.includes('medium.com')) {
      byKey.set(key, { ...existing, ...article, title: existing.title || article.title });
      return;
    }
    // Prefer richer metadata.
    if (!existing.imageUrl && article.imageUrl) {
      existing.imageUrl = article.imageUrl;
    }
    if (!existing.excerpt && article.excerpt) {
      existing.excerpt = article.excerpt;
    }
    if (!existing.author && article.author) {
      existing.author = article.author;
    }
    if (article.mediumId && !existing.mediumId) {
      existing.mediumId = article.mediumId;
      existing.id = article.id || existing.id;
      if (article.url.includes('medium.com')) existing.url = article.url;
    }
  }

  for (const items of feedResults) {
    for (const item of items) {
      const url = item.link.split('?')[0];
      upsert({
        id: normalizeMediumId(item.guid || url),
        mediumId: normalizeMediumId(item.guid || url),
        titleKey: normalizeTitle(item.title),
        title: item.title,
        url,
        excerpt: excerpt(item.description),
        author: item.author || null,
        imageUrl: firstImage(item.description),
        publishedAt: item.pubDate ? new Date(item.pubDate).toISOString() : null,
        tags: item.categories || [],
        source: 'medium',
      });
    }
  }

  // Upsert raw Google items first so total grows even if URL resolve fails.
  for (const item of googleItems) {
    const parsed = parseGoogleNewsTitle(item.title);
    upsert({
      id: normalizeMediumId(item.guid || item.link),
      mediumId: null,
      titleKey: normalizeTitle(parsed.title),
      title: parsed.title,
      url: item.link,
      excerpt: excerpt(item.description),
      author: parsed.author,
      imageUrl: null,
      publishedAt: item.pubDate ? new Date(item.pubDate).toISOString() : null,
      tags: ['wearables'],
      source: 'medium',
    });
  }

  // Resolve Google News URLs to Medium (parallel, limited).
  const unresolved = Array.from(byKey.values()).filter((a) =>
    String(a.url || '').includes('news.google.com')
  );
  const resolved = await mapPool(unresolved, 8, async (article) => {
    let mediumUrl = null;
    try {
      mediumUrl = await resolveGoogleNewsArticleUrl(article.url);
    } catch (_) {
      mediumUrl = null;
    }
    if (mediumUrl && !mediumUrl.includes('medium.com')) {
      mediumUrl = null;
    }
    if (!mediumUrl) return null;
    return {
      ...article,
      id: normalizeMediumId(mediumUrl),
      mediumId: normalizeMediumId(mediumUrl),
      url: mediumUrl,
    };
  });

  for (const article of resolved) {
    if (article) upsert(article);
  }

  const articles = Array.from(byKey.values()).filter((a) => a.title && a.url);
  articles.sort((a, b) => {
    const at = a.publishedAt ? Date.parse(a.publishedAt) : 0;
    const bt = b.publishedAt ? Date.parse(b.publishedAt) : 0;
    return bt - at;
  });

  console.log('archive total', articles.length);
  return articles.map(({ mediumId, titleKey, ...rest }) => rest);
}

/**
 * Public widget/manager catalog for ArkUIBuilder Tool (DevEco plugin) and web clients.
 * GET https://us-central1-arkuibuilder.cloudfunctions.net/getWidgetCatalog
 */
exports.getWidgetCatalog = functions.https.onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  if (req.method !== 'GET') {
    res.status(405).json({ error: 'Method Not Allowed' });
    return;
  }

  try {
    const db = admin.firestore();
    const [widgetsSnap, managersSnap] = await Promise.all([
      db.collection('widgets').orderBy('createdAt', 'desc').get(),
      db.collection('managers').orderBy('createdAt', 'desc').get(),
    ]);

    const widgets = widgetsSnap.docs.map((doc) => {
      const d = doc.data() || {};
      return {
        id: doc.id,
        title: d.title || '',
        description: d.description || '',
        mainCategory: d.mainCategory || 'Mobile',
        category: d.category || '',
        gifUrl: d.gifUrl || '',
        code: d.code || '',
        tags: Array.isArray(d.tags) ? d.tags : [],
      };
    });

    const managers = managersSnap.docs.map((doc) => {
      const d = doc.data() || {};
      return {
        id: doc.id,
        name: d.name || d.className || '',
        className: d.className || '',
        description: d.description || '',
        code: d.code || '',
      };
    });

    res.set('Cache-Control', 'public, max-age=120');
    res.json({
      widgets,
      managers,
      updatedAt: new Date().toISOString(),
    });
  } catch (error) {
    console.error('getWidgetCatalog error:', error);
    res.status(500).json({ error: 'Failed to load catalog' });
  }
});

/**
 * Cloud Function to proxy Firebase Storage images
 * This bypasses corporate firewall restrictions on firebasestorage.googleapis.com
 * 
 * Usage: https://us-central1-arkuibuilder.cloudfunctions.net/proxyImage?path=widget_gifs/filename.png
 */
exports.proxyImage = functions.https.onRequest(async (req, res) => {
  // Enable CORS for all origins
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, HEAD, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');
  
  // Handle preflight OPTIONS request
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }
  
  // Only allow GET requests
  if (req.method !== 'GET') {
    return res.status(405).send('Method Not Allowed');
  }
  
  const imagePath = req.query.path;
  
  if (!imagePath) {
    return res.status(400).send('Missing path parameter. Usage: ?path=widget_gifs/filename.png');
  }
  
  try {
    const bucket = admin.storage().bucket();
    const file = bucket.file(imagePath);
    
    // Check if file exists
    const [exists] = await file.exists();
    
    if (!exists) {
      console.error(`File not found: ${imagePath}`);
      return res.status(404).send('Image not found');
    }
    
    // Get file metadata
    const [metadata] = await file.getMetadata();
    
    // Set response headers
    res.set('Content-Type', metadata.contentType || 'application/octet-stream');
    res.set('Content-Length', metadata.size);
    res.set('Cache-Control', 'public, max-age=3600'); // Cache for 1 hour
    res.set('ETag', metadata.etag);
    
    // Stream the file to response
    file.createReadStream()
      .on('error', (err) => {
        console.error('Stream error:', err);
        if (!res.headersSent) {
          res.status(500).send('Error fetching image');
        }
      })
      .pipe(res);
      
  } catch (error) {
    console.error('Function error:', error);
    if (!res.headersSent) {
      res.status(500).send('Internal server error');
    }
  }
});

/** Calendar day (YYYY-MM-DD) a visit is counted under, in Türkiye time. */
function visitDateKey() {
  return new Intl.DateTimeFormat('en-CA', { timeZone: 'Europe/Istanbul' }).format(new Date());
}

/**
 * Count a site visit. Called once per page load by the web app.
 * Firestore rules keep /analytics admin-only, so public writes go through here.
 *
 * POST { visitorId } — random id the browser keeps in localStorage; only its hash is stored.
 *
 * analytics/visits                           { totalVisits, totalUniqueVisitors }
 * analytics/visits/daily/{YYYY-MM-DD}        { date, visits, uniqueVisitors }
 * analytics/visits/daily/{date}/visitors/{h} dedupe marker for that day
 * analytics/visits/visitors/{h}              dedupe marker for all time
 */
exports.trackVisit = functions.https.onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }
  if (req.method !== 'POST') {
    res.status(405).send('Method Not Allowed');
    return;
  }

  const visitorId = String(req.body?.visitorId || '');
  if (!/^[A-Za-z0-9_-]{16,64}$/.test(visitorId)) {
    res.status(400).json({ error: 'visitorId is required' });
    return;
  }

  const date = visitDateKey();
  const hash = crypto.createHash('sha256').update(visitorId).digest('hex');
  const db = admin.firestore();
  const visitsRef = db.collection('analytics').doc('visits');
  const dayRef = visitsRef.collection('daily').doc(date);
  const dayVisitorRef = dayRef.collection('visitors').doc(hash);
  const knownVisitorRef = visitsRef.collection('visitors').doc(hash);
  const { FieldValue } = admin.firestore;

  try {
    await db.runTransaction(async (tx) => {
      const [dayVisitor, knownVisitor] = await tx.getAll(dayVisitorRef, knownVisitorRef);
      const now = FieldValue.serverTimestamp();

      tx.set(
        dayRef,
        {
          date,
          visits: FieldValue.increment(1),
          uniqueVisitors: FieldValue.increment(dayVisitor.exists ? 0 : 1),
          updatedAt: now,
        },
        { merge: true }
      );
      tx.set(
        visitsRef,
        {
          totalVisits: FieldValue.increment(1),
          totalUniqueVisitors: FieldValue.increment(knownVisitor.exists ? 0 : 1),
          updatedAt: now,
        },
        { merge: true }
      );
      if (!dayVisitor.exists) tx.set(dayVisitorRef, { firstSeenAt: now });
      if (!knownVisitor.exists) {
        tx.set(knownVisitorRef, { firstSeenAt: now, firstSeenDate: date });
      }
    });
    res.status(200).json({ status: 'ok', date });
  } catch (error) {
    console.error('trackVisit failed:', error);
    res.status(500).json({ error: 'Failed to record visit' });
  }
});
