local log = require('log')
local decimal = require('decimal')


-- модуль проверки аргументов в функциях
local checks = require('checks')
local vshard = require('vshard')
local expirationd = require('expirationd')
fiber = require('fiber')

-- модуль работы с числами
local decnumber = require('ldecnumber')

local function init_spaces()
    local customer = box.schema.space.create(-- имя спейса для хранения пользователей
        'customer',
        -- дополнительные параметры
        {
            -- формат хранимых кортежей
            format = {
                { 'customer_id', 'unsigned' },
                { 'bucket_id', 'unsigned' },
                { 'name', 'string' },
            },
            -- создадим спейс, только если его не было
            if_not_exists = true,
        })

    -- создадим индекс по id пользователя
    customer:create_index('customer_id', {
        parts = { 'customer_id' },
        if_not_exists = true,
    })

    customer:create_index('bucket_id', {
        parts = { 'bucket_id' },
        unique = false,
        if_not_exists = true,
    })

    -- аналогично, создаем спейс для учетных записей (счетов)
    local account = box.schema.space.create('account', {
        format = {
            { 'account_id', 'unsigned' },
            { 'customer_id', 'unsigned' },
            { 'bucket_id', 'unsigned' },
            { 'balance', 'string' },
            { 'name', 'string' },
        },
        if_not_exists = true,
    })

    -- аналогичные индексы
    account:create_index('account_id', {
        parts = { 'account_id' },
        if_not_exists = true,
    })
    account:create_index('customer_id', {
        parts = { 'customer_id' },
        unique = false,
        if_not_exists = true,
    })

    account:create_index('bucket_id', {
        parts = { 'bucket_id' },
        unique = false,
        if_not_exists = true,
    })

    --   расход в секунду  для учетных записей (счетов)
    local consumption = box.schema.space.create('consumption', {
        format = {
            { 'consumption_id', 'unsigned' },
            { 'account_id', 'unsigned' },
            { 'bucket_id', 'unsigned' },
            { 'consumption', 'string' },
        },
        if_not_exists = true,
    })

    -- аналогичные индексы
    consumption:create_index('consumption_id', {
        parts = { 'consumption_id' },
        if_not_exists = true,
    })
    consumption:create_index('account_id', {
        parts = { 'account_id' },
        unique = false,
        if_not_exists = true,
    })

    consumption:create_index('bucket_id', {
        parts = { 'bucket_id' },
        unique = false,
        if_not_exists = true,
    })
    box.schema.sequence.create('consumption', { min = 5, start = 5, if_not_exists = true, })
end


local function customer_add(customer)
    customer.accounts = customer.accounts or {}

    -- открытие транзакции
    box.begin()

    -- вставка кортежа в спейс customer
    box.space.customer:insert({
        customer.customer_id,
        customer.bucket_id,
        customer.name
    })
    for _, account in ipairs(customer.accounts) do
        -- вставка кортежей в спейс account
        box.space.account:insert({
            account.account_id,
            customer.customer_id,
            customer.bucket_id,
            '0.00',
            account.name
        })
    end

    -- коммит транзакции
    box.commit()
    return true
end


local function update_balance(balance, amount)
    -- конвертируем строку с балансом в число
    local balance_decimal = decnumber.tonumber(balance)
    local balance_amount = decnumber.tonumber(amount)

    log.info('********* balance_amount ********************')
    log.info(balance_amount)
    log.info('********* balance_amount ********************')


    balance_decimal = balance_decimal + balance_amount


    log.info('********* balance_decimal ********************')
    log.info(balance_decimal)
    log.info('********* balance_decimal ********************')

    if balance_decimal:isnan() then
        error('Invalid amount')
    end
    log.info('********* balance_decimal 2 ********************')
    log.info(balance_decimal)
    log.info('********* balance_decimal 2 ********************')

    -- округляем до 2-х знаков после запятой и конвертируем баланс
    -- обратно в строку
    return balance_decimal:rescale(-2):tostring()
end


local function customer_update_balance(customer_id, account_id, amount)
    -- проверка аргументов функции
    checks('number', 'number', 'string')


    -- находим требуемый счет в базе данных
    local account = box.space.account:get(account_id)
    if account == nil then -- проверяем, найден ли этот счет
        return nil
    end

    -- проверяем, принадлежит ли запрашиваемый счет пользователю
    if account.customer_id ~= customer_id then
        error('Invalid account_id')
    end

    local new_balance = update_balance(account.balance, amount)

    -- обновляем баланс
    box.space.account:update({ account_id }, {
        { '=', 4, new_balance }
    })

    return new_balance
end

local function customer_update_consumption(customer_id, account_id, amount)
    -- проверка аргументов функции
    checks('number', 'number', 'string')

    log.info('********* customer_update_consumption ********************')

    -- находим требуемый счет в базе данных
    local account = box.space.account:get(account_id)
    if account == nil then -- проверяем, найден ли этот счет
        return nil
    end
    log.info('********* account ********************', account.customer_id)
    log.info(account.customer_id)

    -- проверяем, принадлежит ли запрашиваемый счет пользователю
    if account.customer_id ~= customer_id then
        error('Invalid account_id')
    end

    log.info('********* Invalidn ********************')




    local new_balance = update_balance(account.balance, amount)
    log.info('********* new_balance ********************')


    local cons = box.space.consumption.index.account_id:select(account_id)
    log.info('********* consumption ********************')
    log.info(cons)
    log.info('********* cons ********************')


    box.begin()
    if cons[1] == nil then

        log.info('********* insert ********************')

        box.space.consumption:insert({
            box.sequence.consumption:next(),
            account.account_id,
            account.bucket_id,
            amount
        })
    else
        log.info('********* update ********************')
        log.info(new_balance)
        log.info('********* update ********************')
        box.space.consumption:update({ cons[1].consumption_id }, {
            { '=', 4, amount }
        })
    end;
    box.commit()
    log.info('********* customer_update_consumption ********************')



    return new_balance
end

local function customer_lookup(customer_id)
    checks('number')

    local customer = box.space.customer:get(customer_id)
    if customer == nil then
        return nil
    end
    customer = {
        customer_id = customer.customer_id;
        name = customer.name;
    }
    local accounts = {}
    for _, account in box.space.account.index.customer_id:pairs(customer_id) do
        table.insert(accounts, {
            account_id = account.account_id;
            name = account.name;
            balance = account.balance;
        })
    end
    customer.accounts = accounts;

    return customer
end



local exported_functions = {
    customer_add = customer_add,
    customer_lookup = customer_lookup,
    customer_update_balance = customer_update_balance,
    customer_update_consumption = customer_update_consumption,
}

local function init(opts)


    if opts.is_master then
        -- вызываем функцию инициализацию спейсов
        init_spaces()

        for name in pairs(exported_functions) do
            box.schema.func.create(name, { if_not_exists = true })
            box.schema.role.grant('public', 'execute', 'function', name, { if_not_exists = true })
        end
    end
    for name, func in pairs(exported_functions) do
        rawset(_G, name, func)
    end
    return true
end


local function is_expired(args, tuple)
    log.info('wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww   delete_tuple')
    return false
end


local function delete_tuple(space_id, args, tuple)
    box.begin()
    box.space.consumption:update({ cons[1].consumption_id }, {
        { '=', 4, amount }
    })
    box.commit()
    log.info('888888888888888888888888888   delete_tuple')
end



return {
    role_name = 'storage',
    init = init,
    -- для дальнейшего тестирования
    utils = {
        update_balance = update_balance
    },
    dependencies = {
        'cartridge.roles.vshard-storage',
    },
}
