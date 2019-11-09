DROP FUNCTION if exists make_product_sale;
CREATE FUNCTION make_product_sale(beverage varchar) returns INTEGER AS
-- Данная функция реализует алгоритм рюкзака с точным весом, где вес монеты - ее наминал
-- https://informatics.mccme.ru/mod/book/view.php?id=815&chapterid=60
$$
DECLARE
    all_bills INTEGER;
    i INTEGER;
    j INTEGER;
    tmpval INTEGER;
    tmpval1 INTEGER;
    tmpval2 INTEGER;
    my_money INTEGER;
    machine_money INTEGER;
    drink_cost INTEGER;
    change INTEGER;

BEGIN
    -- Считаем деньги в моем кошельке
    SELECT SUM(my_wallet.count * coins_value.value) INTO my_money FROM my_wallet JOIN coins_value ON my_wallet.FK_my_wallet_id=coins_value.PK_coins_value_id;
    -- Считаем деньги в кошельке автомата
    SELECT SUM(machine_wallet.count * coins_value.value) INTO machine_money FROM machine_wallet JOIN coins_value ON machine_wallet.FK_machine_wallet_id=coins_value.PK_coins_value_id;
    -- Узнаем цену напитка
    SELECT price INTO drink_cost FROM machine WHERE machine.drink = beverage;

    -- Проверяем платежеспособность клиента
    IF drink_cost > my_money
    THEN
        RETURN 1;
    END IF;

    SELECT my_money - drink_cost INTO change;
    -- Проверяем способность выдачи сдачи
    IF machine_money < change
    THEN
        RETURN 1;
    END IF;
    -- Считаем кол-во монет всего в автомате
    SELECT SUM(count) INTO all_bills FROM  machine_wallet;

    -- Узнаем количество каждой монеты в автомате
    CREATE TEMPORARY TABLE bills1(id integer, value integer);
    INSERT INTO bills1 SELECT generate_series(1, machine_wallet.count), coins_value.value FROM machine_wallet JOIN coins_value ON machine_wallet.FK_machine_wallet_id = coins_value.PK_coins_value_id;

    -- Получаем таблицу из всех монет доступных в автомате
    CREATE TEMPORARY TABLE bills(id integer, value integer);
    INSERT INTO bills SELECT row_number() OVER (), bills1.value FROM bills1;

    -- Создаем таблицу для реализации алгоритма рюкзака и заполняем его нулями
    -- tmp_table[от 0 до кол-во монет][от 0 до размера сдачи] -
    -- таблица реализуюшая двумерный массив, из-за этого и того,
    -- что массивы в postgresql по умолчанию нумеруюцся с 1, происходит хак с j + 1
    CREATE TEMPORARY TABLE tmp_table(id serial, data INTEGER[]);
    INSERT INTO tmp_table(id, data) VALUES(0, array_fill(0, ARRAY[change + 2]));
    INSERT INTO tmp_table(data) SELECT array_fill(0, ARRAY[change + 2]) FROM generate_series(1, all_bills) AS i;

    FOR i IN SELECT * FROM generate_series(1,all_bills)
    LOOP
        FOR j in SELECT * FROM generate_series(1, change)
        LOOP
            -- По умалчанию инициализируем tmp_table[i][j] = tmp_table[i-1][j]
            UPDATE tmp_table SET data[j + 1] = t2.data[j + 1] FROM (SELECT id, data FROM tmp_table) as t2 WHERE t2.id + 1 = tmp_table.id and tmp_table.id = i;
            -- Вычисляем номинал монеты - tmpval
            SELECT value INTO tmpval FROM bills WHERE bills.id = i;
            -- Вычисляем tmp_table[i][j]
            SELECT data[j + 1] INTO tmpval1 FROM tmp_table WHERE id = i;
            -- Проверяем возможность улучшить результат на текущем шаге
            IF j >= tmpval
            THEN
                -- Вычисляем tmp_table[i-1][j - tmpval]
                SELECT data[j + 1 - tmpval] INTO tmpval2 FROM tmp_table WHERE id = i - 1;
                -- Проверяем возможность улучшить  помощью текущей монеты
                IF tmpval1 < tmpval2 + tmpval
                THEN
                    -- Сохраняем улучшенный результат
                    UPDATE tmp_table SET data[j + 1] = tmpval2 + tmpval WHERE id = i;
                    -- Небольшая модификация для уменьшения кол-ва шагов
                    IF tmpval2 + tmpval = change
                    THEN
                        -- Изменяем кошельки
                        UPDATE machine_wallet SET count = machine_wallet.count + t.count FROM (SELECT FK_my_wallet_id, count FROM my_wallet) as t WHERE machine_wallet.FK_machine_wallet_id = t.FK_my_wallet_id;
                        UPDATE my_wallet SET count = 0;
                        RETURN 0;
                    END IF;
                END IF;
            END IF;

        END LOOP;
    END LOOP;
    RETURN 1;
END;
$$ language plpgsql;

