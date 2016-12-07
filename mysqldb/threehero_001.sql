show databases;
drop database if exists threehero;

select "创建数据库 threehero";
create database threehero;
use threehero;
select "创建account表";
create table account(uuid varchar(50) primary key,
	nick varchar(50) not null, 
	password varchar(50) not null, 
	gold int not null, 
	money int not null, 
	exp int not null, 
	icon varchar(50) not null,
	flag int  not null, 
	expire int not null,
	version int not null);
desc account;
select "创建card表";
create table card1(uuid varchar(50) primary key,
	account_id varchar(50) not null,
	dataId int not null,
	count int not null,
	explore int not null,
	index card_accountid(account_id));
desc card1;
select "创建explore表";
create table explore(uuid varchar(50) primary key,
	uuid0 varchar(50) not null,
	uuid1 varchar(50) not null,
	uuid2 varchar(50) not null,
	uuid3 varchar(50) not null,
	uuid4 varchar(50) not null,
	con0 int not null,
	con1 int not null,
	con2 int not null,
	con3 int not null,
	con4 int not null,
	time int not null);
desc explore;
select "创建skill能表";
create table skill1(uuid varchar(50) primary key,
	account_id varchar(50) not null,
	dataId int not null,
	count int not null,
	index skill_accountid(account_id));
desc skill1;
select "创建CD表";
create table cooldown(uuid varchar(50) primary key,
	accountId varchar(50) not null,
	atype int not null,
	value int not null,
	index cd_accountid(accountId));
desc cooldown;
select "创建活动表";
create table activity(uuid varchar(50) primary key,
	accountId varchar(50) not null,
	atype int not null,
	value int not null,
	expire int not null,
	index activity_accountid(accountId));
desc activity;
select "                      ";
select "数据库创建完成";
show tables;
