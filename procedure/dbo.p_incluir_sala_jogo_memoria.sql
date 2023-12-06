if exists (select top 1 1 from dbo.sysobjects where id = object_id(N'dbo.p_incluir_sala_jogo_memoria') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop procedure dbo.p_incluir_sala_jogo_memoria
go
create procedure dbo.p_incluir_sala_jogo_memoria
(
	@nm_sala					varchar(50)		= null,
    @nr_jogadores				int				= null,
    @fl_sala_aberta				bit				= null,
	@debug						bit				= null,
	@id_sala					int				= null output,
	@cd_retorno					int				= null output,
	@nm_retorno					varchar(255)	= null output,
	@nr_versao_proc				varchar(15)		= null output
)
as begin
/*
***********************************************************************************************************************************************************************************
	* autor..................: Vitor Moreira
	* objetivo...............: Incluir sala para o jogo da memória, está pode ser aberta ou fechada, tem um nome e um número de jogadores
	* criação................: 21/11/2023
	* exemplo de chamada.....: 
declare @cd_retorno int, @nm_retorno varchar(max),@nr_versao_proc varchar(15), @id_sala int
exec dbo.p_incluir_sala_jogo_memoria
	@nm_sala			= 'Sala 1',
	@nr_jogadores		= 8,
	@fl_sala_aberta		= 1,
	@id_sala			= @id_sala output,
	@cd_retorno			= @cd_retorno output,
	@nm_retorno			= @nm_retorno output,
	@nr_versao_proc		= @nr_versao_proc output
select '@cd_retorno' = @cd_retorno, '@nm_retorno' = @nm_retorno, '@nr_versao_proc' = @nr_versao_proc, '@id_sala' = @id_sala
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
		declare
			@dt_sistema datetime = getdate()
	end
	
	/*Criação de tabela temporária*/
	begin
		if object_id('tempd..#t_sala_jogo_memoria') is not null
			drop table #t_sala_jogo_memoria
		create table #t_sala_jogo_memoria
		(
			id_sala					int
		)
	end

	/*Verificando parametros de entrada*/
	if @debug = 1
	begin
		if not exists (select top 1 1 from dbo.sysobjects where id = object_id(N'[dbo].[debug]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
		begin
			select @cd_retorno = 1, @nm_retorno = 'A tabela dbo.debug não existe'
			return
		end

		insert into dbo.debug (nm_campo,vl_campo,dt_sistema) values 
		('@nm_sala',@nm_sala,@dt_sistema),
		('@nr_jogadores',@nr_jogadores,@dt_sistema),
		('@fl_sala_aberta',@fl_sala_aberta,@dt_sistema),
		('@debug',@debug,@dt_sistema),
		('@id_sala',@id_sala,@dt_sistema),
		('@cd_retorno',@cd_retorno,@dt_sistema),
		('@nm_retorno',@nm_retorno,@dt_sistema),
		('@nr_versao_proc',@nr_versao_proc,@dt_sistema)
	end

	/*Pré validações*/
	begin
		if isnull(@nm_sala,'') = ''
		begin
			select @cd_retorno = 6, @nm_retorno = 'O parâmetro @nm_sala é obrigatório'
			return
		end
		
		if @nr_jogadores is null
		begin
			select @cd_retorno = 7, @nm_retorno = 'O parâmetro @nr_jogadores é obrigatório'
			return
		end
		
		if @fl_sala_aberta is null
		begin
			select @cd_retorno = 8, @nm_retorno = 'O parâmetro @fl_sala_aberta é obrigatório'
			return
		end
		
		if @nr_jogadores <= 0 or @nr_jogadores > 8
		begin
			select @cd_retorno = 9, @nm_retorno = 'A quantidade de jogadores deve ser entre 1 e 8'
			return
		end
		
		if not exists (select top 1 1 from dbo.sysobjects where id = object_id(N'[dbo].[t_sala_jogo_memoria]') and objectproperty(id, N'IsUserTable') = 1)
		begin
			select @cd_retorno = 10, @nm_retorno = 'A tabela dbo.t_sala_jogo_memoria não existe'
			return
		end

		if exists(select top 1 1 from dbo.t_sala_jogo_memoria t where t.nm_sala = @nm_sala and t.fl_ativo = 1)
		begin
			select @cd_retorno = 11, @nm_retorno = 'Esse nome de sala já está sendo usado'
			return
		end

	end

	/*Resultado*/
	begin

		insert into dbo.t_sala_jogo_memoria (nm_sala,nr_jogadores,fl_sala_aberta,fl_ativo,dt_cadastro,dt_alteracao)
		output inserted.id_sala into #t_sala_jogo_memoria (id_sala)
		values (@nm_sala,@nr_jogadores,@fl_sala_aberta,1,@dt_sistema,@dt_sistema)
		
		select @id_sala = t.id_sala from #t_sala_jogo_memoria t
	end

	/*Definindo retorno com processamento efetuado com sucesso*/
	select	@cd_retorno = 0,
			@nm_retorno = 'Processamento efetuado com sucesso'
	
	select 'cd_retorno' = @cd_retorno, 'nm_retorno' = @nm_retorno
	
end try
begin catch
	set @cd_retorno =	1
	set @nm_retorno =	'Procedure : ' + isnull(@nm_proc,'') + ' - ' + 'Versão: ' + isnull(convert(varchar(20), @nr_versao_proc),'0') + ' - '
					+ case when @nm_proc <> isnull(error_procedure(),@nm_proc) then 'Erro na procedure: ' + error_procedure() else '' end
					+ 'Mensagem: ' + isnull(convert(varchar(300), error_message()), '')
					+ case when isnull(error_line(), 0) <> 0 then ' - Linha: ' + convert(varchar(max),error_line()) else '' end
	select 'cd_retorno' = @cd_retorno, 'nm_retorno' = @nm_retorno
end catch
end
