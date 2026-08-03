#!/usr/bin/env node
/**
 * Upload scripts/courses_seed.json into Firestore:
 *   courses/{id}
 *   courses/{id}/lessons/{lessonId}
 *
 * Auth: uses Firebase CLI tokens from configstore (firebase login).
 * Fallback: ../firebase-service-account.json
 *
 * Usage:
 *   node scripts/upload_courses.js
 */

const fs = require('fs');
const path = require('path');
const https = require('https');
const os = require('os');

const PROJECT_ID = 'arkuibuilder';
const SEED_PATH = path.join(__dirname, 'courses_seed.json');

function loadCliAccessToken() {
  const configPath = path.join(
    os.homedir(),
    '.config/configstore/firebase-tools.json',
  );
  if (!fs.existsSync(configPath)) return null;
  const cfg = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  const tokens = cfg.tokens;
  if (!tokens?.refresh_token) return null;
  return tokens;
}

function refreshAccessToken(tokens) {
  return new Promise((resolve, reject) => {
    const body = new URLSearchParams({
      grant_type: 'refresh_token',
      refresh_token: tokens.refresh_token,
      client_id:
        tokens.client_id ||
        '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com',
      client_secret: tokens.client_secret || 'j9iVZfS8kkCEFUPaAeJV0sAI',
    }).toString();

    const req = https.request(
      {
        hostname: 'oauth2.googleapis.com',
        path: '/token',
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Content-Length': Buffer.byteLength(body),
        },
      },
      (res) => {
        let data = '';
        res.on('data', (c) => (data += c));
        res.on('end', () => {
          try {
            const json = JSON.parse(data);
            if (!json.access_token) {
              reject(new Error('Token refresh failed: ' + data));
              return;
            }
            resolve(json.access_token);
          } catch (e) {
            reject(e);
          }
        });
      },
    );
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

function toFirestoreValue(value) {
  if (value === null || value === undefined) {
    return { nullValue: null };
  }
  if (typeof value === 'string') return { stringValue: value };
  if (typeof value === 'boolean') return { booleanValue: value };
  if (typeof value === 'number') {
    if (Number.isInteger(value)) return { integerValue: String(value) };
    return { doubleValue: value };
  }
  if (Array.isArray(value)) {
    return {
      arrayValue: {
        values: value.map((v) => toFirestoreValue(v)),
      },
    };
  }
  if (typeof value === 'object') {
    const fields = {};
    for (const [k, v] of Object.entries(value)) {
      if (v === undefined) continue;
      fields[k] = toFirestoreValue(v);
    }
    return { mapValue: { fields } };
  }
  return { stringValue: String(value) };
}

function documentFromObject(obj) {
  const fields = {};
  for (const [k, v] of Object.entries(obj)) {
    if (v === undefined) continue;
    fields[k] = toFirestoreValue(v);
  }
  return { fields };
}

function requestJson(method, urlPath, accessToken, bodyObj) {
  const body = bodyObj ? JSON.stringify(bodyObj) : null;
  return new Promise((resolve, reject) => {
    const req = https.request(
      {
        hostname: 'firestore.googleapis.com',
        path: urlPath,
        method,
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
          ...(body ? { 'Content-Length': Buffer.byteLength(body) } : {}),
        },
      },
      (res) => {
        let data = '';
        res.on('data', (c) => (data += c));
        res.on('end', () => {
          if (res.statusCode && res.statusCode >= 400) {
            reject(
              new Error(`${method} ${urlPath} -> ${res.statusCode}: ${data}`),
            );
            return;
          }
          resolve(data ? JSON.parse(data) : {});
        });
      },
    );
    req.on('error', reject);
    if (body) req.write(body);
    req.end();
  });
}

async function listLessonDocs(accessToken, courseId) {
  const parent = `projects/${PROJECT_ID}/databases/(default)/documents/courses/${courseId}/lessons`;
  try {
    const res = await requestJson(
      'GET',
      `/v1/${parent}?pageSize=300`,
      accessToken,
    );
    return res.documents || [];
  } catch (_) {
    return [];
  }
}

async function deleteDoc(accessToken, name) {
  await requestJson(
    'DELETE',
    `/v1/${name}`,
    accessToken,
  );
}

async function upsertCourse(accessToken, course) {
  const { id, lessons = [], ...meta } = course;
  const coursePath = `projects/${PROJECT_ID}/databases/(default)/documents/courses/${id}`;

  // Delete existing lessons
  const existing = await listLessonDocs(accessToken, id);
  for (const doc of existing) {
    await deleteDoc(accessToken, doc.name);
  }

  await requestJson(
    'PATCH',
    `/v1/${coursePath}?currentDocument.exists=false`.replace(
      'currentDocument.exists=false',
      '',
    ),
    accessToken,
    documentFromObject(meta),
  );
  // PATCH create-or-update
  await requestJson(
    'PATCH',
    `/v1/${coursePath}`,
    accessToken,
    documentFromObject(meta),
  );

  for (const lesson of lessons) {
    const lessonId = lesson.id;
    const { id: _omit, ...lessonBody } = lesson;
    const lessonPath = `${coursePath}/lessons/${lessonId}`;
    await requestJson(
      'PATCH',
      `/v1/${lessonPath}`,
      accessToken,
      documentFromObject(lessonBody),
    );
  }

  console.log(
    `✅ ${id} (${lessons.length} lessons, track=${meta.track || '?'})`,
  );
}

async function main() {
  if (!fs.existsSync(SEED_PATH)) {
    console.error('Missing scripts/courses_seed.json — run export first.');
    process.exit(1);
  }

  const seed = JSON.parse(fs.readFileSync(SEED_PATH, 'utf8'));
  let courses = seed.courses || [];

  // Optional filter: COURSE_ID=harmonyos-kits node scripts/upload_courses.js
  // Uploads only the matching course so other courses' Firestore data is left intact.
  const onlyId = process.env.COURSE_ID;
  if (onlyId) {
    courses = courses.filter((c) => c.id === onlyId);
    if (courses.length === 0) {
      console.error(`No course with id "${onlyId}" in seed.`);
      process.exit(1);
    }
    console.log(`Filtered to course "${onlyId}".`);
  }
  console.log(`Uploading ${courses.length} course(s) to ${PROJECT_ID}…`);

  // Preferred: a ready access token (e.g. ACCESS_TOKEN=$(gcloud auth print-access-token)).
  let accessToken = process.env.ACCESS_TOKEN;
  if (!accessToken) {
    const tokens = loadCliAccessToken();
    if (!tokens) {
      console.error(
        'No token. Set ACCESS_TOKEN=$(gcloud auth print-access-token) or run: firebase login',
      );
      process.exit(1);
    }
    accessToken = tokens.access_token;
    const expiresAt = Number(tokens.expires_at || 0);
    if (!accessToken || Date.now() > expiresAt - 60_000) {
      accessToken = await refreshAccessToken(tokens);
    }
  }

  for (const course of courses) {
    await upsertCourse(accessToken, course);
  }

  console.log('Done.');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
