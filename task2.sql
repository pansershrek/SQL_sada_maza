drop index if exists IX_machine_drink;
drop index if exists IX_machine_count;
drop index if exists IX_machine_price;
drop index if exists IX_machine_wallet_value;
drop index if exists IX_my_wallet_value;

drop table if exists machine;
drop table if exists machine_wallet;
drop table if exists my_wallet;
drop table if exists coins_value;


create table coins_value(
    PK_coins_value_id serial primary key,
    value integer check(value >= 0)
);

create table machine(
	id serial primary key,
	drink varchar (20) not null,
	count integer check(count >= 0),
	price integer
);
create index IX_machine_drink on machine(drink);
create index IX_machine_count on machine(count);
create index IX_machine_price on machine(price);


create table machine_wallet(
	FK_machine_wallet_id integer,
	count integer check(count >= 0),
	foreign key (FK_machine_wallet_id)
	references coins_value(PK_coins_value_id) on delete cascade
);


create index IX_machine_wallet_value on machine_wallet(FK_machine_wallet_id);


create table my_wallet(
	FK_my_wallet_id integer,
	count integer check(count >= 0),
	foreign key (FK_my_wallet_id)
	references coins_value(PK_coins_value_id) on delete cascade
);
create index IX_my_wallet_value on my_wallet(FK_my_wallet_id);

insert into machine(drink, count, price) values('чай', 0, 25);
insert into machine(drink, count, price) values('капучино', 0, 39);
insert into machine(drink, count, price) values('какао', 0, 23);
insert into machine(drink, count, price) values('шоколад', 0, 31);

insert into coins_value(value) values(10);
insert into coins_value(value) values(5);
insert into coins_value(value) values(2);
insert into coins_value(value) values(1);

insert into machine_wallet select PK_coins_value_id as FK_machine_wallet_id, 0 as count from coins_value;
insert into my_wallet select PK_coins_value_id as FK_my_wallet_id, 0 as count from coins_value;

update machine_wallet set count = 10 where count = 0;
