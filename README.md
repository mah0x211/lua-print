# lua-print

[![test](https://github.com/mah0x211/lua-print/actions/workflows/test.yml/badge.svg)](https://github.com/mah0x211/lua-print/actions/workflows/test.yml)
[![Coverage Status](https://coveralls.io/repos/github/mah0x211/lua-print/badge.svg?branch=master)](https://coveralls.io/github/mah0x211/lua-print?branch=master)


the print module.


## Installation

```
luarocks install print
```


## `__call` metamethod

```lua
local print = require('print')
print('hello', 'world')
```

that equivalent to Lua's built-in `print` function.


## print.flush()

this function is equivalent to the following code.

```lua
io.output():flush()
```


## s = print.format( fmt, ... )

this function converts the given arguments to a string.

if the first argument is a format string, the rest of the arguments will be converted according to the format specifiers.


## Print values to the default output file

the following functions are receives any number of arguments and prints their values with `ISO8601 formatted date` and a function name as `label` string to default output file (`io.output()`).

if the first argument is a format string, the rest of the arguments will be converted according to the format specifiers.

- **print.emerge(...)**
- **print.alert(...)**
- **print.crit(...)**
- **print.error(...)**
- **print.warn(...)**
- **print.notice(...)**
- **print.info(...)**

the above functions can limit the output by setting the output level.

- **print.setlevel( label:string )**

The following output levels can be set.

- `'emerge'` `print.emerge` function will be enabled.
- `'alert'`: `print.alert` and the above features will be enabled.
- `'crit'`: `print.crit` and the above features will be enabled.
- `'error'`: `print.error` and the above features will be enabled.
- `'warn'`: `print.warn` and the above features will be enabled.
- `'notice'`: `print.notice` and the above features will be enabled.
- `'info'`: `print.info` and the above features will be enabled.

for example, if you do `setlevel('error')`, `warn`, `notice`, and `info` will not be printed.

```lua
local print = require('print')
print.setlevel('error')
-- the following functions are do not output anything
print.warn('hello warn')
print.notice('hello notice')
print.info('hello info')
```

Also, when debug mode is enabled with the following function, debug information will be added to the output string.

- **print.setdebug( enabled:boolean )**
