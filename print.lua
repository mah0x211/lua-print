--
-- Copyright (C) 2022 Masatoshi Fukunaga
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
--
local pcall = pcall
local select = select
local type = type
local concat = table.concat
local date = os.date
local getinfo = debug.getinfo
local sub = string.sub
local output = io.output
local format = require('string.format.all')
-- static variables
local OUTPUT = output()
local WRITE_FN = OUTPUT.write
local FLUSH_FN = OUTPUT.flush
local DEBUG = false
local SRCLEN = 0
local PRINT_LEVEL = 7 --- @type string|integer
local LEVELS = {
    [0] = 'fatal',
    [1] = 'emerge',
    [2] = 'alert',
    [3] = 'crit',
    [4] = 'error',
    [5] = 'warn',
    [6] = 'notice',
    [7] = 'info',
    [8] = 'debug',
    fatal = 0,
    emerge = 1,
    alert = 2,
    crit = 3,
    error = 4,
    warn = 5,
    notice = 6,
    info = 7,
    debug = 8,
}

--- vformat
--- @param ... any
--- @return string s
local function vformat(...)
    local s = format(...)
    return s
end

--- printout
--- @param strv string[]
--- @param fmt string
--- @param ... string
--- @return boolean ok
--- @return any err
--- @return any eno
--- @return string msg
local function printout(strv, fmt, ...)
    strv[#strv + 1] = vformat(fmt, ...)

    local msg = concat(strv, ' ')
    local ok, err, eno = WRITE_FN(OUTPUT, msg .. '\n')
    if not ok then
        return false, err, eno, msg
    end
    return true, nil, nil, msg
end

--- printf
--- @param label string
--- @param fmt any
--- @param ... any
--- @return boolean ok
--- @return any err
--- @return any eno
local function printf(label, fmt, ...)
    local strv = {
        -- ISO8601 date format
        format('%s [%s]', date('%FT%T%z'), label),
    }

    -- append call info
    if label == 'debug' or label == 'fatal' or DEBUG then
        local info = getinfo(3, 'Sl')
        if SRCLEN > 0 then
            info.short_src = '...' .. sub(info.short_src, -SRCLEN)
        end
        strv[2] = format('[%s:%d]', info.short_src, info.currentline)

        if fmt == nil and label == 'fatal' then
            fmt = 'fatal error!'
        end
    end

    local ok, err, eno, msg = printout(strv, fmt, ...)
    if label == 'fatal' then
        error(msg, 3)
    end
    return ok, err, eno
end

--- new
--- @param label string
--- @return function
local function new(label)
    assert(LEVELS[label], format('unknown label %q', tostring(label)))
    return function(...)
        if LEVELS[label] <= PRINT_LEVEL then
            local narg = select('#', ...)
            if narg > 0 or LEVELS[label] == 0 then
                local ok, err, eno = printf(label, ...)
                -- prevent tail-call optimization
                return ok, err, eno
            end
        end
    end
end

--- flush
--- @return boolean ok
--- @return any err
--- @return any eno
local function flush()
    local ok, err, eno = FLUSH_FN(OUTPUT)
    if not ok then
        return false, err, eno
    end
    return true
end

--- setoutput
--- @param file file*|string|table|nil
local function setoutput(file)
    local f
    if file == nil then
        -- use default output
        f = assert(output())
    elseif not pcall(function()
        f = assert(output(file))
    end) and not pcall(function()
        assert(type(file.write) == 'function' and type(file.flush) == 'function')
        f = file
    end) then
        error('file must be file*, string or table', 2)
    end

    OUTPUT = f
    WRITE_FN = OUTPUT.write
    FLUSH_FN = OUTPUT.flush
end

--- setlevel
--- @param level string
local function setlevel(level)
    if type(level) ~= 'string' then
        error('level must be string', 2)
    end

    local lv = LEVELS[level]
    if not lv then
        error(format('unsupported print level %q', level), 2)
    end

    PRINT_LEVEL = lv
end

--- setdebug
--- @param enabled boolean
--- @param srclen number?
local function setdebug(enabled, srclen)
    if type(enabled) ~= 'boolean' then
        error('enabled must be boolean', 2)
    elseif srclen ~= nil and type(srclen) ~= 'number' then
        error('srclen must be number or nil', 2)
    end
    DEBUG = enabled
    SRCLEN = srclen or SRCLEN
end

--- call
--- @param ... any
local function call(_, ...)
    printout({}, ...)
end

return setmetatable({}, {
    __call = call,
    __index = {
        flush = flush,
        format = vformat,
        setdebug = setdebug,
        setlevel = setlevel,
        setoutput = setoutput,
        fatal = new('fatal'),
        emerge = new('emerge'),
        alert = new('alert'),
        crit = new('crit'),
        error = new('error'),
        warn = new('warn'),
        notice = new('notice'),
        info = new('info'),
        debug = new('debug'),
    },
})

