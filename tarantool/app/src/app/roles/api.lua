local vshard = require('vshard')
local cartridge = require('cartridge')
local errors = require('errors')
local log = require('log')
local err_vshard_router = errors.new_class("Vshard routing error")
local err_httpd = errors.new_class("httpd error")



local function http_customer_add(req)
    local customer = req:json()

    log.info('**********************************')


    local bucket_id = vshard.router.bucket_id(customer.customer_id)
    customer.bucket_id = bucket_id

    local _, error = err_vshard_router:pcall(
        vshard.router.call,
        bucket_id,
        'write',
        'customer_add',
        {customer}
    )

    if error then
        local resp = req:render({json = {
            info = "Internal error",
            error = error
        }})
        resp.status = 500
        return resp
    end

    local resp = req:render({json = { info = "Successfully created" }})
    resp.status = 201
    return resp
end

local function http_customer_get(req)
    local customer_id = tonumber(req:stash('customer_id'))

    local bucket_id = vshard.router.bucket_id(customer_id)

    local customer, error = err_vshard_router:pcall(
        vshard.router.call,
        bucket_id,
        'read',
        'customer_lookup',
        {customer_id}
    )

    if error then
        local resp = req:render({json = {
            info = "Internal error",
            error = error
        }})
        resp.status = 500
        return resp
    end

    if customer == nil then
        local resp = req:render({json = { info = "Customer not found" }})
        resp.status = 404
        return resp
    end

    customer.bucket_id = nil
    local resp = req:render({json = customer})
    resp.status = 200
    return resp
end


local function http_customer_update_balance(req)

    log.info('********* http_customer_update_balance ********************')

    local customer_id = tonumber(req:stash('customer_id'))
    local body = req:json()
    local account_id = tonumber(body["account_id"])
    local amount = body["amount"]

    local bucket_id = vshard.router.bucket_id(customer_id)

    local balance, error = err_vshard_router:pcall(
        vshard.router.call,
        bucket_id,
        'read',
        'customer_update_balance',
        {customer_id, account_id, amount}
    )

    if error then
        local resp = req:render({json = {
            info = "Internal error",
            error = error
        }})
        resp.status = 500
        return resp
    end

    if balance == nil then
        local resp = req:render({json = { info = "Account not found" }})
        resp.status = 404
        return resp
    end

    local resp = req:render({json = {balance = balance}})
    resp.status = 200
    return resp
end


local function http_update_consumption(req)


    local customer_id = tonumber(req:stash('customer_id'))
    local body = req:json()
    local amount = body["consumption"]
    local account_id = body["account_id"]

    
    local bucket_id = vshard.router.bucket_id(customer_id)

     local balance, error = err_vshard_router:pcall(
         vshard.router.call,
         bucket_id,
         'read',
         'customer_update_consumption',
         {customer_id, account_id, amount}
     )


    if error then
        local resp = req:render({json = {
            info = "Internal error",
            error = error
        }})
        resp.status = 500
        return resp
    end

    -- if balance == nil then
    --     local resp = req:render({json = { info = "Account not found" }})
    --     resp.status = 404
    --     return resp
    -- end

    local resp = req:render({json = {balance = amount, account_id = account_id}})
    resp.status = 200
    return resp
end


local function init(opts)
    rawset(_G, 'vshard', vshard)

  
    if opts.is_master then
        box.schema.user.grant('guest',
            'read,write,execute',
            'universe',
            nil, { if_not_exists = true }
        )
    end

    local httpd = cartridge.service_get('httpd')

    if not httpd then
        return nil, err_httpd:new("not found")
    end

    -- Навешиваем функции-обработчики
    httpd:route(
        { path = '/storage/customers/create', method = 'POST', public = true },
        http_customer_add
    )
    httpd:route(
        { path = '/storage/customers/:customer_id', method = 'GET', public = true },
        http_customer_get
    )
    httpd:route(
        { path = '/storage/customers/:customer_id/update_balance', method = 'POST', public = true },
        http_customer_update_balance
    )
    httpd:route(
        { path = '/storage/customers/:customer_id/update_consumption', method = 'POST', public = true },
        http_update_consumption
    )
 





    return true
end





return {
    role_name = 'api',
    init = init,
    dependencies = {'cartridge.roles.vshard-router'},
}
