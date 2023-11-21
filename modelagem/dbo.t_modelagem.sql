
if exists (select top 1 1 from dbo.sysobjects where id = object_id(N'dbo.debug') and objectproperty(id, N'IsUserTable') = 1)
	drop table dbo.debug
create table dbo.debug(
	nm_campo varchar(max) NULL,
	vl_campo varchar(max) NULL,
	dt_sistema datetime NULL
)
if exists (select top 1 1 from dbo.sysobjects where id = object_id(N'dbo.t_apelido_jogo_memoria') and objectproperty(id, N'IsUserTable') = 1)
	drop table dbo.t_apelido_jogo_memoria
create table dbo.t_apelido_jogo_memoria
(
	id_apelido					int				identity(1,1)	not null,
	nm_apelido					varchar(50)		not null,
	fl_ativo					bit				not null	default(1),
	dt_cadastro					datetime		not null	default(getdate()),
	dt_alteracao				datetime		not null	default(getdate())
)
if exists (select top 1 1 from dbo.sysobjects where id = object_id(N'dbo.t_sala_jogo_memoria') and objectproperty(id, N'IsUserTable') = 1)
	drop table dbo.t_sala_jogo_memoria
create table dbo.t_sala_jogo_memoria
(
	id_sala						int				identity(1,1)	not null,
	nm_sala						varchar(50)		not null,
	nr_jogadores				int				not null,
	fl_sala_aberta				bit				not null,
	fl_ativo					bit				not null	default(1),
	dt_cadastro					datetime		not null	default(getdate()),
	dt_alteracao				datetime		not null	default(getdate())
)