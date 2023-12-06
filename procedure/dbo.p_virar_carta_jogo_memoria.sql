if exists (select top 1 1 from dbo.sysobjects where id = object_id(N'dbo.p_virar_carta_jogo_memoria') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop procedure dbo.p_virar_carta_jogo_memoria
go
create procedure dbo.p_virar_carta_jogo_memoria
(
	@id_carta					int				= null,
	@id_apelido					int				= null,
	@id_sala					int				= null,
	@debug						bit				= null,
	
	@jogofinalizado 			bit				= null output,
	@pontuacao					int				= null output,
	@cd_retorno					int				= null output,
	@nm_retorno					varchar(255)	= null output,
	@nr_versao_proc				varchar(15)		= null output
)
as begin
/*
***********************************************************************************************************************************************************************************
	* autor..................: Vitor Moreira
	* objetivo...............: Ser chamada para virar carta de jogo da memória, controlando a pontuação do jogador, definir se ele acertou ou errou, e se ganhou o jogo.
	Ela também deve controlar quais cartas devem ser exibidas ou ocultadas para cada jogador.
	* criação................: 03/12/2023
	* exemplo de chamada.....: 
declare @cd_retorno int, @nm_retorno varchar(max),@nr_versao_proc varchar(15)
exec dbo.p_virar_carta_jogo_memoria
	@id_carta		= 1,
	@id_apelido		= 1,
	@id_sala		= 1,
	@cd_retorno		= @cd_retorno output,
	@nm_retorno		= @nm_retorno output,
	@nr_versao_proc	= @nr_versao_proc output
select '@cd_retorno' = @cd_retorno, '@nm_retorno' = @nm_retorno, '@nr_versao_proc' = @nr_versao_proc
	* histórico..............: 
	* 
***********************************************************************************************************************************************************************************
*/
begin try
	set nocount on
	set xact_abort on
	set transaction isolation level read uncommitted 

	set @nr_versao_proc = ltrim(rtrim(replace(replace('$Revision: 1.0 $','Revision:',''),'$','')))
	declare @nm_proc varchar(200) = 'dbo.p_virar_carta_jogo_memoria'
	
	/*Declarando variaveis internas*/
	begin
		declare	@dt_sistema					datetime	= getdate(),
				@fl_acertou					bit 		= 0,
				@id_carta_virada_rodada_1	int 		= 0,
				@nr_carta_virada_rodada_1	int 		= 0,
				@nr_carta_virada_rodada_2	int 		= 0
		
		/*Controle de pontuação*/
		declare	@tempoiniciojogo		datetime,
				@tempoatual 			datetime		= getdate(),
				@tempototaljogo			int				= 90 * 1000, /*Tempo total do jogo em milissegundos (90 segundos)*/
				@tempopassado			int
	end

	insert into dbo.debug (nm_campo,vl_campo,dt_sistema) values 
	('linha50','linha50',@dt_sistema),
	('@id_carta',convert(varchar(max),@id_carta),@dt_sistema),
	('@id_apelido',convert(varchar(max),@id_apelido),@dt_sistema),
	('@id_sala',convert(varchar(max),@id_sala),@dt_sistema)

	/*Pré validações*/
	begin
		if @id_carta is null
		begin
			select @cd_retorno = 1, @nm_retorno = 'O parâmetro @id_carta é obrigatório'
			raiserror(@nm_retorno, 16, 1)
		end

		if @id_apelido is null
		begin
			select @cd_retorno = 2, @nm_retorno = 'O parâmetro @id_apelido é obrigatório'
			raiserror(@nm_retorno, 16, 1)
		end

		if @id_sala is null
		begin
			select @cd_retorno = 3, @nm_retorno = 'O parâmetro @id_sala é obrigatório'
			raiserror(@nm_retorno, 16, 1)
		end

		if not exists(select top 1 1 from dbo.t_apelido_jogo_memoria t where t.id_apelido = @id_apelido)
		begin
			select @cd_retorno = 19, @nm_retorno = 'O parâmetro @id_apelido não foi encontrado'
			raiserror(@nm_retorno, 16, 1)
		end

		if not exists(select top 1 1 from dbo.t_sala_jogo_memoria t where t.id_sala = @id_sala)
		begin
			select @cd_retorno = 20, @nm_retorno = 'O parâmetro @id_sala não foi encontrado'
			raiserror(@nm_retorno, 16, 1)
		end

		if not exists(select top 1 1 from dbo.t_apelido_sala_cartas t where t.id_apelido = @id_apelido and t.id_sala = @id_sala and t.id_carta = @id_carta)
		begin
			select @cd_retorno = 21, @nm_retorno = 'O parâmetro @id_carta não foi encontrado'
			raiserror(@nm_retorno, 16, 1)
		end

	end

	/*Criando tabelas temporarias*/
	begin
		if object_id('tempdb..#t_apelido_sala_cartas_pvcjm') is not null
			drop table #t_apelido_sala_cartas_pvcjm
		create table #t_apelido_sala_cartas_pvcjm
		(
			id_apelido_sala_cartas		int				not null,
			id_apelido					int				not null,
			id_sala						int				not null,
			id_carta					int				not null,
			nr_imagem					int				not null,
			fl_carta_virada_rodada		bit				not null,
			fl_carta_virada_acerto		bit				not null
		)

	end

	/*Definindo valores para variáveis de controle de pontuação*/
	begin
		select @jogofinalizado = 0, @pontuacao = 0
		/*Obter o tempo de início do jogo para o jogador*/
		select
			@tempoiniciojogo = t.dt_inicio_jogo
		from
			dbo.t_apelido_sala t
		where
			t.id_apelido = @id_apelido
			and t.id_sala = @id_sala
	end

	/*Inserindo dados nas tabelas temporarias*/
	begin
		insert into #t_apelido_sala_cartas_pvcjm
			(id_apelido_sala_cartas,id_apelido,id_sala,id_carta,nr_imagem,fl_carta_virada_rodada,fl_carta_virada_acerto)
		select
			t.id_apelido_sala_cartas,
			t.id_apelido,
			t.id_sala,
			t.id_carta,
			t.nr_imagem,
			t.fl_carta_virada_rodada,
			t.fl_carta_virada_acerto
		from
			dbo.t_apelido_sala_cartas t
		where
			t.id_apelido = @id_apelido
			and t.id_sala = @id_sala
	end

	update t set
		fl_carta_virada_rodada = 1
	from
		#t_apelido_sala_cartas_pvcjm t
	where
		t.id_carta = @id_carta

	/*Conferindo carta virada na rodada 1 e 2*/
	begin
		if (select count(*) from #t_apelido_sala_cartas_pvcjm t where t.fl_carta_virada_rodada = 1) = 2
		begin
			select top 1
				@nr_carta_virada_rodada_1 = t.nr_imagem,
				@id_carta_virada_rodada_1 = t.id_carta
			from
				#t_apelido_sala_cartas_pvcjm t
			where
				t.fl_carta_virada_rodada = 1
				and t.id_carta <> @id_carta
				
			select top 1
				@nr_carta_virada_rodada_2 = t.nr_imagem
			from
				#t_apelido_sala_cartas_pvcjm t
			where
				t.id_carta = @id_carta
				and isnull(@id_carta_virada_rodada_1 ,0) <> 0
			
			if isnull(@id_carta_virada_rodada_1,0) <> 0
				select @fl_acertou = case when @nr_carta_virada_rodada_1 = @nr_carta_virada_rodada_2 then 1 else 0 end
		end
		
	end


	/*Atualizando controle*/
	begin
		if @fl_acertou = 1
		begin
			/*Quando acertar, marcar a flag de acerto nas duas cartas, e desmarcar a carta de carta virada na rodada*/
			update t set
				fl_carta_virada_acerto = 1,
				fl_carta_virada_rodada = 0
			from
				#t_apelido_sala_cartas_pvcjm t
			where
				t.id_carta in (@id_carta, @id_carta_virada_rodada_1)
		end
		
		if (select count(*) from #t_apelido_sala_cartas_pvcjm t where t.fl_carta_virada_rodada = 1) >= 3
		begin
			update t set
				fl_carta_virada_rodada = 0,
				fl_carta_virada_acerto = 0
			from
				#t_apelido_sala_cartas_pvcjm t
			where
				t.fl_carta_virada_rodada = 1
				and t.id_carta <> @id_carta
		end
	end

	update t set
		fl_carta_virada_rodada		= ta.fl_carta_virada_rodada,
		fl_carta_virada_acerto		= ta.fl_carta_virada_acerto
	from
		dbo.t_apelido_sala_cartas t
		inner join #t_apelido_sala_cartas_pvcjm ta
			on ta.id_apelido_sala_cartas = t.id_apelido_sala_cartas

	select
		t.id_carta,
		nr_carta	=
			case	when t.fl_carta_virada_rodada = 1 or t.fl_carta_virada_acerto = 1
						then t.nr_imagem
					else 0 end
	from
		#t_apelido_sala_cartas_pvcjm t
	
	/*Definindo fim do jogo*/
	begin
		/*Calcular o tempo passado desde o início do jogo*/
    	set @tempoPassado = datediff(millisecond, @tempoiniciojogo, @tempoatual)

		-- Verificar se todas as cartas foram acertadas
		if (select count(*) from dbo.t_apelido_sala_cartas t where t.id_apelido = @id_apelido and t.fl_carta_virada_acerto = 0) = 0
		begin
			set @jogofinalizado = 1

			/*Calcular a pontuação com base no tempo passado*/
			set @pontuacao = round((@tempototaljogo - @tempoPassado) * (1000.0 / @tempototaljogo), 0)
			
			update t set
				fl_jogo_finalizado		= @jogofinalizado,
				vl_pontuacao			= @pontuacao
			from
				dbo.t_apelido_sala t
			where
				t.id_apelido = @id_apelido
				and t.id_sala = @id_sala
		end
	end

	/*Definindo retorno com processamento efetuado com sucesso*/
	select	@cd_retorno = 0,
			@nm_retorno = 'Processamento efetuado com sucesso'
	

end try
begin catch
	set @cd_retorno =	1
	set @nm_retorno =	'Procedure : ' + isnull(@nm_proc,'') + ' - ' + 'Versão: ' + isnull(convert(varchar(20), @nr_versao_proc),'0') + ' - '
					+ case when @nm_proc <> isnull(error_procedure(),@nm_proc) then 'Erro na procedure: ' + error_procedure() else '' end
					+ 'Mensagem: ' + isnull(convert(varchar(300), error_message()), '')
					+ case when isnull(error_line(), 0) <> 0 then ' - Linha: ' + convert(varchar(max),error_line()) else '' end
	
end catch
end
