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
    const { nomeDaSala, numeroJogadores } = req.body;

    try {
        const request = new sql.Request();

        request.input('nm_sala', sql.VarChar, nomeDaSala);
        request.input('nr_jogadores', sql.Int, numeroJogadores);
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

//app.post('/virar-carta', async (req, res) => {
//	try {

//		const request = new sql.Request();

//		// Configurar os parâmetros de entrada
//		request.input('id_carta', sql.Int, req.body.id_carta);
//		request.input('cd_usuario', sql.VarChar(100), req.body.cd_usuario);
//		request.input('id_partida', sql.Int, req.body.id_partida);

//		// Configurar os parâmetros de saída
//		request.output('fl_virar_carta', sql.Bit);
//		request.output('cd_retorno', sql.Int);
//		request.output('nm_retorno', sql.VarChar(sql.MAX));
//		request.output('nr_versao_proc', sql.VarChar(15));

//		// Executar a stored procedure
//		const result = await request.execute('dbo.p_virar_carta_jogo_memoria');

//		// Capturar os valores dos parâmetros de saída
//		res.json({
//			fl_virar_carta: result.output.fl_virar_carta,
//			cd_retorno: result.output.cd_retorno,
//			nm_retorno: result.output.nm_retorno,
//			nr_versao_proc: result.output.nr_versao_proc
//		});
//	} catch (err) {
//		res.status(500).send(err.message);
//	}
//});

app.post('/virar-carta', async (req, res) => {
    const { id_carta, id_apelido, id_sala } = req.body;

    try {
        const request = new sql.Request();
        // Configurar parâmetros da requisição
        request.input('id_carta', sql.Int, id_carta);
        request.input('id_apelido', sql.Int, id_apelido);
        request.input('id_sala', sql.Int, id_sala);
        request.output('cd_retorno', sql.Int);
        request.output('nm_retorno', sql.VarChar(255));
        request.output('pontuacao', sql.Int);
        request.output('jogofinalizado', sql.Bit);

        const resultado = await request.execute('dbo.p_virar_carta_jogo_memoria');

        if (resultado.output.cd_retorno !== 0) {
            res.json({
				cd_retorno: resultado.output.cd_retorno,
				nm_retorno: resultado.output.nm_retorno,
				pontuacao: resultado.output.pontuacao, // Adicionar campo de pontuação
				jogofinalizado: resultado.output.jogofinalizado // Adicionar campo para indicar o fim do jogo
			 });
        } else {
            res.json({
				cd_retorno: resultado.output.cd_retorno,
				nm_retorno: resultado.output.nm_retorno, 
				pontuacao: resultado.output.pontuacao, // Adicionar campo de pontuação
				jogofinalizado: resultado.output.jogofinalizado, // Adicionar campo para indicar o fim do jogo
				cartas: resultado.recordset });
        }
    } catch (err) {
        console.error(err);
        res.status(500).json({ erro: err.message });
    }
});

app.get('/obter-ranking', async (req, res) => {
    const { id_sala } = req.query;

    try {
        const request = new sql.Request();
        request.input('id_sala', sql.Int, id_sala);
        request.output('cd_retorno', sql.Int);
        request.output('nm_retorno', sql.VarChar(255));

        const resultado = await request.execute('dbo.p_obter_ranking_jogadores');
		
        if (resultado.output.cd_retorno !== 0) {
            res.status(500).json({ mensagem: resultado.output.nm_retorno });
			
        } else {
            res.json(resultado.recordset);
        }
    } catch (err) {
        console.error(err);
        res.status(500).send({ mensagem: "Erro ao obter ranking", erro: err });
    }
});

app.post('/iniciar-jogo', async (req, res) => {
    try {
        const { id_apelido, id_sala } = req.body;
        const request = new sql.Request();

        request.input('id_apelido', sql.Int, id_apelido);
        request.input('id_sala', sql.Int, id_sala);
        request.output('cd_retorno', sql.Int);
        request.output('nm_retorno', sql.VarChar(255)); // Corrigido aqui


        // Chama a stored procedure para embaralhar as cartas
        const resultado = await request.execute('dbo.p_listar_cartas'); // Corrigido aqui
        

        // Verifica se todos os jogadores na sala estão prontos
        const resultadoProntidao = await request.query(`
            SELECT COUNT(*) as totalJogadores, 
                   SUM(CASE WHEN fl_pronto = 1 THEN 1 ELSE 0 END) as jogadoresProntos 
            FROM dbo.t_status_jogador_sala 
            WHERE id_sala = @id_sala
        `);

        const todosProntos = resultadoProntidao.recordset[0].totalJogadores === resultadoProntidao.recordset[0].jogadoresProntos;

        if (resultado.output.cd_retorno == 0 && todosProntos){
            res.json({ cd_retorno: 0,nm_retorno: resultado.output.nm_retorno, todosJogadoresProntos: true });
        } else {
            res.json({ cd_retorno: resultado.output.cd_retorno, nm_retorno: resultado.output.nm_retorno,todosJogadoresProntos: false });
        }
    } catch (err) {
        res.status(500).send({ mensagem: "Erro ao iniciar o jogo", erro: err });
    }
});


app.post('/marcar-pronto', async (req, res) => {
    try {
        const { id_apelido, id_sala } = req.body;
        const request = new sql.Request();

        request.input('id_apelido', sql.Int, id_apelido);
        request.input('id_sala', sql.Int, id_sala);

        await request.query(`
            update t set
            	fl_pronto = 1, dt_atualizacao = GETDATE() 
			from
				dbo.t_status_jogador_sala t
            where
				t.id_apelido = @id_apelido
				and t.id_sala = @id_sala
        `);
		
        res.json({ mensagem: "Estado atualizado com sucesso" });
    } catch (err) {
        res.status(500).send({ mensagem: "Erro ao atualizar estado", erro: err });
    }
});

app.get('/verificar-prontidao', async (req, res) => {
    try {
        const { id_sala } = req.query;
        const request = new sql.Request();

        request.input('id_sala', sql.Int, id_sala);

        const resultado = await request.query(`
            SELECT COUNT(*) as totalJogadores, 
                   SUM(CASE WHEN fl_pronto = 1 THEN 1 ELSE 0 END) as jogadoresProntos 
            FROM t_status_jogador_sala 
            WHERE id_sala = @id_sala
        `);

        const todosProntos = resultado.recordset[0].totalJogadores === resultado.recordset[0].jogadoresProntos;

        res.json({ todosJogadoresProntos: todosProntos });
    } catch (err) {
        res.status(500).send({ mensagem: "Erro ao verificar prontidão", erro: err });
    }
});

