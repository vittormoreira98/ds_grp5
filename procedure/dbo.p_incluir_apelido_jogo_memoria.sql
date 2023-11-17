if exists (select top 1 1 from dbo.sysobjects where id = object_id(N'dbo.p_incluir_apelido_jogo_memoria') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop procedure dbo.p_incluir_apelido_jogo_memoria
go
create procedure dbo.p_incluir_apelido_jogo_memoria
(
	@nm_apelido					varchar(50)		= null,
	@debug						bit				= null,
    @id_apelido					int				= null output,
	@cd_retorno					int				= null output,
	@nm_retorno					varchar(max)	= null output,
	@nr_versao_proc				varchar(15)		= null output
)
as begin
/*
***********************************************************************************************************************************************************************************
	* autor..................: Vitor Moreira
	* objetivo...............: Incluir um apelido para o jogo da memória, caso ele não esteja sendo usado por outro usuário
	* criação................: 17/11/2023
	* exemplo de chamada.....: 
declare @cd_retorno int, @nm_retorno varchar(max),@nr_versao_proc varchar(15), @id_apelido int
exec dbo.p_incluir_apelido_jogo_memoria
	@nm_apelido		= 'Chico Bento',
	@id_apelido		= @id_apelido output,
	@cd_retorno		= @cd_retorno output,
	@nm_retorno		= @nm_retorno output,
	@nr_versao_proc	= @nr_versao_proc output
select '@cd_retorno' = @cd_retorno, '@nm_retorno' = @nm_retorno, '@nr_versao_proc' = @nr_versao_proc, '@id_apelido' = @id_apelido
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
        if object_id('tempd..#t_apelido_jogo_memoria') is not null
            drop table #t_apelido_jogo_memoria
        create table #t_apelido_jogo_memoria
        (
            id_apelido					int
        )
    end

    if @debug = 1
    begin
        insert into dbo.debug (nm_campo,vl_campo,dt_sistema) values 
        ('@nm_apelido',@nm_apelido,@dt_sistema)
    end

    /*Pré validações*/
    begin
        if isnull(@nm_apelido,'') = ''
        begin
            select @cd_retorno = 1, @nm_retorno = 'O parâmetro @nm_apelido é obrigatório'
            return
        end

        if exists(select top 1 1 from dbo.t_apelido_jogo_memoria t where t.nm_apelido = @nm_apelido and t.fl_ativo = 1)
        begin
            select @cd_retorno = 2, @nm_retorno = 'O apelido informado já está sendo usado por outro usuário'
            return
        end

    end

    /*Resultado*/
    begin
        insert into dbo.t_apelido_jogo_memoria (nm_apelido,fl_ativo,dt_cadastro,dt_alteracao)
        output inserted.id_apelido into #t_apelido_jogo_memoria (id_apelido)
        values (@nm_apelido,1,@dt_sistema,@dt_sistema)
        
        select @id_apelido = t.id_apelido from #t_apelido_jogo_memoria t
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
