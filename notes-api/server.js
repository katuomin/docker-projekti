const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

const pool = new Pool({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    port: process.env.DB_PORT,
});

const initDb = async () => {
    try {
        await pool.query(`
            CREATE TABLE IF NOT EXISTS notes (
                id SERIAL PRIMARY KEY,
                content TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        `);
        console.log("db ready!!!");
    } catch (err) {
        console.error("failed init db!!!", err);
        setTimeout(initDb, 5000);
    }
};
initDb();

// API: Hae kaikki muistiinpanot
app.get('/api/notes', async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM notes ORDER BY created_at DESC');
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// API: Tallenna uusi muistiinpano
app.post('/api/notes', async (req, res) => {
    try {
        const { content } = req.body;
        
        const result = await pool.query(`INSERT INTO notes (content) VALUES ($1) RETURNING *`, [content]);
        
        res.status(201).json(result.rows);
    } catch (err) {
        console.error("Virhe tallennuksessa:", err.message);
        res.status(500).json({ error: err.message });
    }
});

// API: Muokkaa olemassa olevaa muistiinpanoa
app.put('/api/notes/:id', async (req, res) => {
    try {
        const { content } = req.body;

        const result = await pool.query(
            `UPDATE notes SET content = $1 WHERE id = $2 RETURNING *`,
            [content, req.params.id]
        );

        // Jos rivin määrä on 0, id:llä ei ole vastaavaa muistiinpanoa
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Muistiinpanoa ei löytynyt' });
        }

        res.json(result.rows);
    } catch (err) {
        console.error("Virhe muokkauksessa:", err.message);
        res.status(500).json({ error: err.message });
    }
});

// API: Poista muistiinpano
app.delete('/api/notes/:id', async (req, res) => {
    try {
        const result = await pool.query('DELETE FROM notes WHERE id = $1 RETURNING id', [req.params.id]);

        // Jos rivin määrä on 0, id:llä ei ole vastaavaa muistiinpanoa
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Muistiinpanoa ei löytynyt' });
        }

        res.json({ deleted: result.rows.length });
    } catch (err) {
        console.error("Virhe poistossa:", err.message);
        res.status(500).json({ error: err.message });
    }
});

// API: Healthcheck
app.get('/health', (req, res) => res.json({ status: 'ok' }));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`API  ${PORT}`));
