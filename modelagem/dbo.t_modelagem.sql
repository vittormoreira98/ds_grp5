
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
	nr_jogadores_atuais			int				not null	default(0),
	fl_ativo					bit				not null	default(1),
	dt_cadastro					datetime		not null	default(getdate()),
	dt_alteracao				datetime		not null	default(getdate())
)
if exists (select top 1 1 from dbo.sysobjects where id = object_id(N'dbo.t_apelido_sala') and objectproperty(id, N'IsUserTable') = 1)
	drop table dbo.t_apelido_sala
create table dbo.t_apelido_sala
(
	id_apelido_sala				int				identity(1,1)	not null,
	id_apelido					int				not null,
	id_sala						int				not null,
	dt_atualizacao				datetime		not null	default(getdate()),
	dt_inicio_jogo				datetime		null,
	fl_jogo_finalizado			bit				not null	default(0),
	vl_pontuacao				int				not null	default(0)
)
if exists (select top 1 1 from dbo.sysobjects where id = object_id(N'dbo.t_apelido_sala_cartas') and objectproperty(id, N'IsUserTable') = 1)
	drop table dbo.t_apelido_sala_cartas
create table dbo.t_apelido_sala_cartas
(
	id_apelido_sala_cartas		int				identity(1,1)	not null,
	id_apelido					int				not null,
	id_sala						int				not null,
	id_carta					int				not null,
	nr_imagem					int				not null,
	fl_carta_virada_rodada		bit				not null	default(0),
	fl_carta_virada_acerto		bit				not null	default(0),
	dt_cadastro					datetime		not null	default(getdate())
)
if exists (select top 1 1 from dbo.sysobjects where id = object_id(N'dbo.t_status_jogador_sala') and objectproperty(id, N'IsUserTable') = 1)
	drop table dbo.t_status_jogador_sala
create table dbo.t_status_jogador_sala
(
	id_status_jogador_salas		int				identity(1,1)	not null,
	id_apelido					int				not null,
	id_sala						int				not null,
	fl_pronto					bit				not null	default(0),
	dt_atualizacao				datetime		not null	default(getdate())
)