if exists (select top 1 1 from dbo.sysobjects where id = object_id(N'dbo.p_entrar_sala') and objectproperty(id, N'IsProcedure') = 1)
	drop procedure dbo.p_entrar_sala
go
create procedure dbo.p_entrar_sala(
	@id_sala 					int				= null,
	@id_apelido 				int				= null,
	@debug						bit				= null,
	@cd_retorno					int				= null output,
	@nm_retorno					varchar(255)	= null output,
	@nr_versao_proc				varchar(15)		= null output)
as begin

/*
***********************************************************************************************************************************************************************************
	* autor..................: Vitor Moreira
	* objetivo...............: Entrar em uma sala de jogo da memória
	* criação................: 26/11/2023
	* exemplo de chamada.....: 
declare @cd_retorno int, @nm_retorno varchar(max),@nr_versao_proc varchar(15)
exec dbo.p_entrar_sala
	@id_sala			= 1,
	@id_apelido			= 1,
	@cd_retorno			= @cd_retorno output,
	@nm_retorno			= @nm_retorno output,
	@nr_versao_proc		= @nr_versao_proc output
select '@cd_retorno' = @cd_retorno, '@nm_retorno' = @nm_retorno, '@nr_versao_proc' = @nr_versao_proc, '@id_sala' = @id_sala
	* histórico..............: 
	* 
***********************************************************************************************************************************************************************************
*/
begin try

	set nocount on;
	set xact_abort on;
	set transaction isolation level read uncommitted;
	
	set @nr_versao_proc = ltrim(rtrim(replace(replace('$Revision: 1.0 $','Revision:',''),'$','')))
	declare @nm_proc varchar(200) = 'dbo.p_listar_salas_disponiveis';

	declare	@capacidadeatual int;

	select	@capacidadeatual = count(*) from dbo.t_apelido_sala where id_sala = @id_sala;

	/*Validações*/
	begin
		if not exists(select top 1 1 from dbo.t_sala_jogo_memoria t where t.id_sala = @id_sala)
		begin
			set @cd_retorno = 12;
			set @nm_retorno = 'Sala não encontrada.';
			return;
		end
		
		if not exists(select top 1 1 from dbo.t_apelido_jogo_memoria t where t.id_apelido = @id_apelido and t.fl_ativo = 1)
		begin
			set @cd_retorno = 13;
			set @nm_retorno = 'Apelido não encontrado.';
			return;
		end

		if @capacidadeatual >= (select nr_jogadores from dbo.t_sala_jogo_memoria where id_sala = @id_sala)
		begin
			set @cd_retorno = 14;
			set @nm_retorno = 'Sala cheia.';
			return;
		end
	end

	/*Resultado*/
	begin
		--insert into dbo.t_apelido_sala (id_apelido, id_sala)
		--values (@id_apelido, @id_sala);
		
		merge dbo.t_apelido_sala as target
		using (select @id_apelido, @id_sala) as source (id_apelido, id_sala)
		on (target.id_apelido = source.id_apelido and target.id_sala = source.id_sala)
		when matched then 
			update set dt_atualizacao = getdate()
		when not matched then 
			insert (id_apelido, id_sala)
			values (source.id_apelido, source.id_sala);

		--insert into dbo.t_status_jogador_sala (id_apelido, id_sala)
		--values (@id_apelido, @id_sala);

		merge dbo.t_status_jogador_sala as target
		using (select @id_apelido, @id_sala) as source (id_apelido, id_sala)
		on (target.id_apelido = source.id_apelido and target.id_sala = source.id_sala)
		when matched then 
			update set dt_atualizacao = getdate()
		when not matched then 
			insert (id_apelido, id_sala)
			values (source.id_apelido, source.id_sala);
	end

	select	@cd_retorno = 0,
			@nm_retorno = 'apelido adicionado à sala com sucesso';

end try
begin catch
	set @cd_retorno =	1
	set @nm_retorno =	'Procedure : ' + isnull(@nm_proc,'') + ' - ' + 'Versão: ' + isnull(convert(varchar(20), @nr_versao_proc),'0') + ' - '
					+ case when @nm_proc <> isnull(error_procedure(),@nm_proc) then 'Erro na procedure: ' + error_procedure() else '' end
					+ 'Mensagem: ' + isnull(convert(varchar(300), error_message()), '')
					+ case when isnull(error_line(), 0) <> 0 then ' - Linha: ' + convert(varchar(max),error_line()) else '' end
end catch;
end;
