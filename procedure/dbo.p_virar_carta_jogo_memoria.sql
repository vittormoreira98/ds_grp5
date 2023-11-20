if exists (select top 1 1 from dbo.sysobjects where id = object_id(N'dbo.p_virar_carta_jogo_memoria') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop procedure dbo.p_virar_carta_jogo_memoria
go
create procedure dbo.p_virar_carta_jogo_memoria
(
	@id_carta					int				= null,
	@cd_usuario					varchar(100)	= null,
	@id_partida					int				= null,
	@debug						bit				= null,
	@fl_virar_carta				bit				= null output,
	@cd_retorno					int				= null output,
	@nm_retorno					varchar(max)	= null output,
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
exec dbo.p_virar_carta_jogo_memoria
	@id_carta		= 1,
	@cd_usuario		= 'vitor',
	@id_partida		= 1,
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
		declare
			@dt_sistema datetime = getdate()
	end

	insert into dbo.debug (nm_campo,vl_campo,dt_sistema) values 
	('linha50','linha50',@dt_sistema),
	('@id_carta',convert(varchar(max),@id_carta),@dt_sistema),
	('@cd_usuario',@cd_usuario,@dt_sistema),
	('@id_partida',convert(varchar(max),@id_partida),@dt_sistema)

	select @fl_virar_carta = 1
	/*Pré validações*/
	begin
		if @id_carta is null
		begin
			select @cd_retorno = 1, @nm_retorno = 'O parâmetro @id_carta é obrigatório'
			raiserror(@nm_retorno, 16, 1)
		end

		if @cd_usuario is null
		begin
			select @cd_retorno = 2, @nm_retorno = 'O parâmetro @cd_usuario é obrigatório'
			raiserror(@nm_retorno, 16, 1)
		end

		if @id_partida is null
		begin
			select @cd_retorno = 3, @nm_retorno = 'O parâmetro @id_partida é obrigatório'
			raiserror(@nm_retorno, 16, 1)
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
	select 'cd_retorno' = @cd_retorno, 'nm_retorno' = @nm_retorno
end catch
end
