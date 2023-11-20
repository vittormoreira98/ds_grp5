
if exists (select top 1 1 from dbo.sysobjects where id = object_id(N'dbo.debug') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
	drop table dbo.debug
create table dbo.debug(
	nm_campo varchar(max) NULL,
	vl_campo varchar(max) NULL,
	dt_sistema datetime NULL
)
if exists (select top 1 1 from dbo.sysobjects where id = object_id(N'dbo.t_apelido_jogo_memoria') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
	drop table dbo.t_apelido_jogo_memoria
create table dbo.t_apelido_jogo_memoria
(
	id_apelido					int				identity(1,1)	not null,
	nm_apelido					varchar(50)		not null,
	fl_ativo					bit				not null	default(1),
	dt_cadastro					datetime		not null	default(getdate()),
	dt_alteracao				datetime		not null	default(getdate()),
	dt_exclusao					datetime		null
)