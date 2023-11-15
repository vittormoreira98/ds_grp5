require('dotenv').config();
const express = require('express');
const app = express();

const sql = require('mssql');

app.use(express.json()); // Para lidar com JSON payloads

const port = 3000;
app.listen(port, () => {
    console.log(`Servidor rodando na porta ${port}`);
});

const dbConfig = {
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    server: process.env.DB_SERVER, 
    database: process.env.DB_DATABASE,
    options: {
        encrypt: false, // Se estiver usando o Azure SQL
        trustServerCertificate: true // Apenas para desenvolvimento local
    }
};

app.post('/virar-carta', async (req, res) => {
    try {
        await sql.connect(dbConfig);

        const request = new sql.Request();

        // Configurar os parâmetros de entrada
        request.input('id_carta', sql.Int, req.body.id_carta);
        request.input('cd_usuario', sql.VarChar(100), req.body.cd_usuario);
        request.input('id_partida', sql.Int, req.body.id_partida);

        // Configurar os parâmetros de saída
        request.output('fl_virar_carta', sql.Bit);
        request.output('cd_retorno', sql.Int);
        request.output('nm_retorno', sql.VarChar(sql.MAX));
        request.output('nr_versao_proc', sql.VarChar(15));

        // Executar a stored procedure
        const result = await request.execute('dbo.p_virar_carta_jogo_memoria');

        // Capturar os valores dos parâmetros de saída
        res.json({
            fl_virar_carta: result.output.fl_virar_carta,
            cd_retorno: result.output.cd_retorno,
            nm_retorno: result.output.nm_retorno,
            nr_versao_proc: result.output.nr_versao_proc
        });
    } catch (err) {
        res.status(500).send(err.message);
    }
});








