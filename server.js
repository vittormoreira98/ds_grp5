require('dotenv').config();
const express = require('express');
const cors = require('cors');
const app = express();

app.use(express.static('public')); // 'public' é a pasta onde seus arquivos HTML estão localizados

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

sql.connect(dbConfig)

app.use((req, res, next) => {
	res.header('Cache-Control', 'no-cache, no-store, must-revalidate');
	res.header('Pragma', 'no-cache');
	res.header('Expires', '0');
	next();
});

app.post('/incluir-apelido', async (req, res) => {
	try {
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

//app.post('/api/obter-id-apelido', async (req, res) => {
//    const { apelido } = req.body;

//    try {
//        const request = new sql.Request();
//        request.input('apelido', sql.VarChar, apelido);

//        const resultado = await request.query('SELECT id_apelido FROM tabelaApelidos WHERE nm_apelido = @apelido');

//        if (resultado.recordset.length > 0) {
//            res.json({ sucesso: true, id_apelido: resultado.recordset[0].id_apelido });
//        } else {
//            res.json({ sucesso: false, mensagem: "Apelido não encontrado." });
//        }
//    } catch (err) {
//        res.status(500).send({ mensagem: "Erro ao obter ID do apelido", erro: err.message });
//    }
//});


app.get('/listar-salas', async (req, res) => {
    try {
        const resultado = await sql.query('exec dbo.p_listar_salas_disponiveis');
        res.json(resultado.recordset);
    } catch (err) {
        res.status(500).send({ mensagem: "Erro ao listar salas", erro: err });
    }
});

app.post('/entrar-sala', async (req, res) => {
    const { idSala, idApelido } = req.body;
	
    try {
		const request = new sql.Request();
		
        request.input('id_sala', sql.Int, idSala);
		request.input('id_apelido', sql.Int, idApelido);
		request.output('cd_retorno', sql.Int);
		request.output('nm_retorno', sql.VarChar(sql.MAX));
		request.output('nr_versao_proc', sql.VarChar(15));

        const resultado = await request.execute('dbo.p_entrar_sala');
        
		// Acessando o cd_retorno
		const cdRetorno = resultado.output.cd_retorno;
		
		if (cdRetorno === 0) {
			// Sucesso
			res.json({ sucesso: true, mensagem: "Você conseguiu entrar numa sala." });
		} else {
			// Falha
			res.json({ sucesso: false, mensagem: resultado.output.nm_retorno });
		}
		
    } catch (err) {
        res.status(500).send({ mensagem: "Erro ao entrar na sala", erro: err });
    }
});

app.post('/cadastrar-sala', async (req, res) => {
    const { nomeDaSala, numeroJogadores, salaAberta } = req.body;

    try {
        const request = new sql.Request();

        request.input('nm_sala', sql.VarChar, nomeDaSala);
        request.input('nr_jogadores', sql.Int, numeroJogadores);
        request.input('fl_sala_aberta', sql.Bit, salaAberta);
		request.output('cd_retorno', sql.Int);
		request.output('nm_retorno', sql.VarChar(sql.MAX));
		request.output('nr_versao_proc', sql.VarChar(15));

        const resultado = await request.execute('dbo.p_incluir_sala_jogo_memoria');
		
		// Acessando o cd_retorno
		const cdRetorno = resultado.output.cd_retorno;

		if (cdRetorno === 0) {
			// Sucesso
			res.json({ sucesso: true, mensagem: "Sala criada com sucesso." });
		} else {
			// Falha
			res.json({ sucesso: false, mensagem: resultado.output.nm_retorno });
		}

		//// Capturar os valores dos parâmetros de saída
		//res.json({
		//	cd_retorno: result.output.cd_retorno,
		//	nm_retorno: result.output.nm_retorno,
		//	nr_versao_proc: result.output.nr_versao_proc
		//});

		//if (resultado.recordset && resultado.recordset.length > 0 && resultado.recordset[0].cd_retorno === 0) {
		//	res.json({ sucesso: true, mensagem: "Sala criada com sucesso." });
		//} else {
		//	// Lide com a situação onde recordset é undefined ou vazio
		//	res.json({ sucesso: false, mensagem: "Erro ao criar a sala. Detalhes: Recordset vazio ou indefinido." });
		//}
        
		//if (resultado.recordset[0].cd_retorno === 0) {
        //    res.json({ sucesso: true, mensagem: "Sala criada com sucesso." });
        //} else {
        //    res.json({ sucesso: false, mensagem: resultado.recordset[0].nm_retorno });
        //}

    } catch (err) {
        console.error('Erro ao tentar cadastrar sala:', err);
        res.status(500).send({ mensagem: "Erro ao criar sala", erro: err.message });
    }
});

app.post('/virar-carta', async (req, res) => {
	try {

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









