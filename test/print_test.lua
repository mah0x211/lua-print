require('luacov')
local pcall = pcall
local unpack = unpack or table.unpack
local assert = require('assert')
local printx = require('print')

local TMPNAME = os.tmpname()

local function remove(f)
    f:close()
    os.remove(TMPNAME)
end

local function call(fn, ...)
    local defout = io.output()
    local f = io.tmpfile()

    assert(io.output(f) == f)
    printx.setoutput()
    local ok, err = pcall(fn, ...)
    assert(io.output(defout) == defout)
    printx.setoutput()

    if not ok then
        remove(f)
        return nil, err
    end

    f:seek("set")

    return f
end

local function test_setoutput()
    local defout = io.output()

    -- test that custom output
    local f = io.tmpfile()
    printx.setoutput(f)
    assert.equal(io.output(), f)

    -- test that custom output as table
    local buf = ''
    local flushed = false
    printx.setoutput({
        flush = function(self)
            flushed = true
            return self
        end,
        write = function(self, msg)
            buf = buf .. msg
            return self
        end,
    })
    printx.flush()
    assert.is_true(flushed)
    printx('foo', 'bar', 'baz')
    assert.equal(buf, 'foo bar baz\n')

    -- test that set default output
    printx.setoutput()
    assert.not_equal(io.output(), defout)

    -- test that throws an error if argument is invalid
    local err = assert.throws(printx.setoutput, true)
    assert.match(err, 'file must be file*, string or table')
end

local function test_print_features()
    printx.setlevel('debug')
    -- test that output date and label
    for k, v in pairs({
        emerge = {
            'hello print %s',
            'format',
            'world',
            1,
            true,
            {
                foo = 'bar',
            },
        },
        alert = {
            'hello print %s',
            'format',
            'world',
            1,
            true,
            {
                foo = 'bar',
            },
        },
        crit = {
            'hello print %s',
            'format',
            'world',
            1,
            true,
            {
                foo = 'bar',
            },
        },
        error = {
            'hello print %s',
            'format',
            'world',
            1,
            true,
            {
                foo = 'bar',
            },
        },
        warn = {
            'hello print %s',
            'format',
            'world',
            1,
            true,
            {
                foo = 'bar',
            },
        },
        notice = {
            'hello print %s',
            'format',
            'world',
            1,
            true,
            {
                foo = 'bar',
            },
        },
        info = {
            'hello print %s',
            'format',
            'world',
            1,
            true,
            {
                foo = 'bar',
            },
        },
        debug = {
            'hello print %s',
            'format',
            'world',
            1,
            true,
            {
                foo = 'bar',
            },
        },
    }) do
        local f = assert(call(function()
            printx[k](unpack(v))
        end))
        local res = f:read('*a')
        remove(f)

        -- match date
        assert.match(res, '^%d+%-%d+%-%d+T%d+:%d+:%d+.+ ', false)
        -- match label and argument
        if k == 'debug' then
            assert.match(res, string.format(
                             '%%[%s] %%[[^:]+:%%d+] hello print format world 1 true { foo = "bar" }',
                             k), false)
        else
            assert.match(res, string.format(
                             '[%s] hello print format world 1 true { foo = "bar" }',
                             k))
        end
    end
end

local function test_print_fatal()
    -- test that output date and label and throws an error
    local err
    local f = assert(call(function()
        err = assert.throws(function()
            printx.fatal(unpack({
                'hello print %s',
                'format',
                'world',
                1,
                true,
                {
                    foo = 'bar',
                },
            }))
        end)
    end))
    local res = f:read('*a')
    remove(f)

    -- error messages include output messages
    assert.match(err, res)
    -- match date
    assert.match(res, '^%d+%-%d+%-%d+T%d+:%d+:%d+.+ ', false)
    -- match label and argument
    assert.match(res,
                 '%[fatal] hello print format world 1 true { foo = "bar" }',
                 false)
end

local function test_setlevel()
    -- test that set the output level
    local levels = {
        'emerge',
        'alert',
        'crit',
        'error',
        'warn',
        'notice',
        'info',
    }
    for i, lv in ipairs(levels) do
        local enabled_levels = table.concat(levels, ' ', 1, i)

        printx.setlevel(lv)
        -- test that output date and label
        for k, v in pairs({
            emerge = 'hello',
            alert = 'hello',
            crit = 'hello',
            error = 'hello',
            warn = 'hello',
            notice = 'hello',
            info = 'hello',
        }) do
            local f = assert(call(function()
                printx[k](v)
            end))
            local res = f:read('*a')
            remove(f)

            if string.find(enabled_levels, k, 1, true) then
                -- enabled to output
                assert.match(res, string.format('[%s] hello', k))
            else
                -- disabled to output
                assert.equal(res, '')
            end
        end
    end
    printx.setlevel('info')

    --- test that throws unsupported error
    local ok, err = pcall(function()
        printx.setlevel(true)
    end)
    assert(not ok, 'setlevel true')
    assert.match(err, 'level must be string')

    --- test that throws unsupported error
    ok, err = pcall(function()
        printx.setlevel('foo')
    end)
    assert(not ok, 'setlevel foo')
    assert.match(err, 'unsupported print level .+foo', false)
end

local function test_setdebug()
    -- test that set the debug to true
    printx.setdebug(true)
    for k, v in pairs({
        emerge = 'hello',
        alert = 'hello',
        crit = 'hello',
        error = 'hello',
        warn = 'hello',
        notice = 'hello',
        info = 'hello',
    }) do
        local f = assert(call(function()
            printx[k](v)
        end))
        local res = f:read('*a')
        remove(f)

        -- enabled to output
        local pat = string.format('%%[%s%%] ', k) .. '%[.+:%d+] ' .. v
        assert.match(res, pat, false)
    end
    printx.setdebug(false)

    --- test that throws unsupported error
    local ok, err = pcall(function()
        printx.setdebug(1)
    end)
    assert(not ok, 'setdebug true1')
    assert.match(err, 'enabled must be boolean')
end

local function test_format()
    -- test that format string
    for _, v in ipairs({
        {
            arg = {},
            equal = '',
        },
        {
            arg = {
                'hello',
            },
            equal = 'hello',
        },
        {
            arg = {
                'hello %s',
                'world',
            },
            equal = 'hello world',
        },
        {
            arg = {
                'hello %%s',
                'world',
            },
            equal = 'hello %%s world',
        },
        {
            arg = {
                true,
                'hello %s',
                'world',
            },
            equal = 'true hello %s world',
        },
    }) do
        local s = printx.format(unpack(v.arg))
        assert.equal(s, v.equal)
    end

    -- test that throws an error
    local err = assert.throws(printx.format, 'hello %s %d', 'world')
    assert.match(err, 'argument #3')
end

local function test_flush()
    local fname = os.tmpname()
    local defout = io.output()
    local f = assert(io.output(fname))

    assert(f ~= defout)
    printx.setoutput()
    f:setvbuf("full")
    f:write('hello')

    -- test that flush buffer
    local file = assert(io.open(fname))
    assert.equal(file:read('*a'), '')
    printx.flush()
    assert.equal(file:read('*a'), 'hello')
    assert(io.output(defout) == defout)

    remove(f)
    file:close()
    os.remove(fname)
    printx.setoutput()
end

test_setoutput()
test_print_features()
test_print_fatal()
test_setlevel()
test_setdebug()
test_format()
test_flush()
