if exists (select top 1 1 from dbo.sysobjects where id = object_id(N'dbo.p_listar_salas_disponiveis') and objectproperty(id, N'IsProcedure') = 1)
	drop procedure dbo.p_listar_salas_disponiveis
go
create procedure dbo.p_listar_salas_disponiveis (
	@debug						bit				= null,
	@cd_retorno					int				= null output,
	@nm_retorno					varchar(max)	= null output,
	@nr_versao_proc				varchar(15)		= null output)
as begin
/*
***********************************************************************************************************************************************************************************
	* autor..................: Vitor Moreira
	* objetivo...............: Listar salas disponíveis para o jogo da memória
	* criação................: 26/11/2023
	* exemplo de chamada.....: 
declare @cd_retorno int, @nm_retorno varchar(max),@nr_versao_proc varchar(15)
exec dbo.p_listar_salas_disponiveis
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

	select
		t.id_sala, t.nm_sala, t.nr_jogadores, t.fl_sala_aberta, t.nr_jogadores_atuais
	from
		dbo.t_sala_jogo_memoria t
	where
		t.fl_ativo = 1;

	select	@cd_retorno = 0,
			@nm_retorno = 'Salas listadas com sucesso';

end try
begin catch
	set @cd_retorno =	1
	set @nm_retorno =	'Procedure : ' + isnull(@nm_proc,'') + ' - ' + 'Versão: ' + isnull(convert(varchar(20), @nr_versao_proc),'0') + ' - '
					+ case when @nm_proc <> isnull(error_procedure(),@nm_proc) then 'Erro na procedure: ' + error_procedure() else '' end
					+ 'Mensagem: ' + isnull(convert(varchar(300), error_message()), '')
					+ case when isnull(error_line(), 0) <> 0 then ' - Linha: ' + convert(varchar(max),error_line()) else '' end
end catch;
end;
