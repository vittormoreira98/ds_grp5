
create table dbo.t_sexo (
    id_sexo int identity(1,1) primary key,
    ds_sexo varchar(10)
);

create table dbo.t_tipo_meio_comunicacao (
    id_tipo_meio_comunicacao int identity(1,1) primary key,
    ds_tipo_meio_comunicacao varchar(50)
);

create table dbo.t_pessoa (
    id_pessoa int identity(1,1) primary key,
    nm_pessoa varchar(100),
    cd_cpf char(11),
    cd_rg varchar(20),
    dt_nascimento date,
    id_sexo int foreign key references dbo.t_sexo(id_sexo)
);

create table dbo.t_pessoa_meio_comunicacao (
    id_pessoa_meio_comunicacao int identity(1,1) primary key,
    id_pessoa int foreign key references dbo.t_pessoa(id_pessoa),
    id_tipo_meio_comunicacao int foreign key references dbo.t_tipo_meio_comunicacao(id_tipo_meio_comunicacao),
    nm_pessoa_meio_comunicacao varchar(100)
);

create table t_usuario (
    id_usuario int identity(1,1) primary key,
    cd_usuario varchar(50),
    id_pessoa int foreign key references dbo.t_pessoas(id)
);

create table dbo.t_pessoa_endereco (
    id_pessoa_endereco int identity(1,1) primary key,
    id_pessoa int foreign key references dbo.t_pessoa(id_pessoa),
    cd_cep varchar(8),
    nm_rua varchar(100),
    cd_numero varchar(10),
    ds_complemento varchar(100),
    nm_bairro varchar(50),
    nm_cidade varchar(50),
    cd_estado char(2),
    nm_pais varchar(50)
);
