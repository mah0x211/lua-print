# lua-print

[![test](https://github.com/mah0x211/lua-print/actions/workflows/test.yml/badge.svg)](https://github.com/mah0x211/lua-print/actions/workflows/test.yml)
[![codecov](https://codecov.io/gh/mah0x211/lua-print/branch/master/graph/badge.svg)](https://codecov.io/gh/mah0x211/lua-print)


the print module.


## Installation

```
luarocks install print
```


## `__call` metamethod

```lua
local print = require('print')
print('print %q', 'hello', 'world') -- print "hello" world
```

the above code is equivalent to the following code;

```lua
local format = require('print').format
print(format('print %q', 'hello', 'world')) -- print "hello" world
```


## ok, err, errnum = print.flush()

this function is equivalent to the following code.

```lua
io.output():flush()
```


## s = print.format( fmt, ... )

this function converts the given arguments to a string.

if the first argument is a format string, the rest of the arguments will be converted according to the format specifiers.


## print.setoutput( [out] )

change the output destination.

**Parameters**

- `out:nil|file*|string|table`: output destination.
    - `nil|file*|string`: equivalent to `io.output(out)`
    - `table`: table must contains the `write` and `flush` functions;
      ```lua
      ok, err, errnum = out.write(out, msg)
      ok, err, errnum = out.flush(out)
      - ok:boolean
      - err:string
      - errnum:integer
      - msg:string
      ```


## Print values

the following functions are receives any number of arguments and prints their values with `ISO8601 formatted date` and a function name as `label` string to output file (default: `io.output()`).

if the first argument is a format string, the rest of the arguments will be converted according to the format specifiers.

- **print.fatal(...)**: throws an `error` after prints their values.  
    - if no arguments are given, the `error` message will be `fatal error!`.
- **ok, err, errnum = print.emerge(...)**
- **ok, err, errnum = print.alert(...)**
- **ok, err, errnum = print.crit(...)**
- **ok, err, errnum = print.error(...)**
- **ok, err, errnum = print.warn(...)**
- **ok, err, errnum = print.notice(...)**
- **ok, err, errnum = print.info(...)**
- **ok, err, errnum = print.debug(...)**: debug information will be added to the output string.

the above functions can limit the output by setting the output level.

- **print.setlevel( label:string )**

The following output levels can be set.

- `'fatal'` `print.fatal` function will be enabled.
- `'emerge'` `print.emerge` and the above functions will be enabled.
- `'alert'`: `print.alert` and the above functions will be enabled.
- `'crit'`: `print.crit` and the above functions will be enabled.
- `'error'`: `print.error` and the above functions will be enabled.
- `'warn'`: `print.warn` and the above functions will be enabled.
- `'notice'`: `print.notice` and the above functions will be enabled.
- `'info'`: `print.info` and the above functions will be enabled. (**default**)
- `'debug'`: `print.debug` and the above functions will be enabled.

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

- **print.setdebug( enabled:boolean [, srclen] )**  
    - `enabled:boolean`: enable debug mode that prints the source pathname and line number.
    - `srclen:integer`: source file length. (**default**: `0` - `<1` means unlimited)

