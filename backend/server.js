// Nature Vision Backend - Express.js Beispiel
// Installieren: npm init -y && npm install express cors body-parser

const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(bodyParser.json({ limit: '50mb' }));
app.use(bodyParser.urlencoded({ limit: '50mb', extended: true }));
app.use(express.static(path.join(__dirname, 'public')));

// ─── In-Memory Database (nur für Demo, verwende MongoDB/PostgreSQL in Production) ────────

const users = new Map();  // userId -> user data
const mementos = new Map(); // id -> memento data
const analytics = [];
const sessions = [];  // Session logs
const events = [];    // Event logs

// ─── Health Check ────────────────────────────────────────────────────────

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', message: 'Backend is running' });
});

// ─── Users Endpoints ────────────────────────────────────────────────────

app.post('/api/users/register', (req, res) => {
  const { name, deviceId, userId } = req.body;

  if (!name || !deviceId || !userId) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  const user = {
    userId,
    deviceId,
    name,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };

  users.set(userId, user);

  res.status(201).json({
    message: 'User registered successfully',
    user,
  });
});

app.get('/api/users/profile', (req, res) => {
  const userId = req.get('X-User-ID');
  const deviceId = req.get('X-Device-ID');

  if (!userId || !deviceId) {
    return res.status(401).json({ error: 'Missing auth headers' });
  }

  const user = users.get(userId);

  if (!user) {
    return res.status(404).json({ error: 'User not found' });
  }

  res.json(user);
});

// ─── Mementos Endpoints ────────────────────────────────────────────────

app.post('/api/mementos', (req, res) => {
  const userId = req.get('X-User-ID');
  const { prompt, photoPath, note, date } = req.body;

  if (!userId) {
    return res.status(401).json({ error: 'Missing X-User-ID header' });
  }

  if (!prompt || !date) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  const id = `memento_${Date.now()}`;
  const memento = {
    id,
    userId,
    prompt,
    photoPath,
    note,
    date,
    createdAt: new Date().toISOString(),
  };

  mementos.set(id, memento);

  res.status(201).json({
    message: 'Memento created',
    memento,
  });
});

app.get('/api/mementos', (req, res) => {
  const userId = req.get('X-User-ID');

  if (!userId) {
    return res.status(401).json({ error: 'Missing X-User-ID header' });
  }

  const userMementos = Array.from(mementos.values()).filter(m => m.userId === userId);

  res.json(userMementos);
});

app.patch('/api/mementos/:id', (req, res) => {
  const userId = req.get('X-User-ID');
  const { id } = req.params;
  const { prompt, note, date } = req.body;

  if (!userId) {
    return res.status(401).json({ error: 'Missing X-User-ID header' });
  }

  const memento = mementos.get(id);

  if (!memento || memento.userId !== userId) {
    return res.status(404).json({ error: 'Memento not found' });
  }

  memento.prompt = prompt || memento.prompt;
  memento.note = note !== undefined ? note : memento.note;
  memento.date = date || memento.date;
  memento.updatedAt = new Date().toISOString();

  res.json({
    message: 'Memento updated',
    memento,
  });
});

app.delete('/api/mementos/:id', (req, res) => {
  const userId = req.get('X-User-ID');
  const { id } = req.params;

  if (!userId) {
    return res.status(401).json({ error: 'Missing X-User-ID header' });
  }

  const memento = mementos.get(id);

  if (!memento || memento.userId !== userId) {
    return res.status(404).json({ error: 'Memento not found' });
  }

  mementos.delete(id);

  res.json({ message: 'Memento deleted' });
});

// ─── Analytics Endpoints ────────────────────────────────────────────────

app.post('/api/analytics', (req, res) => {
  const userId = req.get('X-User-ID');
  const { date, appOpens, totalSeconds, streak, mementoCount } = req.body;

  if (!userId) {
    return res.status(401).json({ error: 'Missing X-User-ID header' });
  }

  const record = {
    userId,
    date,
    appOpens,
    totalSeconds,
    streak,
    mementoCount,
    recordedAt: new Date().toISOString(),
  };

  analytics.push(record);

  res.status(201).json({
    message: 'Analytics recorded',
    record,
  });
});

app.get('/api/analytics', (req, res) => {
  const userId = req.get('X-User-ID');

  if (!userId) {
    return res.status(401).json({ error: 'Missing X-User-ID header' });
  }

  const userAnalytics = analytics.filter(a => a.userId === userId);

  res.json(userAnalytics);
});

// ─── Sessions Endpoints ────────────────────────────────────────────────

app.post('/api/sessions/start', (req, res) => {
  const userId = req.get('X-User-ID');
  const { deviceId } = req.body;

  if (!userId || !deviceId) {
    return res.status(400).json({ error: 'Missing userId or deviceId' });
  }

  const session = {
    sessionId: `session_${Date.now()}`,
    userId,
    deviceId,
    startTime: new Date().toISOString(),
    endTime: null,
    duration: null,
    events: [],
  };

  sessions.push(session);

  res.status(201).json({
    message: 'Session started',
    sessionId: session.sessionId,
  });
});

