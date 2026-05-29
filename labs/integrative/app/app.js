const express = require('express');
const mysql = require('mysql2/promise');

const app = express();
const PORT = process.env.PORT || 3000;
const MEM_LIMIT_MB = parseInt(process.env.MEM_LIMIT_MB || '256', 10);
const DB_CONFIG = {
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'appdb',
};

let pool;

async function initDB() {
  try {
    pool = mysql.createPool(DB_CONFIG);
    await pool.query(`
      CREATE TABLE IF NOT EXISTS usuarios (
        id INT AUTO_INCREMENT PRIMARY KEY,
        nombre VARCHAR(100) NOT NULL,
        email VARCHAR(100) NOT NULL,
        creado TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    const [rows] = await pool.query('SELECT COUNT(*) AS count FROM usuarios');
    if (rows[0].count === 0) {
      await pool.query("INSERT INTO usuarios (nombre, email) VALUES ('Admin', 'admin@example.com')");
      await pool.query("INSERT INTO usuarios (nombre, email) VALUES ('Usuario1', 'user1@example.com')");
    }
    console.log('DB conectada e inicializada');
  } catch (err) {
    console.error('Error conectando a DB:', err.message);
    console.log('App arranca sin DB (solo healthcheck)');
  }
}

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', uptime: process.uptime() });
});

app.get('/usuarios', async (_req, res) => {
  if (!pool) {
    return res.status(503).json({ error: 'DB no disponible' });
  }
  try {
    const [rows] = await pool.query('SELECT id, nombre, email FROM usuarios');
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/mem', (_req, res) => {
  const used = process.memoryUsage();
  res.json({
    rss: Math.round(used.rss / 1024 / 1024) + 'MB',
    heapTotal: Math.round(used.heapTotal / 1024 / 1024) + 'MB',
    heapUsed: Math.round(used.heapUsed / 1024 / 1024) + 'MB',
    limit: MEM_LIMIT_MB + 'MB',
  });
});

app.get('/leak', (_req, res) => {
  const leak = [];
  setInterval(() => {
    leak.push(Buffer.alloc(10 * 1024 * 1024));
  }, 500);
  res.json({ message: 'Memory leak iniciado (10MB cada 500ms)' });
});

app.get('/', (_req, res) => {
  res.json({
    service: 'App PYME',
    status: 'running',
    endpoints: {
      health: '/health',
      usuarios: '/usuarios',
      mem: '/mem',
      leak: '/leak',
    },
  });
});

async function start() {
  await initDB();
  app.listen(PORT, () => {
    console.log(`App corriendo en puerto ${PORT}`);
    console.log(`Limite de memoria: ${MEM_LIMIT_MB}MB`);
  });
}

start();
