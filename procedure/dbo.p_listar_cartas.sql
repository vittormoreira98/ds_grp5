if exists (select top 1 1 from dbo.sysobjects where id = object_id(N'dbo.p_listar_cartas') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop procedure dbo.p_listar_cartas
go
create procedure dbo.p_listar_cartas
(
	@id_apelido					int				= null,
	@id_sala					int				= null,
	@debug						bit				= null,
	@cd_retorno					int				= null output,
	@nm_retorno					varchar(255)	= null output,
	@nr_versao_proc				varchar(15)		= null output
)
as begin
/*
***********************************************************************************************************************************************************************************
	* autor..................: Vitor Moreira
	* objetivo...............: Ser chamada para virar carta de jogo da memória, controlando a pontuação do jogador, definir se ele acertou ou errou, e se ganhou o jogo.
	* criação................: 14/11/2023
	* exemplo de chamada.....: 
declare @cd_retorno int, @nm_retorno varchar(max),@nr_versao_proc varchar(15)
exec dbo.p_listar_cartas
	@id_apelido	= 1,
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
	declare @nm_proc varchar(200) = 'dbo.p_listar_cartas'
	
	/*Declarando variaveis internas*/
	begin
		declare @dt_sistema 			datetime = getdate(),
				@nr_cartas_no_jogo		int = 18
	end

	insert into dbo.debug (nm_campo,vl_campo,dt_sistema) values 
	('linha47','linha47',@dt_sistema),
	('@id_apelido',convert(varchar(max),@id_apelido),@dt_sistema),
	('@id_sala',convert(varchar(max),@id_sala),@dt_sistema)

	/*Pré validações*/
	begin
		if @id_apelido is null
		begin
			select @cd_retorno = 15, @nm_retorno = 'O parâmetro @id_apelido é obrigatório'
			raiserror(@nm_retorno, 16, 1)
		end

		if @id_sala is null
		begin
			select @cd_retorno = 16, @nm_retorno = 'O parâmetro @id_sala é obrigatório'
			raiserror(@nm_retorno, 16, 1)
		end
		
		if not exists(select top 1 1 from dbo.t_apelido_jogo_memoria t where t.id_apelido = @id_apelido)
		begin
			select @cd_retorno = 17, @nm_retorno = 'O parâmetro @id_apelido não existe na tabela dbo.t_apelido_jogo_memoria'
			raiserror(@nm_retorno, 16, 1)
		end

		if not exists(select top 1 1 from dbo.t_apelido_jogo_memoria t where t.id_apelido = @id_apelido)
		begin
			select @cd_retorno = 17, @nm_retorno = 'O parâmetro @id_apelido não existe na tabela dbo.t_apelido_jogo_memoria'
			raiserror(@nm_retorno, 16, 1)
		end

		if not exists(select top 1 1 from dbo.t_sala_jogo_memoria t where t.id_sala = @id_sala)
		begin
			select @cd_retorno = 18, @nm_retorno = 'O parâmetro @id_sala não existe na tabela dbo.t_sala_jogo_memoria'
			raiserror(@nm_retorno, 16, 1)
		end
	end


	/*Criando tabelas temporarias*/
	begin
		if object_id('tempdb..#t_apelido_sala_cartas') is not null
			drop table #t_apelido_sala_cartas
		create table #t_apelido_sala_cartas
		(
			id_apelido					int				not null,
			id_sala						int				not null,
			id_carta					int				not null,
			nr_imagem					int				not null
		)

		if object_id('tempdb..#t_cartas') is not null
			drop table #t_cartas
		create table #t_cartas
		(
			id_carta					int				not null,
			fl_metade					bit				not null	default(0),
			nr_imagem					int				null
		)
	end

	/*Populando tabelas temporárias*/
	begin
		/*Populando #t_cartas*/
		begin
			;with cte_cartas as(
				select top (@nr_cartas_no_jogo) 
					id_carta		= row_number() over (order by (select null))
				from
					sys.all_columns a
					cross join sys.all_columns b)
			insert into #t_cartas (id_carta)
			select id_carta from cte_cartas;

			/*Atualiza #t_cartas.fl_metade = 1 na primeira metade dos registros na tabela #t_cartas*/
			update #t_cartas set fl_metade = 1 where id_carta <= @nr_cartas_no_jogo/2

			/*Preenchendo o campo nr_imagem na tabela #t_cartas, ela deve ser um sequencial com metade do tamanho do @nr_cartas_no_jogo,
			cada número deve se repetir 2 vezes, e a diposição dos números deve ser aleatória*/
			;with cte as(
				select
					id_carta,
					nr_imagem = row_number() over (partition by fl_metade order by newid())
				from
					#t_cartas)
			update t set
				nr_imagem = cte.nr_imagem
			from
				#t_cartas t
				inner join cte on
					cte.id_carta = t.id_carta
			where
				t.nr_imagem is null;
		end

		/*Populando #t_apelido_sala_cartas*/
		begin
			insert into #t_apelido_sala_cartas (id_apelido,id_sala,id_carta,nr_imagem)
			select
				id_apelido		= @id_apelido,
				id_sala			= @id_sala,
				id_carta		= t.id_carta,
				nr_imagem		= t.nr_imagem
			from
				#t_cartas t
		end

		if object_id('tempdb..#t_cartas') is not null
			drop table #t_cartas

	end

	/*Resultado*/
	begin
		/*Caso tenha o id_apelido e id_sala já inseridos na dbo.t_apelido_sala_cartas, exclui e insere na sequencia com base na #t_apelido_sala_cartas*/
		if exists( select top 1 1 from dbo.t_apelido_sala_cartas t where t.id_apelido = @id_apelido and t.id_sala = @id_sala)
		begin
			delete t from dbo.t_apelido_sala_cartas t where t.id_apelido = @id_apelido and t.id_sala = @id_sala
		end
		
		insert into dbo.t_apelido_sala_cartas
			(id_apelido,id_sala,id_carta,nr_imagem)
		select
			id_apelido		= t.id_apelido,
			id_sala			= t.id_sala,
			id_carta		= t.id_carta,
			nr_imagem		= t.nr_imagem
		from
			#t_apelido_sala_cartas t
		
		/*Marcando data e horário do inicio de jogo para o jogador na sala*/
		update t set
			dt_inicio_jogo	= getdate()
		from
			dbo.t_apelido_sala t
		where
			t.id_apelido = @id_apelido
			and t.id_sala = @id_sala

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
