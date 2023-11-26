require('dotenv').config();
const express = require('express');
const cors = require('cors');
const app = express();

const sql = require('mssql');
app.use(cors()); // Isso irá habilitar o CORS para todas as rotas e origens

app.use(express.json()); // Para lidar com JSON payloads

const port = process.env.PORT || 3000;
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

app.use((req, res, next) => {
	res.header('Cache-Control', 'no-cache, no-store, must-revalidate');
	res.header('Pragma', 'no-cache');
	res.header('Expires', '0');
	next();
});

app.post('/incluir-apelido', async (req, res) => {
	try {
		await sql.connect(dbConfig);

		const request = new sql.Request();

		// Configurar os parâmetros de entrada
		request.input('nm_apelido', sql.VarChar(50), req.body.nm_apelido);

		// Configurar os parâmetros de saída
		request.output('id_apelido', sql.Int);
		request.output('cd_retorno', sql.Int);
		request.output('nm_retorno', sql.VarChar(sql.MAX));
		request.output('nr_versao_proc', sql.VarChar(15));

		// Executar a stored procedure
		const result = await request.execute('dbo.p_incluir_apelido_jogo_memoria');

		// Capturar os valores dos parâmetros de saída
		res.json({
			id_apelido: result.output.id_apelido,
			cd_retorno: result.output.cd_retorno,
			nm_retorno: result.output.nm_retorno,
			nr_versao_proc: result.output.nr_versao_proc
		});
	} catch (err) {
		res.status(500).send(err.message);
	}
});

app.get('/listar-salas', async (req, res) => {
    try {
        const resultado = await sql.query('exec dbo.p_listar_salas_disponiveis');
        res.json(resultado.recordset);
    } catch (err) {
        res.status(500).send({ mensagem: "Erro ao listar salas", erro: err });
    }
});

app.post('/entrar-sala', async (req, res) => {
    const { idSala, idJogador } = req.body;
    try {
        const resultado = await sql.query('exec dbo.p_entrar_sala @id_sala, @id_jogador', [idSala, idJogador]);
        res.json(resultado.recordset);
    } catch (err) {
        res.status(500).send({ mensagem: "Erro ao entrar na sala", erro: err });
    }
});



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









