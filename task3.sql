--DROP FUNCTION if exists sell;
CREATE FUNCTION sell(coin_value integer) returns void AS
$$ 
begin
UPDATE my_wallet
SET COUNT = COUNT + 1
WHERE my_wallet.FK_my_wallet_id IN
    (SELECT my_wallet.FK_my_wallet_id
     FROM coins_value
     JOIN my_wallet ON coins_value.PK_coins_value_id = my_wallet.FK_my_wallet_id
     WHERE value = coin_value );
end;
$$ language plpgsql;