app.post('/api/sessions/end', (req, res) => {
  const userId = req.get('X-User-ID');
  const { sessionId } = req.body;

  if (!userId || !sessionId) {
    return res.status(400).json({ error: 'Missing userId or sessionId' });
  }

  const session = sessions.find(s => s.sessionId === sessionId && s.userId === userId);

  if (!session) {
    return res.status(404).json({ error: 'Session not found' });
  }

  const endTime = new Date();
  session.endTime = endTime.toISOString();
  session.duration = Math.round((endTime - new Date(session.startTime)) / 1000); // in seconds

  res.json({
    message: 'Session ended',
    session,
  });
});

// ─── Events Endpoints ────────────────────────────────────────────────────

app.post('/api/events', (req, res) => {
  const userId = req.get('X-User-ID');
  const { sessionId, eventType, data } = req.body;

  if (!userId || !sessionId || !eventType) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  const event = {
    eventId: `event_${Date.now()}`,
    userId,
    sessionId,
    eventType, // 'prompt_viewed', 'photo_taken', 'note_added', 'memento_saved', 'app_paused'
    timestamp: new Date().toISOString(),
    data, // Additional data (prompt text, image path, etc.)
  };

  events.push(event);

  // Add event to session
  const session = sessions.find(s => s.sessionId === sessionId);
  if (session) {
    session.events.push(event);
  }

  res.status(201).json({
    message: 'Event logged',
    event,
  });
});

// ─── Admin API ────────────────────────────────────────────────────────

app.get('/api/admin/sessions', (req, res) => {
  res.json({
    totalSessions: sessions.length,
    sessions: sessions.sort((a, b) => new Date(b.startTime) - new Date(a.startTime)),
  });
});

app.get('/api/admin/sessions/:userId', (req, res) => {
  const { userId } = req.params;

  const userSessions = sessions.filter(s => s.userId === userId)
    .sort((a, b) => new Date(b.startTime) - new Date(a.startTime));

  res.json({
    userId,
    totalSessions: userSessions.length,
    sessions: userSessions,
  });
});

app.get('/api/admin/events', (req, res) => {
  res.json({
    totalEvents: events.length,
    events: events.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp)),
  });
});

app.get('/api/admin/events/:userId', (req, res) => {
  const { userId } = req.params;

  const userEvents = events.filter(e => e.userId === userId)
    .sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));

  res.json({
    userId,
    totalEvents: userEvents.length,
    events: userEvents,
  });
});

app.get('/api/admin/users', (req, res) => {
  const usersList = Array.from(users.values()).map(user => ({
    userId: user.userId,
    name: user.name,
    createdAt: user.createdAt,
    sessionCount: sessions.filter(s => s.userId === user.userId).length,
    eventCount: events.filter(e => e.userId === user.userId).length,
  }));

  res.json({
    totalUsers: usersList.length,
    users: usersList,
  });
});

// ─── Admin Dashboard ────────────────────────────────────────────────────

app.get('/admin', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'admin.html'));
});

// ─── Dev: Seed demo data (GET for convenience in local dev) ─────────────────
app.get('/api/admin/seed', (req, res) => {
  const demoUserId = 'demo_user_1';
  const demoDeviceId = 'demo_device_1';

  if (!users.has(demoUserId)) {
    users.set(demoUserId, {
      userId: demoUserId,
      deviceId: demoDeviceId,
      name: 'Demo User',
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    });
  }

  const session = {
    sessionId: `session_demo_${Date.now()}`,
    userId: demoUserId,
    deviceId: demoDeviceId,
    startTime: new Date().toISOString(),
    endTime: null,
    duration: null,
    events: [],
  };

  sessions.push(session);

  const ev1 = {
    eventId: `event_demo_${Date.now()}_1`,
    userId: demoUserId,
    sessionId: session.sessionId,
    eventType: 'prompt_viewed',
    timestamp: new Date().toISOString(),
    data: { prompt: 'Describe the sky' },
  };

  const ev2 = {
    eventId: `event_demo_${Date.now()}_2`,
    userId: demoUserId,
    sessionId: session.sessionId,
    eventType: 'photo_taken',
    timestamp: new Date().toISOString(),
    data: { photoPath: '/tmp/demo1.jpg' },
  };

  events.push(ev1, ev2);
  session.events.push(ev1, ev2);

  res.json({ message: 'Demo seed created', sessionId: session.sessionId, events: [ev1.eventId, ev2.eventId] });
});

// ─── Start Server ────────────────────────────────────────────────────────

app.listen(PORT, () => {
  console.log(`🌿 Nature Vision Backend running on http://localhost:${PORT}`);
  console.log(`📍 API Base URL: http://localhost:${PORT}/api`);
  console.log(`📊 Admin Dashboard: http://localhost:${PORT}/admin`);
});

