local cartridge = require('cartridge')
local expirationd = require('expirationd')
local log = require('log')
local decimal = require('decimal')
local decnumber = require('ldecnumber')
local http_client = require('http.client').new({max_connections = 5})



local job_name = 'clean_all';

local function init_daemon()


    log.info('ggggggggggggsssggggggg   delete_tuple')
    local space = box.space.account
    log.info('ggggggggggggsssggggggg   delete_tuple1')
    local job_name = 'clean_all'
    log.info('ggggggggggggsssggggggg   delete_tuple3')
    expirationd = require('expirationd')
    log.info('ggggggggggggsssggggggg   sds')

    local function is_expired(args, tuple)
        return true
    end
    log.info('ggggggggggggsssggggggg   sds')

    local function delete_tuple(space_id, args, tuple)

        local sp = box.space.consumption
        local acc = box.space.account

        for k, v in sp:pairs() do


            local cur_bal = acc:get(v[2])
            local bal = (decnumber.tonumber(cur_bal[4]) -   decnumber.tonumber(v[4]))
            local bal_str = bal:tostring()


            box.begin()

            if bal  <= decnumber.tonumber('0.0')  then
                  log.info('send signall to poweroff' )




            end

            acc:update({ v[2] }, {
                { '=', 4, bal_str }
            })
            box.commit()
            local status = http_client:post('http://localhost:8001',  acc:get(v[2])[2]).status;
            log.info('status %s' , status )

            log.info('job Worked %s increase %s', v[4], bal_str  )




        end


    end
    log.info('ggggggggggggsssggggggg   start')
    expirationd.start(job_name, space.id, is_expired, {
        process_expired_tuple = delete_tuple, args = nil, force = true,
        tuples_per_iteration = 2, full_scan_time = 36
    })

end


local function init(opts)
    init_daemon();
    return true
end

local function stop()
    expirationd.kill_task(job_name)
end

local function validate_config(conf_new, conf_old) -- luacheck: no unused args
    return true
end

local function apply_config(conf, opts) -- luacheck: no unused args
    -- if opts.is_master then
    -- end

    return true
end


return {
    role_name = 'app.roles.daemon',
    init = init,
    -- для дальнейшего тестирования

    dependencies = {
        'cartridge.roles.vshard-storage',
    },
}
