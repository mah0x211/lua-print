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
local dump = require('dump')
local concat = table.concat
local date = os.date
local error = error
local find = string.find
local format = string.format
local getinfo = debug.getinfo
local sub = string.sub
local output = io.output
local print = print
local select = select
local type = type
local unpack = unpack or table.unpack
local builtin_tostring = tostring
-- static variables
local DEBUG = false
local PRINT_LEVEL = 7
local LEVELS = {
    [1] = 'emerge',
    [2] = 'alert',
    [3] = 'crit',
    [4] = 'error',
    [5] = 'warn',
    [6] = 'notice',
    [7] = 'info',
    emerge = 1,
    alert = 2,
    crit = 3,
    error = 4,
    warn = 5,
    notice = 6,
    info = 7,
}

--- tostring converts v to string
--- @param v any
--- @return string str
local function tostring(v)
    local t = type(v)

    if t == 'string' then
        return v
    elseif t == 'table' then
        return dump(v, 0)
    end

    return builtin_tostring(v)
end

--- tostringv converts varargs to string and insert it into a string vector
--- @param strv string[]
--- @vararg ...
--- @return string[] strv
local function tostringv(strv, ...)
    local argv = {
        ...,
    }
    local n = #strv
    local narg = select('#', ...)

    -- convert to string
    for i = 1, narg do
        strv[n + i] = tostring(argv[i])
    end

    return strv
end

local STRING_SPECS = {
    q = true,
    s = true,
}

--- count_format_params
--- @param s string
--- @param narg integer
--- @vararg any
--- @return integer n
--- @return any[] params
local function count_format_params(s, narg, ...)
    if type(s) ~= 'string' then
        return 0
    end

    local args = {
        ...,
    }
    local params = {}
    local n = 0
    local head = find(s, '%%')
    while head do
        local spec = sub(s, head + 1, head + 1)
        if spec == '%' then
            -- skip escape
            head = head + 1
        elseif n == narg then
            -- too many format specifier
            return narg, args
        else
            n = n + 1
            params[n] = STRING_SPECS[spec] and tostring(args[n]) or args[n]
        end
        head = find(s, '%%', head + 1)
    end

    return n, params
end

--- stringify
--- @param strv string[]
--- @param narg integer
--- @param fmt string
--- @return string[] strv
local function stringify(strv, narg, fmt, ...)
    local nparam, params = count_format_params(fmt, narg, ...)

    if nparam == 0 then
        tostringv(strv, fmt, ...)
    else
        strv[#strv + 1] = format(fmt, unpack(params))
        if narg > nparam then
            tostringv(strv, select(nparam + 1, ...))
        end
    end

    return strv
end

--- printf
--- @param label string
--- @param narg integer
--- @param fmt string
--- @return function
local function printf(label, narg, fmt, ...)
    local strv = {
        -- ISO8601 date format
        format('%s [%s]', date('%FT%T%z'), label),
    }

    -- append call info
    if DEBUG then
        local info = getinfo(3, 'Sl')
        strv[2] = format('[%s:%d]', info.short_src, info.currentline)
    end

    stringify(strv, narg, fmt, ...)

    local _, err = output():write(concat(strv, ' ') .. '\n')
    if err then
        error(err, 3)
    end
end

--- new
--- @param label string
--- @return function
local function new(label)
    assert(LEVELS[label], format('unknown label %q', tostring(label)))
    return function(...)
        if LEVELS[label] <= PRINT_LEVEL then
            local narg = select('#', ...)
            if narg > 0 then
                printf(label, narg - 1, ...)
            end
        end
    end
end

--- vformat
--- @vararg any
local function vformat(...)
    local narg = select('#', ...)

    if narg == 0 then
        return ''
    elseif narg == 1 then
        return tostring(...)
    end

    return concat(stringify({}, narg - 1, ...), ' ')
end

--- flush
local function flush()
    output():flush()
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
local function setdebug(enabled)
    if type(enabled) ~= 'boolean' then
        error('enabled must be boolean', 2)
    end
    DEBUG = enabled
end

--- call
--- @vararg ...
local function call(_, ...)
    print(vformat(...))
end

return setmetatable({}, {
    __call = call,
    __index = {
        flush = flush,
        format = vformat,
        setdebug = setdebug,
        setlevel = setlevel,
        emerge = new('emerge'),
        alert = new('alert'),
        crit = new('crit'),
        error = new('error'),
        warn = new('warn'),
        notice = new('notice'),
        info = new('info'),
    },
})

