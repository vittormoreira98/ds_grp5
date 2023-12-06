if exists (select top 1 1 from dbo.sysobjects where id = object_id(N'dbo.p_obter_ranking_jogadores') and objectproperty(id, N'isprocedure') = 1)
	drop procedure dbo.p_obter_ranking_jogadores
go
create procedure dbo.p_obter_ranking_jogadores(
	@id_sala					int 			= null,
	@debug						bit				= null,
	@cd_retorno					int				= null output,
	@nm_retorno					varchar(255)	= null output,
	@nr_versao_proc				varchar(15)		= null output
)
as begin
/*
***********************************************************************************************************************************************************************************
	* autor..................: Vitor Moreira
	* objetivo...............: Listar ranking de jogadores
	* criação................: 06/12/2023
	* exemplo de chamada.....: 
declare @cd_retorno int, @nm_retorno varchar(max),@nr_versao_proc varchar(15)
exec dbo.p_obter_ranking_jogadores
	@id_salas			= 1,
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
	declare @nm_proc varchar(200) = 'dbo.p_obter_ranking_jogadores';

    select
		tajm.id_apelido,
        tajm.nm_apelido,
        tas.vl_pontuacao as pontos_total,
        sum(convert(int,tasc.fl_carta_virada_acerto)) as total_acertos
    from 
        dbo.t_apelido_sala_cartas tasc
		inner join dbo.t_apelido_sala tas
			on tas.id_apelido = tasc.id_apelido
			and tas.id_sala = tasc.id_sala
		inner join dbo.t_apelido_jogo_memoria  tajm
			on tajm.id_apelido = tas.id_apelido
	where
		tasc.id_sala = @id_sala
    group by 
        tajm.id_apelido,
        tajm.nm_apelido,
		tas.vl_pontuacao
    order by 
        pontos_total desc,
        total_acertos desc,
        newid() /*Para ordenação aleatória em caso de empate*/
	
	
	update t set
		fl_ativo = 0
	from
		dbo.t_sala_jogo_memoria t
	where
		t.id_sala = @id_sala
		
	update tajm set
		fl_ativo = 0
	from
		dbo.t_apelido_jogo_memoria tajm
		inner join dbo.t_apelido_sala tas
			on tas.id_apelido = tajm.id_apelido
			and tas.id_sala = @id_sala
				
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
end catch;
end;

