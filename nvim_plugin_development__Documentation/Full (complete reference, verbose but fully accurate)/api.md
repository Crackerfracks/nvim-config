[

# Api

](https://neovim.io/doc/user/api.html#API)

_Nvim `:help` pages, [generated] from [source] using the [tree-sitter-vimdoc] parser._

* * *

Nvim API [api]

Nvim exposes a powerful API that can be used by plugins and external processes via [RPC], [Lua] and Vimscript .

Applications can also embed libnvim to work with the C API directly.

## API Usage [api-rpc] [RPC] [rpc](https://neovim.io/doc/user/api.html#rpc)

[msgpack-rpc]  
RPC is the main way to control Nvim programmatically. Nvim implements the MessagePack-RPC protocol with these extra (out-of-spec) constraints:

1\. Responses must be given in reverse order of requests (like "unwinding a stack"). 2. Nvim processes all messages (requests and notifications) in the order they are received.

MessagePack-RPC specification: [https://github.com/msgpack-rpc/msgpack-rpc/blob/master/spec.md] [https://github.com/msgpack/msgpack/blob/0b8f5ac/spec.md]

Many clients use the API: user interfaces (GUIs), remote plugins, scripts like "nvr" . Even Nvim itself can control other Nvim instances. API clients can:

Call any API function

Listen for events

Receive remote calls from Nvim

The RPC API is like a more powerful version of Vim's "clientserver" feature.

### CONNECTING [rpc-connecting]

See [channel-intro] for various ways to open a channel. Channel-opening functions take an `rpc` key in the options dict. RPC channels can also be opened by other processes connecting to TCP/IP sockets or named pipes listened to by Nvim.

Nvim creates a default RPC socket at [startup], given by [v:servername]. To start with a TCP/IP socket instead, use [\--listen](https://neovim.io/doc/user/starting.html#--listen) with a TCP-style address:

nvim --listen 127.0.0.1:6666

More endpoints can be started with [serverstart()].

Note that localhost TCP sockets are generally less secure than named pipes, and can lead to vulnerabilities like remote code execution.

Connecting to the socket is the easiest way a programmer can test the API, which can be done through any msgpack-rpc client library or full-featured [api-client]. Here's a Ruby script that prints "hello world!" in the current Nvim instance:

    #!/usr/bin/env ruby
    # Requires msgpack-rpc: gem install msgpack-rpc
    #
    # To run this script, execute it from a running Nvim instance (notice the
    # trailing '&' which is required since Nvim won't process events while
    # running a blocking command):
    #
    #   :!./hello.rb &
    #
    # Or from another shell by setting NVIM_LISTEN_ADDRESS:
    # $ NVIM_LISTEN_ADDRESS=[address] ./hello.rb
    require 'msgpack/rpc'
    require 'msgpack/rpc/transport/unix'
    nvim = MessagePack::RPC::Client.new(MessagePack::RPC::UNIXTransport.new, ENV['NVIM_LISTEN_ADDRESS'])
    result = nvim.call(:nvim_command, 'echo "hello world!"')

A better way is to use the Python REPL with the "pynvim" package, where API functions can be called interactively:

\>>> from pynvim import attach
>>> nvim = attach('socket', path='\[address\]')
>>> nvim.command('echo "hello world!"')

You can also embed Nvim via [jobstart()], and communicate using [rpcrequest()] and [rpcnotify()](https://neovim.io/doc/user/builtin.html#rpcnotify()):

    let nvim = jobstart(['nvim', '--embed'], {'rpc': v:true})
    echo rpcrequest(nvim, 'nvim_eval', '"Hello " . "world!"')
    call jobstop(nvim)

## API Definitions [api-definitions]

[api-types]  
The Nvim C API defines custom types for all function parameters. Some are just typedefs around C99 standard types, others are Nvim-defined data structures.

Basic types

API Type                              C type
------------------------------------------------------------------------
Nil
Boolean                               bool
Integer (signed 64-bit integer)       int64\_t
Float (IEEE 754 double precision)     double
String                                {char\* data, size\_t size} struct
Array                                 kvec
Dict (msgpack: map)                   kvec
Object                                any of the above

**Note:**

Empty Array is accepted as a valid Dictionary parameter.

Functions cannot cross RPC boundaries. But API functions  may support Lua function parameters for non-RPC invocations.

Special types (msgpack EXT)

These are integer typedefs discriminated as separate Object subtypes. They can be treated as opaque integers, but are mutually incompatible: Buffer may be passed as an integer but not as Window or Tabpage.

The EXT object data is the (integer) object handle. The EXT type codes given in the [api-metadata] `types` key are stable: they will not change and are thus forward-compatible.

EXT Type      C type                                  Data
------------------------------------------------------------------------
Buffer        enum value kObjectTypeBuffer            |bufnr()|
Window        enum value kObjectTypeWindow            |window-ID|
Tabpage       enum value kObjectTypeTabpage           internal handle

[api-indexing]  
Most of the API uses 0-based indices, and ranges are end-exclusive. For the end of a range, -1 denotes the last line/column.

Exception: the following API functions use "mark-like" indexing (1-based lines, 0-based columns):

[nvim\_get\_mark()]

[nvim\_buf\_get\_mark()]

[nvim\_buf\_set\_mark()]

[nvim\_win\_get\_cursor()]

[nvim\_win\_set\_cursor()]

Exception: the following API functions use [extmarks] indexing (0-based indices, end-inclusive):

[nvim\_buf\_del\_extmark()]

[nvim\_buf\_get\_extmark\_by\_id()]

[nvim\_buf\_get\_extmarks()]

[nvim\_buf\_set\_extmark()]

[api-fast]  
Most API functions are "deferred": they are queued on the main loop and processed sequentially with normal input. So if the editor is waiting for user input in a "modal" fashion , the request will block. Non-deferred (fast) functions such as [nvim\_get\_mode()] and [nvim\_input()](https://neovim.io/doc/user/api.html#nvim_input()) are served immediately (i.e. without waiting in the input queue). Lua code can use [vim.in\_fast\_event()](https://neovim.io/doc/user/lua.html#vim.in_fast_event()) to detect a fast context.

## API metadata [api-metadata]

The Nvim C API is automatically exposed to RPC by the build system, which parses headers in src/nvim/api/\* and generates dispatch-functions mapping RPC API method names to public C API functions, converting/validating arguments and return values.

Nvim exposes its API metadata as a Dictionary with these items:

version Nvim version, API level/compatibility

version.api\_level API version integer [api-level]

version.api\_compatible API is backwards-compatible with this level

version.api\_prerelease Declares the API as unstable/unreleased `(version.api_prerelease && fn.since == version.api_level)`

functions API function signatures, containing [api-types] info describing the return value and parameters.

ui\_events [UI] event signatures

ui\_options Supported [ui-option]s

`{fn}`.since API level where function `{fn}` was introduced

`{fn}`.deprecated\_since API level where function `{fn}` was deprecated

types Custom handle types defined by Nvim

error\_types Possible error types returned by API functions

About the `functions` map:

Container types may be decorated with type/size constraints, e.g. ArrayOf(Buffer) or ArrayOf(Integer, 2).

Functions considered to be methods that operate on instances of Nvim special types (msgpack EXT) have the "method=true" flag. The receiver type is that of the first argument. Method names are prefixed with `nvim_` plus a type name, e.g. `nvim_buf_get_lines` is the `get_lines` method of a Buffer instance. [dev-api]

Global functions have the "method=false" flag and are prefixed with just `nvim_`, e.g. `nvim_list_bufs`.

[api-mapping]  
External programs (clients) can use the metadata to discover the API, using any of these approaches:

1\. Connect to a running Nvim instance and call [nvim\_get\_api\_info()] via msgpack-RPC. This is best for clients written in dynamic languages which can define functions at runtime.

2\. Start Nvim with [\--api-info]. Useful for statically-compiled clients. Example (requires Python "pyyaml" and "msgpack-python" modules):

nvim --api-info | python -c 'import msgpack, sys, yaml; yaml.dump(msgpack.unpackb(sys.stdin.buffer.read()), sys.stdout)'

3\. Use the [api\_info()] Vimscript function.

    :lua vim.print(vim.fn.api_info())

Example using [filter()] to exclude non-deprecated API functions:

    :new|put =map(filter(api_info().functions, '!has_key(v:val,''deprecated_since'')'), 'v:val.name')

## API contract [api-contract]

The Nvim API is composed of functions and events.

Clients call functions like those described at [api-global].

Clients can subscribe to [ui-events], [api-buffer-updates], etc.

API function names are prefixed with "nvim\_".

API event names are prefixed with "nvim\_" and suffixed with "\_event".

As Nvim evolves the API may change in compliance with this CONTRACT:

New functions and events may be added.

Any such extensions are OPTIONAL: old clients may ignore them.

Function signatures will NOT CHANGE (after release).

Functions introduced in the development (unreleased) version MAY CHANGE. 

Event parameters will not be removed or reordered (after release).

Events may be EXTENDED: new parameters may be added.

New items may be ADDED to map/list parameters/results of functions and events.

Any such new items are OPTIONAL: old clients may ignore them.

Existing items will not be removed (after release).

**Deprecated** functions will not be removed until Nvim version 2.0

"Private" interfaces are NOT covered by this contract:

Undocumented (not in :help) functions or events of any kind

nvim\_\_x ("double underscore") functions

The idea is "versionless evolution", in the words of Rich Hickey:

Relaxing a requirement should be a compatible change.

Strengthening a promise should be a compatible change.

## Global events [api-global-events]

When a client invokes an API request as an async notification, it is not possible for Nvim to send an error response. Instead, in case of error, the following notification will be sent to the client:

[nvim\_error\_event]  
nvim\_error\_event\[`{type}`, `{message}`\]

`{type}` is a numeric id as defined by `api_info().error_types`, and `{message}` is a string with the error message.

## Buffer update events [api-buffer-updates]

API clients can "attach" to Nvim buffers to subscribe to buffer update events. This is similar to [TextChanged] but more powerful and granular.

Call [nvim\_buf\_attach()] to receive these events on the channel:

[nvim\_buf\_lines\_event]  
nvim\_buf\_lines\_event\[`{buf}`, `{changedtick}`, `{firstline}`, `{lastline}`, `{linedata}`, `{more}`\]

When the buffer text between `{firstline}` and `{lastline}` (end-exclusive, zero-indexed) were changed to the new text in the `{linedata}` list. The granularity is a line, i.e. if a single character is changed in the editor, the entire line is sent.

When `{changedtick}` is [v:null] this means the screen lines (display) changed but not the buffer contents. `{linedata}` contains the changed screen lines. This happens when ['inccommand'] shows a buffer preview.

Properties:

`{buf}` API buffer handle (buffer number)

`{changedtick}` value of [b:changedtick] for the buffer. If you send an API command back to nvim you can check the value of [b:changedtick] as part of your request to ensure that no other changes have been made.

`{firstline}` integer line number of the first line that was replaced. Zero-indexed: if line 1 was replaced then `{firstline}` will be 0, not 1. `{firstline}` is always less than or equal to the number of lines that were in the buffer before the lines were replaced.

`{lastline}` integer line number of the first line that was not replaced (i.e. the range `{firstline}`, `{lastline}` is end-exclusive). Zero-indexed: if line numbers 2 to 5 were replaced, this will be 5 instead of 6. `{lastline}` is always be less than or equal to the number of lines that were in the buffer before the lines were replaced. `{lastline}` will be -1 if the event is part of the initial update after attaching.

`{linedata}` list of strings containing the contents of the new buffer lines. Newline characters are omitted; empty lines are sent as empty strings.

`{more}` boolean, true for a "multipart" change notification: the current change was chunked into multiple [nvim\_buf\_lines\_event] notifications (e.g. because it was too big).

nvim\_buf\_changedtick\_event\[`{buf}`, `{changedtick}`\] [nvim\_buf\_changedtick\_event]

When [b:changedtick] was incremented but no text was changed. Relevant for undo/redo.

Properties:

`{buf}` API buffer handle (buffer number) `{changedtick}` new value of [b:changedtick] for the buffer

nvim\_buf\_detach\_event\[`{buf}`\] [nvim\_buf\_detach\_event]  

When buffer is detached (i.e. updates are disabled). Triggered explicitly by [nvim\_buf\_detach()] or implicitly in these cases:

Buffer was [abandon]ed and ['hidden'] is not set.

Buffer was reloaded, e.g. with [:edit] or an external change triggered [:checktime] or ['autoread'](https://neovim.io/doc/user/options.html#'autoread').

Generally: whenever the buffer contents are unloaded from memory.

Properties:

`{buf}` API buffer handle (buffer number)

EXAMPLE

Calling [nvim\_buf\_attach()] with send\_buffer=true on an empty buffer, emits:

nvim\_buf\_lines\_event\[{buf}, {changedtick}, 0, -1, \[""\], v:false\]

User adds two lines to the buffer, emits:

nvim\_buf\_lines\_event\[{buf}, {changedtick}, 0, 0, \["line1", "line2"\], v:false\]

User moves to a line containing the text "Hello world" and inserts "!", emits:

nvim\_buf\_lines\_event\[{buf}, {changedtick}, {linenr}, {linenr} + 1,
                     \["Hello world!"\], v:false\]

User moves to line 3 and deletes 20 lines using "20dd", emits:

nvim\_buf\_lines\_event\[{buf}, {changedtick}, 2, 22, \[\], v:false\]

User selects lines 3-5 using [linewise-visual] mode and then types "p" to paste a block of 6 lines, emits:

nvim\_buf\_lines\_event\[{buf}, {changedtick}, 2, 5,
  \['pasted line 1', 'pasted line 2', 'pasted line 3', 'pasted line 4',
   'pasted line 5', 'pasted line 6'\],
  v:false
\]

User reloads the buffer with ":edit", emits:

nvim\_buf\_detach\_event\[{buf}\]

LUA

[api-buffer-updates-lua]  
In-process Lua plugins can receive buffer updates in the form of Lua callbacks. These callbacks are called frequently in various contexts; [textlock] prevents changing buffer contents and window layout . Moving the cursor is allowed, but it is restored afterwards.

[nvim\_buf\_attach()] will take keyword args for the callbacks. "on\_lines" will receive parameters ("lines", `{buf}`, `{changedtick}`, `{firstline}`, `{lastline}`, `{new_lastline}`, `{old_byte_size}` \[, `{old_utf32_size}`, `{old_utf16_size}`\]). Unlike remote channel events the text contents are not passed. The new text can be accessed inside the callback as

    vim.api.nvim_buf_get_lines(buf, firstline, new_lastline, true)

`{old_byte_size}` is the total size of the replaced region `{firstline}` to `{lastline}` in bytes, including the final newline after `{lastline}`. if `utf_sizes` is set to true in [nvim\_buf\_attach()] keyword args, then the UTF-32 and UTF-16 sizes of the deleted region is also passed as additional arguments `{old_utf32_size}` and `{old_utf16_size}`.

"on\_changedtick" is invoked when [b:changedtick] was incremented but no text was changed. The parameters received are ("changedtick", `{buf}`, `{changedtick}`).

[api-lua-detach]  
In-process Lua callbacks can detach by returning `true`. This will detach all callbacks attached with the same [nvim\_buf\_attach()] call.

## Buffer highlighting [api-highlights]

Nvim allows plugins to add position-based highlights to buffers. This is similar to [matchaddpos()] but with some key differences. The added highlights are associated with a buffer and adapts to line insertions and deletions, similar to signs. It is also possible to manage a set of highlights as a group and delete or replace all at once.

The intended use case are linter or semantic highlighter plugins that monitor a buffer for changes, and in the background compute highlights to the buffer. Another use case are plugins that show output in an append-only buffer, and want to add highlights to the outputs. Highlight data cannot be preserved on writing and loading a buffer to file, nor in undo/redo cycles.

Highlights are registered using the [nvim\_buf\_set\_extmark()] function, which adds highlights as [extmarks]. If highlights need to be tracked or manipulated after adding them, the returned [extmark](https://neovim.io/doc/user/api.html#extmark) id can be used.

    -- create the highlight through an extmark
    extid = vim.api.nvim_buf_set_extmark(buf, ns_id, line, col_start, {end_col = col_end, hl_group = hl_group})
    -- example: modify the extmark's highlight group
    vim.api.nvim_buf_set_extmark(buf, ns_id, line, col_start, {end_col = col_end, hl_group = NEW_HL_GROUP, id = extid})
    -- example: change the highlight's position
    vim.api.nvim_buf_set_extmark(buf, ns_id, NEW_LINE, col_start, {end_col = col_end, hl_group = NEW_HL_GROUP, id = extid})

See also [vim.hl.range()].

## Floating windows [api-floatwin] [floating-windows]

Floating windows ("floats") are displayed on top of normal windows. This is useful to implement simple widgets, such as tooltips displayed next to the cursor. Floats are fully functional windows supporting user editing, common [api-window] calls, and most window options .

Two ways to create a floating window:

[nvim\_open\_win()] creates a new window 

[nvim\_win\_set\_config()] reconfigures a normal window into a float

To close it use [nvim\_win\_close()] or a command such as [:close].

To check whether a window is floating, check whether the `relative` option in its config is non-empty:

    if vim.api.nvim_win_get_config(window_id).relative ~= '' then
      -- window with this window_id is floating
    end

Buffer text can be highlighted by typical mechanisms . The [hl-NormalFloat] group highlights normal text; ['winhighlight'](https://neovim.io/doc/user/options.html#'winhighlight') can be used as usual to override groups locally. Floats inherit options from the current window; specify `style=minimal` in [nvim\_open\_win()](https://neovim.io/doc/user/api.html#nvim_open_win()) to disable various visual features such as the ['number'](https://neovim.io/doc/user/options.html#'number') column.

Other highlight groups specific to floating windows:

[hl-FloatBorder] for window's border

[hl-FloatTitle] for window's title

[hl-FloatFooter] for window's footer

Currently, floating windows don't support some widgets like scrollbar.

The output of [:mksession] does not include commands for restoring floating windows.

Example: create a float with scratch buffer:

    let buf = nvim_create_buf(v:false, v:true)
    call nvim_buf_set_lines(buf, 0, -1, v:true, ["test", "text"])
    let opts = {'relative': 'cursor', 'width': 10, 'height': 2, 'col': 0,
        \ 'row': 1, 'anchor': 'NW', 'style': 'minimal'}
    let win = nvim_open_win(buf, 0, opts)
    " optional: change highlight, otherwise Pmenu is used
    call nvim_set_option_value('winhl', 'Normal:MyHighlight', {'win': win})

## Extended marks [api-extended-marks] [extmarks] [extmark](https://neovim.io/doc/user/api.html#extmark)

Extended marks (extmarks) represent buffer annotations that track text changes in the buffer. They can represent cursors, folds, misspelled words, anything that needs to track a logical location in the buffer over time. [api-indexing]

Extmark position works like a "vertical bar" cursor: it exists between characters. Thus, the maximum extmark index on a line is 1 more than the character index:

 f o o b a r      line contents
 0 1 2 3 4 5      character positions (0-based)
0 1 2 3 4 5 6     extmark positions (0-based)

Extmarks have "forward gravity": if you place the cursor directly on an extmark position and enter some text, the extmark migrates forward.

f o o|b a r      line (| = cursor)
     3           extmark
f o o z|b a r    line (| = cursor)
       4         extmark (after typing "z")

If an extmark is on the last index of a line and you input a newline at that point, the extmark will accordingly migrate to the next line:

f o o z b a r|   line (| = cursor)
             7   extmark
f o o z b a r    first line
                 extmarks (none present)
|                second line (| = cursor)
0                extmark (after typing <CR>)

Example:

Let's set an extmark at the first row (row=0) and third column (column=2). [api-indexing] Passing id=0 creates a new mark and returns the id:

  01 2345678
0 ex|ample..
    ^ extmark position

    let g:mark_ns = nvim_create_namespace('myplugin')
    let g:mark_id = nvim_buf_set_extmark(0, g:mark_ns, 0, 2, {})

We can get the mark by its id:

    echo nvim_buf_get_extmark_by_id(0, g:mark_ns, g:mark_id, {})
    " => [0, 2]

We can get all marks in a buffer by [namespace] (or by a range):

    echo nvim_buf_get_extmarks(0, g:mark_ns, 0, -1, {})
    " => [[1, 0, 2]]

Deleting all surrounding text does NOT remove an extmark! To remove extmarks use [nvim\_buf\_del\_extmark()]. Deleting "x" in our example:

  0 12345678
0 e|ample..
   ^ extmark position

    echo nvim_buf_get_extmark_by_id(0, g:mark_ns, g:mark_id, {})
    " => [0, 1]

**Note:** Extmark "gravity" decides how it will shift after a text edit. See [nvim\_buf\_set\_extmark()]

Namespaces allow any plugin to manage only its own extmarks, ignoring those created by another plugin.

Extmark positions changed by an edit will be restored on undo/redo. Creating and deleting extmarks is not a buffer change, thus new undo states are not created for extmark changes.

## Global Functions [api-global]

nvim\_chan\_send(`{chan}`, `{data}`) [nvim\_chan\_send()]  
Send data to channel `id`. For a job, it writes it to the stdin of the process. For the stdio channel [channel-stdio], it writes to Nvim's stdout. For an internal terminal instance  it writes directly to terminal output. See [channel-bytes](https://neovim.io/doc/user/channel.html#channel-bytes) for more information.

This function writes raw data, not RPC messages. If the channel was created with `rpc=true` then the channel expects RPC messages, use [vim.rpcnotify()] and [vim.rpcrequest()] instead.

Attributes:

[RPC] only Lua [vim.api] only Since: 0.5.0

Parameters:

`{chan}` id of the channel

`{data}` data to write. 8-bit clean: can contain NUL bytes.

nvim\_create\_buf(`{listed}`, `{scratch}`) [nvim\_create\_buf()]  
Creates a new, empty, unnamed buffer.

Attributes:

Since: 0.4.0

Parameters:

`{listed}` Sets ['buflisted']

`{scratch}` Creates a "throwaway" [scratch-buffer] for temporary work . Also sets ['nomodeline'](https://neovim.io/doc/user/options.html#'nomodeline') on the buffer.

Return:

Buffer id, or 0 on error

See also:

buf\_open\_scratch

nvim\_del\_current\_line() [nvim\_del\_current\_line()]  
Deletes the current line.

Attributes:

not allowed when [textlock] is active Since: 0.1.0

nvim\_del\_keymap(`{mode}`, `{lhs}`) [nvim\_del\_keymap()]  
Unmaps a global [mapping] for the given mode.

To unmap a buffer-local mapping, use [nvim\_buf\_del\_keymap()].

Attributes:

Since: 0.4.0

See also:

[nvim\_set\_keymap()]

nvim\_del\_mark(`{name}`) [nvim\_del\_mark()]  
Deletes an uppercase/file named mark. See [mark-motions].

**Note:**

Lowercase name (or other buffer-local mark) is an error.

Attributes:

Since: 0.6.0

Parameters:

`{name}` Mark name

Return:

true if the mark was deleted, else false.

See also:

[nvim\_buf\_del\_mark()]

[nvim\_get\_mark()]

nvim\_del\_var(`{name}`) [nvim\_del\_var()]  
Removes a global (g:) variable.

Attributes:

Since: 0.1.0

Parameters:

`{name}` Variable name

nvim\_echo(`{chunks}`, `{history}`, `{opts}`) [nvim\_echo()]  
Prints a message given by a list of `[text, hl_group]` "chunks".

Example:

    vim.api.nvim_echo({ { 'chunk1-line1\nchunk1-line2\n' }, { 'chunk2-line1' } }, true, {})

Attributes:

Since: 0.5.0

Parameters:

`{chunks}` List of `[text, hl_group]` pairs, where each is a `text` string highlighted by the (optional) name or ID `hl_group`.

`{history}` if true, add to [message-history].

`{opts}` Optional parameters.

err: Treat the message like `:echoerr`. Sets `hl_group` to [hl-ErrorMsg] by default.

kind: Set the [ui-messages] kind with which this message will be emitted.

verbose: Message is controlled by the ['verbose'] option. Nvim invoked with `-V3log` will write the message to the "log" file instead of standard output.

nvim\_eval\_statusline(`{str}`, `{opts}`) [nvim\_eval\_statusline()]  
Evaluates statusline string.

Attributes:

[api-fast] Since: 0.6.0

Parameters:

`{str}` Statusline string .

`{opts}` Optional parameters.

winid: (number) [window-ID] of the window to use as context for statusline.

maxwidth: (number) Maximum width of statusline.

fillchar: (string) Character to fill blank spaces in the statusline . Treated as single-width even if it isn't.

highlights: (boolean) Return highlight information.

use\_winbar: (boolean) Evaluate winbar instead of statusline.

use\_tabline: (boolean) Evaluate tabline instead of statusline. When true, `{winid}` is ignored. Mutually exclusive with `{use_winbar}`.

use\_statuscol\_lnum: (number) Evaluate statuscolumn for this line number instead of statusline.

Return:

Dict containing statusline information, with these keys:

str: (string) Characters that will be displayed on the statusline.

width: (number) Display width of the statusline.

highlights: Array containing highlight information of the statusline. Only included when the "highlights" key in `{opts}` is true. Each element of the array is a [Dict] with these keys:

start: (number) Byte index (0-based) of first character that uses the highlight.

group: (string) **Deprecated**. Use `groups` instead.

groups: (array) Names of stacked highlight groups (highest priority last).

nvim\_exec\_lua(`{code}`, `{args}`) [nvim\_exec\_lua()]  
Execute Lua code. Parameters (if any) are available as `...` inside the chunk. The chunk can return a value.

Only statements are executed. To evaluate an expression, prefix it with `return`: return my\_function(...)

Attributes:

[RPC] only Since: 0.5.0

Parameters:

`{code}` Lua code to execute

`{args}` Arguments to the code

Return:

Return value of Lua code if present or NIL.

nvim\_feedkeys(`{keys}`, `{mode}`, `{escape_ks}`) [nvim\_feedkeys()]  
Sends input-keys to Nvim, subject to various quirks controlled by `mode` flags. This is a blocking call, unlike [nvim\_input()].

On execution error: does not fail, but updates v:errmsg.

To input sequences like `<C-o>` use [nvim\_replace\_termcodes()] (typically with escape\_ks=false) to replace [keycodes], then pass the result to nvim\_feedkeys().

Example:

    :let key = nvim_replace_termcodes("<C-o>", v:true, v:false, v:true)
    :call nvim_feedkeys(key, 'n', v:false)

Attributes:

Since: 0.1.0

Parameters:

`{keys}` to be typed

`{mode}` behavior flags, see [feedkeys()]

`{escape_ks}` If true, escape K\_SPECIAL bytes in `keys`. This should be false if you already used [nvim\_replace\_termcodes()], and true otherwise.

See also:

feedkeys()

vim\_strsave\_escape\_ks

nvim\_get\_api\_info() [nvim\_get\_api\_info()]  
Returns a 2-tuple (Array), where item 0 is the current channel id and item 1 is the [api-metadata] map (Dict).

Attributes:

[api-fast] [RPC] only Since: 0.1.0

Return:

2-tuple `[{channel-id}, {api-metadata}]`

nvim\_get\_chan\_info(`{chan}`) [nvim\_get\_chan\_info()]  
Gets information about a channel.

See [nvim\_list\_uis()] for an example of how to get channel info.

Attributes:

Since: 0.3.0

Parameters:

`{chan}` channel\_id, or 0 for current channel

Return:

Channel info dict with these keys:

"id" Channel id.

"argv" (optional) Job arguments list.

"stream" Stream underlying the channel.

"stdio" stdin and stdout of this Nvim instance

"stderr" stderr of this Nvim instance

"socket" TCP/IP socket or named pipe

"job" Job with communication over its stdio.

"mode" How data received on the channel is interpreted.

"bytes" Send and receive raw bytes.

"terminal" [terminal] instance interprets ASCII sequences.

"rpc" [RPC] communication on the channel is active.

"pty" (optional) Name of pseudoterminal. On a POSIX system this is a device path like "/dev/pts/1". If unknown, the key will still be present if a pty is used (e.g. for conpty on Windows).

"buffer" (optional) Buffer connected to [terminal] instance.

"client" (optional) Info about the peer (client on the other end of the channel), as set by [nvim\_set\_client\_info()].

nvim\_get\_color\_by\_name(`{name}`) [nvim\_get\_color\_by\_name()]  
Returns the 24-bit RGB value of a [nvim\_get\_color\_map()] color name or "#rrggbb" hexadecimal string.

Example:

    :echo nvim_get_color_by_name("Pink")
    :echo nvim_get_color_by_name("#cbcbcb")

Attributes:

Since: 0.1.0

Parameters:

`{name}` Color name or "#rrggbb" string

Return:

24-bit RGB value, or -1 for invalid argument.

nvim\_get\_color\_map() [nvim\_get\_color\_map()]  
Returns a map of color names and RGB values.

Keys are color names (e.g. "Aqua") and values are 24-bit RGB color values (e.g. 65535).

Attributes:

Since: 0.1.0

Return:

Map of color names and RGB values.

nvim\_get\_context(`{opts}`) [nvim\_get\_context()]  
Gets a map of the current editor state.

Attributes:

Since: 0.4.0

Parameters:

`{opts}` Optional parameters.

types: List of [context-types] ("regs", "jumps", "bufs", "gvars", …) to gather, or empty for "all".

Return:

map of global [context].

nvim\_get\_current\_buf() [nvim\_get\_current\_buf()]  
Gets the current buffer.

Attributes:

Since: 0.1.0

Return:

Buffer id

nvim\_get\_current\_line() [nvim\_get\_current\_line()]  
Gets the current line.

Attributes:

Since: 0.1.0

Return:

Current line string

nvim\_get\_current\_tabpage() [nvim\_get\_current\_tabpage()]  
Gets the current tabpage.

Attributes:

Since: 0.1.0

Return:

[tab-ID]

nvim\_get\_current\_win() [nvim\_get\_current\_win()]  
Gets the current window.

Attributes:

Since: 0.1.0

Return:

[window-ID]

nvim\_get\_hl(`{ns_id}`, `{opts}`) [nvim\_get\_hl()]  
Gets all or specific highlight groups in a namespace.

**Note:**

When the `link` attribute is defined in the highlight definition map, other attributes will not be taking effect .

Attributes:

Since: 0.9.0

Parameters:

`{ns_id}` Get highlight groups for namespace ns\_id [nvim\_get\_namespaces()]. Use 0 to get global highlight groups [:highlight].

`{opts}` Options dict:

name: (string) Get a highlight definition by name.

id: (integer) Get a highlight definition by id.

link: (boolean, default true) Show linked group name instead of effective definition [:hi-link].

create: (boolean, default true) When highlight group doesn't exist create it.

Return:

Highlight groups as a map from group name to a highlight definition map as in [nvim\_set\_hl()], or only a single highlight definition map if requested by name or id.

nvim\_get\_hl\_id\_by\_name(`{name}`) [nvim\_get\_hl\_id\_by\_name()]  
Gets a highlight group by name

similar to [hlID()], but allocates a new ID if not present.

Attributes:

Since: 0.5.0

nvim\_get\_hl\_ns(`{opts}`) [nvim\_get\_hl\_ns()]  
Gets the active highlight namespace.

Attributes:

Since: 0.10.0

Parameters:

`{opts}` Optional parameters

winid: (number) [window-ID] for retrieving a window's highlight namespace. A value of -1 is returned when [nvim\_win\_set\_hl\_ns()] has not been called for the window (or was called with a namespace of -1).

Return:

Namespace id, or -1

nvim\_get\_keymap(`{mode}`) [nvim\_get\_keymap()]  
Gets a list of global (non-buffer-local) [mapping] definitions.

Attributes:

Since: 0.2.1

Parameters:

`{mode}` Mode short-name ("n", "i", "v", ...)

Return:

Array of [maparg()]\-like dictionaries describing mappings. The "buffer" key is always zero.

nvim\_get\_mark(`{name}`, `{opts}`) [nvim\_get\_mark()]  
Returns a `(row, col, buffer, buffername)` tuple representing the position of the uppercase/file named mark. "End of line" column position is returned as [v:maxcol] (big number). See [mark-motions].

Marks are (1,0)-indexed. [api-indexing]

**Note:**

Lowercase name (or other buffer-local mark) is an error.

Attributes:

Since: 0.6.0

Parameters:

`{name}` Mark name

`{opts}` Optional parameters. Reserved for future use.

Return:

4-tuple (row, col, buffer, buffername), (0, 0, 0, '') if the mark is not set.

See also:

[nvim\_buf\_set\_mark()]

[nvim\_del\_mark()]

nvim\_get\_mode() [nvim\_get\_mode()]  
Gets the current mode. [mode()] "blocking" is true if Nvim is waiting for input.

Attributes:

[api-fast] Since: 0.2.0

Return:

Dict { "mode": String, "blocking": Boolean }

nvim\_get\_proc(`{pid}`) [nvim\_get\_proc()]  
Gets info describing process `pid`.

Attributes:

Since: 0.3.0

Return:

Map of process properties, or NIL if process not found.

nvim\_get\_proc\_children(`{pid}`) [nvim\_get\_proc\_children()]  
Gets the immediate children of process `pid`.

Attributes:

Since: 0.3.0

Return:

Array of child process ids, empty if process not found.

nvim\_get\_runtime\_file(`{name}`, `{all}`) [nvim\_get\_runtime\_file()]  
Finds files in runtime directories, in ['runtimepath'] order.

"name" can contain wildcards. For example `nvim_get_runtime_file("colors/*.{vim,lua}", true)` will return all color scheme files. Always use forward slashes (/) in the search pattern for subdirectories regardless of platform.

It is not an error to not find any files. An empty array is returned then.

Attributes:

[api-fast] Since: 0.5.0

Parameters:

`{name}` pattern of files to search for

`{all}` whether to return all matches or only the first

Return:

list of absolute paths to the found files

nvim\_get\_var(`{name}`) [nvim\_get\_var()]  
Gets a global (g:) variable.

Attributes:

Since: 0.1.0

Parameters:

`{name}` Variable name

Return:

Variable value

nvim\_get\_vvar(`{name}`) [nvim\_get\_vvar()]  
Gets a v: variable.

Attributes:

Since: 0.1.0

Parameters:

`{name}` Variable name

Return:

Variable value

nvim\_input(`{keys}`) [nvim\_input()]  
Queues raw user-input. Unlike [nvim\_feedkeys()], this uses a low-level input buffer and the call is non-blocking (input is processed asynchronously by the eventloop).

To input blocks of text, [nvim\_paste()] is much faster and should be preferred.

On execution error: does not fail, but updates v:errmsg.

**Note:**

[keycodes] like `<CR>` are translated, so "<" is special. To input a literal "<", send `<LT>`.

For mouse events use [nvim\_input\_mouse()]. The pseudokey form `<LeftMouse><col,row>` is deprecated since [api-level] 6.

Attributes:

[api-fast] Since: 0.1.0

Parameters:

`{keys}` to be typed

Return:

Number of bytes actually written (can be fewer than requested if the buffer becomes full).

[nvim\_input\_mouse()]  
nvim\_input\_mouse(`{button}`, `{action}`, `{modifier}`, `{grid}`, `{row}`, `{col}`) Send mouse event from GUI.

Non-blocking: does not wait on any result, but queues the event to be processed soon by the event loop.

**Note:**

Currently this doesn't support "scripting" multiple mouse events by calling it multiple times in a loop: the intermediate mouse positions will be ignored. It should be used to implement real-time mouse input in a GUI. The deprecated pseudokey form (`<LeftMouse><col,row>`) of [nvim\_input()] has the same limitation.

Attributes:

[api-fast] Since: 0.4.0

Parameters:

`{button}` Mouse button: one of "left", "right", "middle", "wheel", "move", "x1", "x2".

`{action}` For ordinary buttons, one of "press", "drag", "release". For the wheel, one of "up", "down", "left", "right". Ignored for "move".

`{modifier}` String of modifiers each represented by a single char. The same specifiers are used as for a key press, except that the "-" separator is optional, so "C-A-", "c-a" and "CA" can all be used to specify Ctrl+Alt+click.

`{grid}` Grid number if the client uses [ui-multigrid], else 0.

`{row}` Mouse row-position (zero-based, like redraw events)

`{col}` Mouse column-position (zero-based, like redraw events)

nvim\_list\_bufs() [nvim\_list\_bufs()]  
Gets the current list of buffers.

Includes unlisted (unloaded/deleted) buffers, like `:ls!`. Use [nvim\_buf\_is\_loaded()] to check if a buffer is loaded.

Attributes:

Since: 0.1.0

Return:

List of buffer ids

nvim\_list\_chans() [nvim\_list\_chans()]  
Get information about all open channels.

Attributes:

Since: 0.3.0

Return:

Array of Dictionaries, each describing a channel with the format specified at [nvim\_get\_chan\_info()].

nvim\_list\_runtime\_paths() [nvim\_list\_runtime\_paths()]  
Gets the paths contained in [runtime-search-path].

Attributes:

Since: 0.1.0

Return:

List of paths

nvim\_list\_tabpages() [nvim\_list\_tabpages()]  
Gets the current list of [tab-ID]s.

Attributes:

Since: 0.1.0

Return:

List of [tab-ID]s

nvim\_list\_uis() [nvim\_list\_uis()]  
Gets a list of dictionaries representing attached UIs.

Example: The Nvim builtin [TUI] sets its channel info as described in [startup-tui]. In particular, it sets `client.name` to "nvim-tui". So you can check if the TUI is running by inspecting the client name of each UI:

    vim.print(vim.api.nvim_get_chan_info(vim.api.nvim_list_uis()[1].chan).client.name)

Attributes:

Since: 0.3.0

Return:

Array of UI dictionaries, each with these keys:

"height" Requested height of the UI

"width" Requested width of the UI

"rgb" true if the UI uses RGB colors 

"ext\_..." Requested UI extensions, see [ui-option]

"chan" [channel-id] of remote UI

nvim\_list\_wins() [nvim\_list\_wins()]  
Gets the current list of all [window-ID]s in all tabpages.

Attributes:

Since: 0.1.0

Return:

List of [window-ID]s

nvim\_load\_context(`{dict}`) [nvim\_load\_context()]  
Sets the current editor state from the given [context] map.

Attributes:

Since: 0.4.0

Parameters:

`{dict}` [Context] map.

nvim\_open\_term(`{buffer}`, `{opts}`) [nvim\_open\_term()]  
Open a terminal instance in a buffer

By default (and currently the only option) the terminal will not be connected to an external process. Instead, input sent on the channel will be echoed directly by the terminal. This is useful to display ANSI terminal sequences returned as part of an RPC message, or similar.

**Note:** to directly initiate the terminal using the right size, display the buffer in a configured window before calling this. For instance, for a floating display, first create an empty buffer using [nvim\_create\_buf()], then display it using [nvim\_open\_win()], and then call this function. Then [nvim\_chan\_send()](https://neovim.io/doc/user/api.html#nvim_chan_send()) can be called immediately to process sequences in a virtual terminal having the intended size.

Example: this `TermHl` command can be used to display and highlight raw ANSI termcodes, so you can use Nvim as a "scrollback pager" (for terminals like kitty): [ansi-colorize] [terminal-scrollback-pager]

    vim.api.nvim_create_user_command('TermHl', function()
      local b = vim.api.nvim_create_buf(false, true)
      local chan = vim.api.nvim_open_term(b, {})
      vim.api.nvim_chan_send(chan, table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n'))
      vim.api.nvim_win_set_buf(0, b)
    end, { desc = 'Highlights ANSI termcodes in curbuf' })

Attributes:

not allowed when [textlock] is active Since: 0.5.0

Parameters:

`{buffer}` Buffer to use. Buffer contents (if any) will be written to the PTY.

`{opts}` Optional parameters.

on\_input: Lua callback for input sent, i e keypresses in terminal mode. **Note:** keypresses are sent raw as they would be to the pty master end. For instance, a carriage return is sent as a "\\r", not as a "\\n". [textlock] applies. It is possible to call [nvim\_chan\_send()] directly in the callback however. `["input", term, bufnr, data]`

force\_crlf: (boolean, default true) Convert "\\n" to "\\r\\n".

Return:

Channel id, or 0 on error

nvim\_paste(`{data}`, `{crlf}`, `{phase}`) [nvim\_paste()]  
Pastes at cursor (in any mode), and sets "redo" so dot  will repeat the input. UIs call this to implement "paste", but it's also intended for use by scripts to input large, dot-repeatable blocks of text .

Invokes the [vim.paste()] handler, which handles each mode appropriately.

Errors  are reflected in `err` but do not affect the return value (which is strictly decided by `vim.paste()`). On error or cancel, subsequent calls are ignored ("drained") until the next paste is initiated (phase 1 or -1).

Useful in mappings and scripts to insert multiline text. Example:

    vim.keymap.set('n', 'x', function()
      vim.api.nvim_paste([[
        line1
        line2
        line3
      ]], false, -1)
    end, { buffer = true })

Attributes:

not allowed when [textlock] is active Since: 0.4.0

Parameters:

`{data}` Multiline input. Lines break at LF ("\\n"). May be binary (containing NUL bytes).

`{crlf}` Also break lines at CR and CRLF.

`{phase}` -1: paste in a single call (i.e. without streaming). To "stream" a paste, call `nvim_paste` sequentially with these `phase` values:

1: starts the paste (exactly once)

2: continues the paste (zero or more times)

3: ends the paste (exactly once)

Return:

true: Client may continue pasting.

false: Client should cancel the paste.

nvim\_put(`{lines}`, `{type}`, `{after}`, `{follow}`) [nvim\_put()]  
Puts text at cursor, in any mode. For dot-repeatable input, use [nvim\_paste()].

Compare [:put] and [p] which are always linewise.

Attributes:

not allowed when [textlock] is active Since: 0.4.0

Parameters:

`{lines}` [readfile()]\-style list of lines. [channel-lines]

`{type}` Edit behavior: any [getregtype()] result, or:

"b" [blockwise-visual] mode (may include width, e.g. "b3")

"c" [charwise] mode

"l" [linewise] mode

"" guess by contents, see [setreg()]

`{after}` If true insert after cursor , or before .

`{follow}` If true place cursor at end of inserted text.

[nvim\_replace\_termcodes()]  
nvim\_replace\_termcodes(`{str}`, `{from_part}`, `{do_lt}`, `{special}`) Replaces terminal codes and [keycodes] (`<CR>`, `<Esc>`, ...) in a string with the internal representation.

Attributes:

Since: 0.1.0

Parameters:

`{str}` String to be converted.

`{from_part}` Legacy Vim parameter. Usually true.

`{do_lt}` Also translate `<lt>`. Ignored if `special` is false.

`{special}` Replace [keycodes], e.g. `<CR>` becomes a "\\r" char.

See also:

replace\_termcodes

cpoptions

[nvim\_select\_popupmenu\_item()]  
nvim\_select\_popupmenu\_item(`{item}`, `{insert}`, `{finish}`, `{opts}`) Selects an item in the completion popup menu.

If neither [ins-completion] nor [cmdline-completion] popup menu is active this API call is silently ignored. Useful for an external UI using [ui-popupmenu](https://neovim.io/doc/user/ui.html#ui-popupmenu) to control the popup menu with the mouse. Can also be used in a mapping; use `<Cmd>` [:map-cmd](https://neovim.io/doc/user/map.html#%3Amap-cmd) or a Lua mapping to ensure the mapping doesn't end completion mode.

Attributes:

Since: 0.4.0

Parameters:

`{item}` Index (zero-based) of the item to select. Value of -1 selects nothing and restores the original text.

`{insert}` For [ins-completion], whether the selection should be inserted in the buffer. Ignored for [cmdline-completion].

`{finish}` Finish the completion and dismiss the popup menu. Implies `{insert}`.

`{opts}` Optional parameters. Reserved for future use.

[nvim\_set\_client\_info()]  
nvim\_set\_client\_info(`{name}`, `{version}`, `{type}`, `{methods}`, `{attributes}`) Self-identifies the client, and sets optional flags on the channel. Defines the `client` object returned by [nvim\_get\_chan\_info()].

Clients should call this just after connecting, to provide hints for debugging and orchestration. (**Note:** Something is better than nothing! Fields are optional, but at least set `name`.)

Can be called more than once; the caller should merge old info if appropriate. Example: library first identifies the channel, then a plugin using that library later identifies itself.

Attributes:

[RPC] only Since: 0.3.0

Parameters:

`{name}` Client short-name. Sets the `client.name` field of [nvim\_get\_chan\_info()].

`{version}` Dict describing the version, with these (optional) keys:

"major" major version (defaults to 0 if not set, for no release yet)

"minor" minor version

"patch" patch number

"prerelease" string describing a prerelease, like "dev" or "beta1"

"commit" hash or similar identifier of commit

`{type}` Must be one of the following values. Client libraries should default to "remote" unless overridden by the user.

"remote" remote client connected "Nvim flavored" MessagePack-RPC (responses must be in reverse order of requests). [msgpack-rpc]

"msgpack-rpc" remote client connected to Nvim via fully MessagePack-RPC compliant protocol.

"ui" gui frontend

"embedder" application using Nvim as a component (for example, IDE/editor implementing a vim mode).

"host" plugin host, typically started by nvim

"plugin" single plugin, started by nvim

`{methods}` Builtin methods in the client. For a host, this does not include plugin methods which will be discovered later. The key should be the method name, the values are dicts with these (optional) keys (more keys may be added in future versions of Nvim, thus unknown keys are ignored. Clients must only use keys defined in this or later versions of Nvim):

"async" if true, send as a notification. If false or unspecified, use a blocking request

"nargs" Number of arguments. Could be a single integer or an array of two integers, minimum and maximum inclusive.

`{attributes}` Arbitrary string:string map of informal client properties. Suggested keys:

"pid": Process id.

"website": Client homepage URL (e.g. GitHub repository)

"license": License description ("Apache 2", "GPLv3", "MIT", …)

"logo": URI or path to image, preferably small logo or icon. .png or .svg format is preferred.

nvim\_set\_current\_buf(`{buffer}`) [nvim\_set\_current\_buf()]  
Sets the current window's buffer to `buffer`.

Attributes:

not allowed when [textlock] is active or in the [cmdwin] Since: 0.1.0

Parameters:

`{buffer}` Buffer id

nvim\_set\_current\_dir(`{dir}`) [nvim\_set\_current\_dir()]  
Changes the global working directory.

Attributes:

Since: 0.1.0

Parameters:

`{dir}` Directory path

nvim\_set\_current\_line(`{line}`) [nvim\_set\_current\_line()]  
Sets the text on the current line.

Attributes:

not allowed when [textlock] is active Since: 0.1.0

Parameters:

`{line}` Line contents

nvim\_set\_current\_tabpage(`{tabpage}`) [nvim\_set\_current\_tabpage()]  
Sets the current tabpage.

Attributes:

not allowed when [textlock] is active or in the [cmdwin] Since: 0.1.0

Parameters:

`{tabpage}` [tab-ID] to focus

nvim\_set\_current\_win(`{window}`) [nvim\_set\_current\_win()]  
Sets the current window (and tabpage, implicitly).

Attributes:

not allowed when [textlock] is active or in the [cmdwin] Since: 0.1.0

Parameters:

`{window}` [window-ID] to focus

nvim\_set\_hl(`{ns_id}`, `{name}`, `{val}`) [nvim\_set\_hl()]  
Sets a highlight group.

**Note:**

Unlike the `:highlight` command which can update a highlight group, this function completely replaces the definition. For example: `nvim_set_hl(0, 'Visual', {})` will clear the highlight group 'Visual'.

The fg and bg keys also accept the string values `"fg"` or `"bg"` which act as aliases to the corresponding foreground and background values of the Normal group. If the Normal group has not been defined, using these values results in an error.

If `link` is used in combination with other attributes; only the `link` will take effect .

Attributes:

Since: 0.5.0

Parameters:

`{ns_id}` Namespace id for this highlight [nvim\_create\_namespace()]. Use 0 to set a highlight group globally [:highlight]. Highlights from non-global namespaces are not active by default, use [nvim\_set\_hl\_ns()](https://neovim.io/doc/user/api.html#nvim_set_hl_ns()) or [nvim\_win\_set\_hl\_ns()](https://neovim.io/doc/user/api.html#nvim_win_set_hl_ns()) to activate them.

`{name}` Highlight group name, e.g. "ErrorMsg"

`{val}` Highlight definition map, accepts the following keys:

fg: color name or "#RRGGBB", see note.

bg: color name or "#RRGGBB", see note.

sp: color name or "#RRGGBB"

blend: integer between 0 and 100

bold: boolean

standout: boolean

underline: boolean

undercurl: boolean

underdouble: boolean

underdotted: boolean

underdashed: boolean

strikethrough: boolean

italic: boolean

reverse: boolean

nocombine: boolean

link: name of another highlight group to link to, see [:hi-link].

default: Don't override existing definition [:hi-default]

ctermfg: Sets foreground of cterm color [ctermfg]

ctermbg: Sets background of cterm color [ctermbg]

cterm: cterm attribute map, like [highlight-args]. If not set, cterm attributes will match those from the attribute map documented above.

force: if true force update the highlight group when it exists.

nvim\_set\_hl\_ns(`{ns_id}`) [nvim\_set\_hl\_ns()]  
Set active namespace for highlights defined with [nvim\_set\_hl()]. This can be set for a single window, see [nvim\_win\_set\_hl\_ns()].

Attributes:

Since: 0.8.0

Parameters:

`{ns_id}` the namespace to use

nvim\_set\_hl\_ns\_fast(`{ns_id}`) [nvim\_set\_hl\_ns\_fast()]  
Set active namespace for highlights defined with [nvim\_set\_hl()] while redrawing.

This function meant to be called while redrawing, primarily from [nvim\_set\_decoration\_provider()] on\_win and on\_line callbacks, which are allowed to change the namespace during a redraw cycle.

Attributes:

[api-fast] Since: 0.8.0

Parameters:

`{ns_id}` the namespace to activate

nvim\_set\_keymap(`{mode}`, `{lhs}`, `{rhs}`, `{opts}`) [nvim\_set\_keymap()]  
Sets a global [mapping] for the given mode.

To set a buffer-local mapping, use [nvim\_buf\_set\_keymap()].

Unlike [:map], leading/trailing whitespace is accepted as part of the `{lhs}` or `{rhs}`. Empty `{rhs}` is `<Nop>`. [keycodes] are replaced as usual.

Example:

    call nvim_set_keymap('n', ' <NL>', '', {'nowait': v:true})

is equivalent to:

    nmap <nowait> <Space><NL> <Nop>

Attributes:

Since: 0.4.0

Parameters:

`{mode}` Mode short-name (map command prefix: "n", "i", "v", "x", …) or "!" for [:map!], or empty string for [:map]. "ia", "ca" or "!a" for abbreviation in Insert mode, Cmdline mode, or both, respectively

`{lhs}` Left-hand-side [{lhs}] of the mapping.

`{rhs}` Right-hand-side [{rhs}] of the mapping.

`{opts}` Optional parameters map: Accepts all [:map-arguments] as keys except `<buffer>`, values are booleans (default false). Also:

"noremap" disables [recursive\_mapping], like [:noremap]

"desc" human-readable description.

"callback" Lua function called in place of `{rhs}`.

"replace\_keycodes" (boolean) When "expr" is true, replace keycodes in the resulting string . Returning nil from the Lua "callback" is equivalent to returning an empty string.

nvim\_set\_var(`{name}`, `{value}`) [nvim\_set\_var()]  
Sets a global (g:) variable.

Attributes:

Since: 0.1.0

Parameters:

`{name}` Variable name

`{value}` Variable value

nvim\_set\_vvar(`{name}`, `{value}`) [nvim\_set\_vvar()]  
Sets a v: variable, if it is not readonly.

Attributes:

Since: 0.4.0

Parameters:

`{name}` Variable name

`{value}` Variable value

nvim\_strwidth(`{text}`) [nvim\_strwidth()]  
Calculates the number of display cells occupied by `text`. Control characters including `<Tab>` count as one cell.

Attributes:

Since: 0.1.0

Parameters:

`{text}` Some text

Return:

Number of cells

nvim\_\_complete\_set(`{index}`, `{opts}`) [nvim\_\_complete\_set()]  
EXPERIMENTAL: this API may change in the future.

Sets info for the completion item at the given index. If the info text was shown in a window, returns the window and buffer ids, or empty dict if not shown.

Parameters:

`{index}` Completion candidate index

`{opts}` Optional parameters.

info: (string) info text.

Return:

Dict containing these keys:

winid: (number) floating window id

bufnr: (number) buffer id in floating window

nvim\_\_get\_runtime(`{pat}`, `{all}`, `{opts}`) [nvim\_\_get\_runtime()]  
Find files in runtime directories

Attributes:

[api-fast] Since: 0.6.0

Parameters:

`{pat}` pattern of files to search for

`{all}` whether to return all matches or only the first

`{opts}` is\_lua: only search Lua subdirs

Return:

list of absolute paths to the found files

nvim\_\_id(`{obj}`) [nvim\_\_id()]  
Returns object given as argument.

This API function is used for testing. One should not rely on its presence in plugins.

Parameters:

`{obj}` Object to return.

Return:

its argument.

nvim\_\_id\_array(`{arr}`) [nvim\_\_id\_array()]  
Returns array given as argument.

This API function is used for testing. One should not rely on its presence in plugins.

Parameters:

`{arr}` Array to return.

Return:

its argument.

nvim\_\_id\_dict(`{dct}`) [nvim\_\_id\_dict()]  
Returns dict given as argument.

This API function is used for testing. One should not rely on its presence in plugins.

Parameters:

`{dct}` Dict to return.

Return:

its argument.

nvim\_\_id\_float(`{flt}`) [nvim\_\_id\_float()]  
Returns floating-point value given as argument.

This API function is used for testing. One should not rely on its presence in plugins.

Parameters:

`{flt}` Value to return.

Return:

its argument.

nvim\_\_inspect\_cell(`{grid}`, `{row}`, `{col}`) [nvim\_\_inspect\_cell()]  
NB: if your UI doesn't use hlstate, this will not return hlstate first time.

nvim\_\_invalidate\_glyph\_cache() [nvim\_\_invalidate\_glyph\_cache()]  
For testing. The condition in schar\_cache\_clear\_if\_full is hard to reach, so this function can be used to force a cache clear in a test.

nvim\_\_redraw(`{opts}`) [nvim\_\_redraw()]  
EXPERIMENTAL: this API may change in the future.

Instruct Nvim to redraw various components.

Attributes:

Since: 0.10.0

Parameters:

`{opts}` Optional parameters.

win: Target a specific [window-ID] as described below.

buf: Target a specific buffer number as described below.

flush: Update the screen with pending updates.

valid: When present mark `win`, `buf`, or all windows for redraw. When `true`, only redraw changed lines (useful for decoration providers). When `false`, forcefully redraw.

range: Redraw a range in `buf`, the buffer in `win` or the current buffer (useful for decoration providers). Expects a tuple `[first, last]` with the first and last line number of the range, 0-based end-exclusive [api-indexing].

cursor: Immediately update cursor position on the screen in `win` or the current window.

statuscolumn: Redraw the ['statuscolumn'] in `buf`, `win` or all windows.

statusline: Redraw the ['statusline'] in `buf`, `win` or all windows.

winbar: Redraw the ['winbar'] in `buf`, `win` or all windows.

tabline: Redraw the ['tabline'].

See also:

[:redraw]

nvim\_\_stats() [nvim\_\_stats()]  
Gets internal stats.

Return:

Map of various internal stats.

## Vimscript Functions [api-vimscript]

[nvim\_call\_dict\_function()]  
nvim\_call\_dict\_function(`{dict}`, `{fn}`, `{args}`) Calls a Vimscript [Dictionary-function] with the given arguments.

On execution error: fails with Vimscript error, updates v:errmsg.

Attributes:

Since: 0.3.0

Parameters:

`{dict}` Dict, or String evaluating to a Vimscript [self] dict

`{fn}` Name of the function defined on the Vimscript dict

`{args}` Function arguments packed in an Array

Return:

Result of the function call

nvim\_call\_function(`{fn}`, `{args}`) [nvim\_call\_function()]  
Calls a Vimscript function with the given arguments.

On execution error: fails with Vimscript error, updates v:errmsg.

Attributes:

Since: 0.1.0

Parameters:

`{fn}` Function to call

`{args}` Function arguments packed in an Array

Return:

Result of the function call

nvim\_command(`{command}`) [nvim\_command()]  
Executes an Ex command.

On execution error: fails with Vimscript error, updates v:errmsg.

Prefer [nvim\_cmd()] or [nvim\_exec2()] instead. To modify an Ex command in a structured way before executing it, modify the result of [nvim\_parse\_cmd()](https://neovim.io/doc/user/api.html#nvim_parse_cmd()) then pass it to [nvim\_cmd()](https://neovim.io/doc/user/api.html#nvim_cmd()).

Attributes:

Since: 0.1.0

Parameters:

`{command}` Ex command string

nvim\_eval(`{expr}`) [nvim\_eval()]  
Evaluates a Vimscript [expression]. Dicts and Lists are recursively expanded.

On execution error: fails with Vimscript error, updates v:errmsg.

Attributes:

Since: 0.1.0

Parameters:

`{expr}` Vimscript expression string

Return:

Evaluation result or expanded object

nvim\_exec2(`{src}`, `{opts}`) [nvim\_exec2()]  
Executes Vimscript (multiline block of Ex commands), like anonymous [:source].

Unlike [nvim\_command()] this function supports heredocs, script-scope (s:), etc.

On execution error: fails with Vimscript error, updates v:errmsg.

Attributes:

Since: 0.9.0

Parameters:

`{src}` Vimscript code

`{opts}` Optional parameters.

output: (boolean, default false) Whether to capture and return all  output.

Return:

Dict containing information about execution, with these keys:

output: (string|nil) Output if `opts.output` is true.

See also:

[execute()]

[nvim\_command()]

[nvim\_cmd()]

[nvim\_parse\_expression()]  
nvim\_parse\_expression(`{expr}`, `{flags}`, `{highlight}`) Parse a Vimscript expression.

Attributes:

[api-fast] Since: 0.3.0

Parameters:

`{expr}` Expression to parse. Always treated as a single line.

`{flags}` Flags:

"m" if multiple expressions in a row are allowed (only the first one will be parsed),

"E" if EOC tokens are not allowed (determines whether they will stop parsing process or be recognized as an operator/space, though also yielding an error).

"l" when needing to start parsing with lvalues for ":let" or ":for". Common flag sets:

"m" to parse like for `":echo"`.

"E" to parse like for `"<C-r>="`.

empty string for ":call".

"lm" to parse for ":let".

`{highlight}` If true, return value will also include "highlight" key containing array of 4-tuples (arrays) (Integer, Integer, Integer, String), where first three numbers define the highlighted region and represent line, starting column and ending column (latter exclusive: one should highlight region \[start\_col, end\_col)).

Return:

AST: top-level dict with these keys:

"error": Dict with error, present only if parser saw some error. Contains the following keys:

"message": String, error message in printf format, translated. Must contain exactly one "%.\*s".

"arg": String, error message argument.

"len": Amount of bytes successfully parsed. With flags equal to "" that should be equal to the length of expr string. ("Successfully parsed" here means "participated in AST creation", not "till the first error".)

"ast": AST, either nil or a dict with these keys:

"type": node type, one of the value names from ExprASTNodeType stringified without "kExprNode" prefix.

"start": a pair `[line, column]` describing where node is "started" where "line" is always 0 (will not be 0 if you will be using this API on e.g. ":let", but that is not present yet). Both elements are Integers.

"len": “length” of the node. This and "start" are there for debugging purposes primary (debugging parser and providing debug information).

"children": a list of nodes described in top/"ast". There always is zero, one or two children, key will not be present if node has no children. Maximum number of children may be found in node\_maxchildren array.

Local values (present only for certain nodes):

"scope": a single Integer, specifies scope for "Option" and "PlainIdentifier" nodes. For "Option" it is one of ExprOptScope values, for "PlainIdentifier" it is one of ExprVarScope values.

"ident": identifier (without scope, if any), present for "Option", "PlainIdentifier", "PlainKey" and "Environment" nodes.

"name": Integer, register name (one character) or -1. Only present for "Register" nodes.

"cmp\_type": String, comparison type, one of the value names from ExprComparisonType, stringified without "kExprCmp" prefix. Only present for "Comparison" nodes.

"ccs\_strategy": String, case comparison strategy, one of the value names from ExprCaseCompareStrategy, stringified without "kCCStrategy" prefix. Only present for "Comparison" nodes.

"augmentation": String, augmentation type for "Assignment" nodes. Is either an empty string, "Add", "Subtract" or "Concat" for "=", "+=", "-=" or ".=" respectively.

"invert": Boolean, true if result of comparison needs to be inverted. Only present for "Comparison" nodes.

"ivalue": Integer, integer value for "Integer" nodes.

"fvalue": Float, floating-point value for "Float" nodes.

"svalue": String, value for "SingleQuotedString" and "DoubleQuotedString" nodes.

## Command Functions [api-command]

[nvim\_buf\_create\_user\_command()]  
nvim\_buf\_create\_user\_command(`{buffer}`, `{name}`, `{command}`, `{opts}`) Creates a buffer-local command [user-commands].

Attributes:

Since: 0.7.0

Parameters:

`{buffer}` Buffer id, or 0 for current buffer.

See also:

nvim\_create\_user\_command

[nvim\_buf\_del\_user\_command()]  
nvim\_buf\_del\_user\_command(`{buffer}`, `{name}`) Delete a buffer-local user-defined command.

Only commands created with [:command-buffer] or [nvim\_buf\_create\_user\_command()] can be deleted with this function.

Attributes:

Since: 0.7.0

Parameters:

`{buffer}` Buffer id, or 0 for current buffer.

`{name}` Name of the command to delete.

nvim\_buf\_get\_commands(`{buffer}`, `{opts}`) [nvim\_buf\_get\_commands()]  
Gets a map of buffer-local [user-commands].

Attributes:

Since: 0.3.0

Parameters:

`{buffer}` Buffer id, or 0 for current buffer

`{opts}` Optional parameters. Currently not used.

Return:

Map of maps describing commands.

nvim\_cmd(`{cmd}`, `{opts}`) [nvim\_cmd()]  
Executes an Ex command.

Unlike [nvim\_command()] this command takes a structured Dict instead of a String. This allows for easier construction and manipulation of an Ex command. This also allows for things such as having spaces inside a command argument, expanding filenames in a command that otherwise doesn't expand filenames, etc. Command arguments may also be Number, Boolean or String.

The first argument may also be used instead of count for commands that support it in order to make their usage simpler with [vim.cmd()]. For example, instead of `vim.cmd.bdelete{ count = 2 }`, you may do `vim.cmd.bdelete(2)`.

On execution error: fails with Vimscript error, updates v:errmsg.

Attributes:

Since: 0.8.0

Parameters:

`{cmd}` Command to execute. Must be a Dict that can contain the same values as the return value of [nvim\_parse\_cmd()] except "addr", "nargs" and "nextcmd" which are ignored if provided. All values except for "cmd" are optional.

`{opts}` Optional parameters.

output: (boolean, default false) Whether to return command output.

Return:

Command output  if `output` is true, else empty string.

See also:

[nvim\_exec2()]

[nvim\_command()]

[nvim\_create\_user\_command()]  
nvim\_create\_user\_command(`{name}`, `{command}`, `{opts}`) Creates a global [user-commands] command.

For Lua usage see [lua-guide-commands-create].

Example:

    :call nvim_create_user_command('SayHello', 'echo "Hello world!"', {'bang': v:true})
    :SayHello
    Hello world!

Attributes:

Since: 0.7.0

Parameters:

`{name}` Name of the new user command. Must begin with an uppercase letter.

`{command}` Replacement command to execute when this user command is executed. When called from Lua, the command can also be a Lua function. The function is called with a single table argument that contains the following keys:

name: (string) Command name

args: (string) The args passed to the command, if any `<args>`

fargs: (table) The args split by unescaped whitespace (when more than one argument is allowed), if any `<f-args>`

nargs: (string) Number of arguments [:command-nargs]

bang: (boolean) "true" if the command was executed with a ! modifier `<bang>`

line1: (number) The starting line of the command range `<line1>`

line2: (number) The final line of the command range `<line2>`

range: (number) The number of items in the command range: 0, 1, or 2 `<range>`

count: (number) Any count supplied `<count>`

reg: (string) The optional register, if specified `<reg>`

mods: (string) Command modifiers, if any `<mods>`

smods: (table) Command modifiers in a structured format. Has the same structure as the "mods" key of [nvim\_parse\_cmd()].

`{opts}` Optional [command-attributes].

Set boolean attributes such as [:command-bang] or [:command-bar] to true (but not [:command-buffer](https://neovim.io/doc/user/map.html#%3Acommand-buffer), use [nvim\_buf\_create\_user\_command()](https://neovim.io/doc/user/api.html#nvim_buf_create_user_command()) instead).

"complete" [:command-complete] also accepts a Lua function which works like [:command-completion-customlist].

Other parameters:

desc: (string) Used for listing the command when a Lua function is used for `{command}`.

force: (boolean, default true) Override any previous definition.

preview: (function) Preview callback for ['inccommand'] [:command-preview]

nvim\_del\_user\_command(`{name}`) [nvim\_del\_user\_command()]  
Delete a user-defined command.

Attributes:

Since: 0.7.0

Parameters:

`{name}` Name of the command to delete.

nvim\_get\_commands(`{opts}`) [nvim\_get\_commands()]  
Gets a map of global (non-buffer-local) Ex commands.

Currently only [user-commands] are supported, not builtin Ex commands.

Attributes:

Since: 0.3.0

Parameters:

`{opts}` Optional parameters. Currently only supports `{"builtin":false}`

Return:

Map of maps describing commands.

See also:

[nvim\_get\_all\_options\_info()]

nvim\_parse\_cmd(`{str}`, `{opts}`) [nvim\_parse\_cmd()]  
Parse command line.

Doesn't check the validity of command arguments.

Attributes:

[api-fast] Since: 0.8.0

Parameters:

`{str}` Command line string to parse. Cannot contain "\\n".

`{opts}` Optional parameters. Reserved for future use.

Return:

Dict containing command information, with these keys:

cmd: (string) Command name.

range: (array) (optional) Command range (`<line1>` `<line2>`). Omitted if command doesn't accept a range. Otherwise, has no elements if no range was specified, one element if only a single range item was specified, or two elements if both range items were specified.

count: (number) (optional) Command `<count>`. Omitted if command cannot take a count.

reg: (string) (optional) Command `<register>`. Omitted if command cannot take a register.

bang: (boolean) Whether command contains a `<bang>` (!) modifier.

args: (array) Command arguments.

addr: (string) Value of [:command-addr]. Uses short name or "line" for -addr=lines.

nargs: (string) Value of [:command-nargs].

nextcmd: (string) Next command if there are multiple commands separated by a [:bar]. Empty if there isn't a next command.

magic: (dict) Which characters have special meaning in the command arguments.

file: (boolean) The command expands filenames. Which means characters such as "%", "#" and wildcards are expanded.

bar: (boolean) The "|" character is treated as a command separator and the double quote character (") is treated as the start of a comment.

mods: (dict) [:command-modifiers].

filter: (dict) [:filter].

pattern: (string) Filter pattern. Empty string if there is no filter.

force: (boolean) Whether filter is inverted or not.

silent: (boolean) [:silent].

emsg\_silent: (boolean) [:silent!].

unsilent: (boolean) [:unsilent].

sandbox: (boolean) [:sandbox].

noautocmd: (boolean) [:noautocmd].

browse: (boolean) [:browse].

confirm: (boolean) [:confirm].

hide: (boolean) [:hide].

horizontal: (boolean) [:horizontal].

keepalt: (boolean) [:keepalt].

keepjumps: (boolean) [:keepjumps].

keepmarks: (boolean) [:keepmarks].

keeppatterns: (boolean) [:keeppatterns].

lockmarks: (boolean) [:lockmarks].

noswapfile: (boolean) [:noswapfile].

tab: (integer) [:tab]. -1 when omitted.

verbose: (integer) [:verbose]. -1 when omitted.

vertical: (boolean) [:vertical].

split: (string) Split modifier string, is an empty string when there's no split modifier. If there is a split modifier it can be one of:

"aboveleft": [:aboveleft].

"belowright": [:belowright].

"topleft": [:topleft].

"botright": [:botright].

## Options Functions [api-options]

nvim\_get\_all\_options\_info() [nvim\_get\_all\_options\_info()]  
Gets the option information for all options.

The dict has the full option names as keys and option metadata dicts as detailed at [nvim\_get\_option\_info2()].

Attributes:

Since: 0.5.0

Return:

dict of all options

See also:

[nvim\_get\_commands()]

nvim\_get\_option\_info2(`{name}`, `{opts}`) [nvim\_get\_option\_info2()]  
Gets the option information for one option from arbitrary buffer or window

Resulting dict has keys:

name: Name of the option 

shortname: Shortened name of the option 

type: type of option ("string", "number" or "boolean")

default: The default value for the option

was\_set: Whether the option was set.

last\_set\_sid: Last set script id (if any)

last\_set\_linenr: line number where option was set

last\_set\_chan: Channel where option was set (0 for local)

scope: one of "global", "win", or "buf"

global\_local: whether win or buf option has a global value

commalist: List of comma separated values

flaglist: List of single char flags

When `{scope}` is not provided, the last set information applies to the local value in the current buffer or window if it is available, otherwise the global value information is returned. This behavior can be disabled by explicitly specifying `{scope}` in the `{opts}` table.

Attributes:

Since: 0.9.0

Parameters:

`{name}` Option name

`{opts}` Optional parameters

scope: One of "global" or "local". Analogous to [:setglobal] and [:setlocal], respectively.

win: [window-ID]. Used for getting window local options.

buf: Buffer number. Used for getting buffer local options. Implies `{scope}` is "local".

Return:

Option Information

nvim\_get\_option\_value(`{name}`, `{opts}`) [nvim\_get\_option\_value()]  
Gets the value of an option. The behavior of this function matches that of [:set]: the local value of an option is returned if it exists; otherwise, the global value is returned. Local values always correspond to the current buffer or window, unless "buf" or "win" is set in `{opts}`.

Attributes:

Since: 0.7.0

Parameters:

`{name}` Option name

`{opts}` Optional parameters

scope: One of "global" or "local". Analogous to [:setglobal] and [:setlocal], respectively.

win: [window-ID]. Used for getting window local options.

buf: Buffer number. Used for getting buffer local options. Implies `{scope}` is "local".

filetype: [filetype]. Used to get the default option for a specific filetype. Cannot be used with any other option. **Note:** this will trigger [ftplugin] and all [FileType](https://neovim.io/doc/user/autocmd.html#FileType) autocommands for the corresponding filetype.

Return:

Option value

[nvim\_set\_option\_value()]  
nvim\_set\_option\_value(`{name}`, `{value}`, `{opts}`) Sets the value of an option. The behavior of this function matches that of [:set]: for global-local options, both the global and local value are set unless otherwise specified with `{scope}`.

Note the options `{win}` and `{buf}` cannot be used together.

Attributes:

Since: 0.7.0

Parameters:

`{name}` Option name

`{value}` New option value

`{opts}` Optional parameters

scope: One of "global" or "local". Analogous to [:setglobal] and [:setlocal], respectively.

win: [window-ID]. Used for setting window local option.

buf: Buffer number. Used for setting buffer local option.

## Buffer Functions [api-buffer]

For more information on buffers, see [buffers].

Unloaded Buffers:

Buffers may be unloaded by the [:bunload] command or the buffer's ['bufhidden'] option. When a buffer is unloaded its file contents are freed from memory and vim cannot operate on the buffer lines until it is reloaded (usually by opening the buffer again in a new window). API methods such as [nvim\_buf\_get\_lines()](https://neovim.io/doc/user/api.html#nvim_buf_get_lines()) and [nvim\_buf\_line\_count()](https://neovim.io/doc/user/api.html#nvim_buf_line_count()) will be affected.

You can use [nvim\_buf\_is\_loaded()] or [nvim\_buf\_line\_count()] to check whether a buffer is loaded.

nvim\_buf\_attach(`{buffer}`, `{send_buffer}`, `{opts}`) [nvim\_buf\_attach()]  
Activates buffer-update events on a channel, or as Lua callbacks.

Example (Lua): capture buffer updates in a global `events` variable (use "vim.print(events)" to see its contents):

    events = {}
    vim.api.nvim_buf_attach(0, false, {
      on_lines = function(...)
        table.insert(events, {...})
      end,
    })

Attributes:

Since: 0.3.0

Parameters:

`{buffer}` Buffer id, or 0 for current buffer

`{send_buffer}` True if the initial notification should contain the whole buffer: first notification will be `nvim_buf_lines_event`. Else the first notification will be `nvim_buf_changedtick_event`. Not for Lua callbacks.

`{opts}` Optional parameters.

on\_lines: Lua callback invoked on change. Return a truthy value (not `false` or `nil`) to detach. Args:

the string "lines"

buffer id

b:changedtick

first line that changed (zero-indexed)

last line that was changed

last line in the updated range

byte count of previous contents

deleted\_codepoints (if `utf_sizes` is true)

deleted\_codeunits (if `utf_sizes` is true)

on\_bytes: Lua callback invoked on change. This callback receives more granular information about the change compared to on\_lines. Return a truthy value (not `false` or `nil`) to detach. Args:

the string "bytes"

buffer id

b:changedtick

start row of the changed text (zero-indexed)

start column of the changed text

byte offset of the changed text (from the start of the buffer)

old end row of the changed text (offset from start row)

old end column of the changed text (if old end row = 0, offset from start column)

old end byte length of the changed text

new end row of the changed text (offset from start row)

new end column of the changed text (if new end row = 0, offset from start column)

new end byte length of the changed text

on\_changedtick: Lua callback invoked on changedtick increment without text change. Args:

the string "changedtick"

buffer id

b:changedtick

on\_detach: Lua callback invoked on detach. Args:

the string "detach"

buffer id

on\_reload: Lua callback invoked on reload. The entire buffer content should be considered changed. Args:

the string "reload"

buffer id

utf\_sizes: include UTF-32 and UTF-16 size of the replaced region, as args to `on_lines`.

preview: also attach to command preview  events.

Return:

False if attach failed (invalid parameter, or buffer isn't loaded); otherwise True. TODO: LUA\_API\_NO\_EVAL

See also:

[nvim\_buf\_detach()]

[api-buffer-updates-lua]

nvim\_buf\_call(`{buffer}`, `{fun}`) [nvim\_buf\_call()]  
Call a function with buffer as temporary current buffer.

This temporarily switches current buffer to "buffer". If the current window already shows "buffer", the window is not switched. If a window inside the current tabpage (including a float) already shows the buffer, then one of those windows will be set as current window temporarily. Otherwise a temporary scratch window (called the "autocmd window" for historical reasons) will be used.

This is useful e.g. to call Vimscript functions that only work with the current buffer/window currently, like `jobstart(…, {'term': v:true})`.

Attributes:

Lua [vim.api] only Since: 0.5.0

Parameters:

`{buffer}` Buffer id, or 0 for current buffer

`{fun}` Function to call inside the buffer (currently Lua callable only)

Return:

Return value of function.

nvim\_buf\_del\_keymap(`{buffer}`, `{mode}`, `{lhs}`) [nvim\_buf\_del\_keymap()]  
Unmaps a buffer-local [mapping] for the given mode.

Attributes:

Since: 0.4.0

Parameters:

`{buffer}` Buffer id, or 0 for current buffer

See also:

[nvim\_del\_keymap()]

nvim\_buf\_del\_mark(`{buffer}`, `{name}`) [nvim\_buf\_del\_mark()]  
Deletes a named mark in the buffer. See [mark-motions].

**Note:**

only deletes marks set in the buffer, if the mark is not set in the buffer it will return false.

Attributes:

Since: 0.6.0

Parameters:

`{buffer}` Buffer to set the mark on

`{name}` Mark name

Return:

true if the mark was deleted, else false.

See also:

[nvim\_buf\_set\_mark()]

[nvim\_del\_mark()]

nvim\_buf\_del\_var(`{buffer}`, `{name}`) [nvim\_buf\_del\_var()]  
Removes a buffer-scoped (b:) variable

Attributes:

Since: 0.1.0

Parameters:

`{buffer}` Buffer id, or 0 for current buffer

`{name}` Variable name

nvim\_buf\_delete(`{buffer}`, `{opts}`) [nvim\_buf\_delete()]  
Deletes a buffer and its metadata .

To get [:bdelete] behavior, reset ['buflisted'] and pass `unload=true`:

    vim.bo.buflisted = false
    vim.api.nvim_buf_delete(0, { unload = true })

Attributes:

not allowed when [textlock] is active or in the [cmdwin] Since: 0.5.0

Parameters:

`{buffer}` Buffer id, or 0 for current buffer

`{opts}` Optional parameters. Keys:

force: Force deletion, ignore unsaved changes.

unload: Unloaded only , do not delete.

nvim\_buf\_detach(`{buffer}`) [nvim\_buf\_detach()]  
Deactivates buffer-update events on the channel.

Attributes:

[RPC] only Since: 0.3.0

Parameters:

`{buffer}` Buffer id, or 0 for current buffer

Return:

False if detach failed (because the buffer isn't loaded); otherwise True.

See also:

[nvim\_buf\_attach()]

[api-lua-detach] for detaching Lua callbacks

nvim\_buf\_get\_changedtick(`{buffer}`) [nvim\_buf\_get\_changedtick()]  
Gets a changed tick of a buffer

Attributes:

Since: 0.2.0

Parameters:

`{buffer}` Buffer id, or 0 for current buffer

Return:

`b:changedtick` value.

nvim\_buf\_get\_keymap(`{buffer}`, `{mode}`) [nvim\_buf\_get\_keymap()]  
Gets a list of buffer-local [mapping] definitions.

Attributes:

Since: 0.2.1

Parameters:

`{buffer}` Buffer id, or 0 for current buffer

`{mode}` Mode short-name ("n", "i", "v", ...)

Return:

Array of [maparg()]\-like dictionaries describing mappings. The "buffer" key holds the associated buffer id.

[nvim\_buf\_get\_lines()]  
nvim\_buf\_get\_lines(`{buffer}`, `{start}`, `{end}`, `{strict_indexing}`) Gets a line-range from the buffer.

Indexing is zero-based, end-exclusive. Negative indices are interpreted as length+1+index: -1 refers to the index past the end. So to get the last element use start=-2 and end=-1.

Out-of-bounds indices are clamped to the nearest valid value, unless `strict_indexing` is set.

Attributes:

Since: 0.1.0

Parameters:

`{buffer}` Buffer id, or 0 for current buffer

`{start}` First line index

`{end}` Last line index, exclusive

`{strict_indexing}` Whether out-of-bounds should be an error.

Return:

Array of lines, or empty array for unloaded buffer.

See also:

[nvim\_buf\_get\_text()]

nvim\_buf\_get\_mark(`{buffer}`, `{name}`) [nvim\_buf\_get\_mark()]  
Returns a `(row,col)` tuple representing the position of the named mark. "End of line" column position is returned as [v:maxcol] (big number). See [mark-motions].

Marks are (1,0)-indexed. [api-indexing]

Attributes:

Since: 0.1.0

Parameters:

`{buffer}` Buffer id, or 0 for current buffer

`{name}` Mark name

Return:

(row, col) tuple, (0, 0) if the mark is not set, or is an uppercase/file mark set in another buffer.

See also:

[nvim\_buf\_set\_mark()]

[nvim\_buf\_del\_mark()]

nvim\_buf\_get\_name(`{buffer}`) [nvim\_buf\_get\_name()]  
Gets the full file name for the buffer

Attributes:

Since: 0.1.0

Parameters:

`{buffer}` Buffer id, or 0 for current buffer

Return:

Buffer name

nvim\_buf\_get\_offset(`{buffer}`, `{index}`) [nvim\_buf\_get\_offset()]  
Returns the byte offset of a line (0-indexed). [api-indexing]

Line 1 (index=0) has offset 0. UTF-8 bytes are counted. EOL is one byte. ['fileformat'] and ['fileencoding'] are ignored. The line index just after the last line gives the total byte-count of the buffer. A final EOL byte is counted if it would be written, see ['eol'](https://neovim.io/doc/user/options.html#'eol').

Unlike [line2byte()], throws error for out-of-bounds indexing. Returns -1 for unloaded buffer.

Attributes:

Since: 0.3.2

Parameters:

`{buffer}` Buffer id, or 0 for current buffer

`{index}` Line index

Return:

Integer byte offset, or -1 for unloaded buffer.

[nvim\_buf\_get\_text()]  
nvim\_buf\_get\_text(`{buffer}`, `{start_row}`, `{start_col}`, `{end_row}`, `{end_col}`, `{opts}`) Gets a range from the buffer .

Indexing is zero-based. Row indices are end-inclusive, and column indices are end-exclusive.

Prefer [nvim\_buf\_get\_lines()] when retrieving entire lines.

Attributes:

Since: 0.7.0

Parameters:

`{buffer}` Buffer id, or 0 for current buffer

`{start_row}` First line index

`{start_col}` Starting column (byte offset) on first line

`{end_row}` Last line index, inclusive

`{end_col}` Ending column (byte offset) on last line, exclusive

`{opts}` Optional parameters. Currently unused.

Return:

Array of lines, or empty array for unloaded buffer.

nvim\_buf\_get\_var(`{buffer}`, `{name}`) [nvim\_buf\_get\_var()]  
Gets a buffer-scoped (b:) variable.

Attributes:

Since: 0.1.0

Parameters:

`{buffer}` Buffer id, or 0 for current buffer

`{name}` Variable name

Return:

Variable value

nvim\_buf\_is\_loaded(`{buffer}`) [nvim\_buf\_is\_loaded()]  
Checks if a buffer is valid and loaded. See [api-buffer] for more info about unloaded buffers.

Attributes:

Since: 0.3.2

Parameters:

`{buffer}` Buffer id, or 0 for current buffer

Return:

true if the buffer is valid and loaded, false otherwise.

nvim\_buf\_is\_valid(`{buffer}`) [nvim\_buf\_is\_valid()]  
Checks if a buffer is valid.

**Note:**

Even if a buffer is valid it may have been unloaded. See [api-buffer] for more info about unloaded buffers.

Attributes:

Since: 0.1.0

Parameters:

`{buffer}` Buffer id, or 0 for current buffer

Return:

true if the buffer is valid, false otherwise.

nvim\_buf\_line\_count(`{buffer}`) [nvim\_buf\_line\_count()]  
Returns the number of lines in the given buffer.

Attributes:

Since: 0.1.0

Parameters:

`{buffer}` Buffer id, or 0 for current buffer

Return:

Line count, or 0 for unloaded buffer. [api-buffer]

[nvim\_buf\_set\_keymap()]  
nvim\_buf\_set\_keymap(`{buffer}`, `{mode}`, `{lhs}`, `{rhs}`, `{opts}`) Sets a buffer-local [mapping] for the given mode.

Attributes:

Since: 0.4.0

Parameters:

`{buffer}` Buffer id, or 0 for current buffer

See also:

[nvim\_set\_keymap()]

[nvim\_buf\_set\_lines()]  
nvim\_buf\_set\_lines(`{buffer}`, `{start}`, `{end}`, `{strict_indexing}`, `{replacement}`) Sets (replaces) a line-range in the buffer.

Indexing is zero-based, end-exclusive. Negative indices are interpreted as length+1+index: -1 refers to the index past the end. So to change or delete the last line use start=-2 and end=-1.

To insert lines at a given index, set `start` and `end` to the same index. To delete a range of lines, set `replacement` to an empty array.

Out-of-bounds indices are clamped to the nearest valid value, unless `strict_indexing` is set.

Attributes:

not allowed when [textlock] is active Since: 0.1.0

Parameters:

`{buffer}` Buffer id, or 0 for current buffer

`{start}` First line index

`{end}` Last line index, exclusive

`{strict_indexing}` Whether out-of-bounds should be an error.

`{replacement}` Array of lines to use as replacement

See also:

[nvim\_buf\_set\_text()]

[nvim\_buf\_set\_mark()]  
nvim\_buf\_set\_mark(`{buffer}`, `{name}`, `{line}`, `{col}`, `{opts}`) Sets a named mark in the given buffer, all marks are allowed file/uppercase, visual, last change, etc. See [mark-motions].

Marks are (1,0)-indexed. [api-indexing]

**Note:**

Passing 0 as line deletes the mark

Attributes:

Since: 0.6.0

Parameters:

`{buffer}` Buffer to set the mark on

`{name}` Mark name

`{line}` Line number

`{col}` Column/row number

`{opts}` Optional parameters. Reserved for future use.

Return:

true if the mark was set, else false.

See also:

[nvim\_buf\_del\_mark()]

[nvim\_buf\_get\_mark()]

nvim\_buf\_set\_name(`{buffer}`, `{name}`) [nvim\_buf\_set\_name()]  
Sets the full file name for a buffer, like [:file\_f]

Attributes:

Since: 0.1.0

Parameters:

`{buffer}` Buffer id, or 0 for current buffer

`{name}` Buffer name

[nvim\_buf\_set\_text()]  
nvim\_buf\_set\_text(`{buffer}`, `{start_row}`, `{start_col}`, `{end_row}`, `{end_col}`, `{replacement}`) Sets (replaces) a range in the buffer

This is recommended over [nvim\_buf\_set\_lines()] when only modifying parts of a line, as extmarks will be preserved on non-modified parts of the touched lines.

Indexing is zero-based. Row indices are end-inclusive, and column indices are end-exclusive.

To insert text at a given `(row, column)` location, use `start_row = end_row = row` and `start_col = end_col = col`. To delete the text in a range, use `replacement = {}`.

**Note:**

Prefer [nvim\_buf\_set\_lines()] (for performance) to add or delete entire lines.

Prefer [nvim\_paste()] or [nvim\_put()] to insert (instead of replace) text at cursor.

Attributes:

not allowed when [textlock] is active Since: 0.5.0

Parameters:

`{buffer}` Buffer id, or 0 for current buffer

`{start_row}` First line index

`{start_col}` Starting column (byte offset) on first line

`{end_row}` Last line index, inclusive

`{end_col}` Ending column (byte offset) on last line, exclusive

`{replacement}` Array of lines to use as replacement

nvim\_buf\_set\_var(`{buffer}`, `{name}`, `{value}`) [nvim\_buf\_set\_var()]  
Sets a buffer-scoped (b:) variable

Attributes:

Since: 0.1.0

Parameters:

`{buffer}` Buffer id, or 0 for current buffer

`{name}` Variable name

`{value}` Variable value

## Extmark Functions [api-extmark]

[nvim\_buf\_clear\_namespace()]  
nvim\_buf\_clear\_namespace(`{buffer}`, `{ns_id}`, `{line_start}`, `{line_end}`) Clears [namespace]d objects  from a region.

Lines are 0-indexed. [api-indexing] To clear the namespace in the entire buffer, specify line\_start=0 and line\_end=-1.

Attributes:

Since: 0.3.2

Parameters:

`{buffer}` Buffer id, or 0 for current buffer

`{ns_id}` Namespace to clear, or -1 to clear all namespaces.

`{line_start}` Start of range of lines to clear

`{line_end}` End of range of lines to clear (exclusive) or -1 to clear to end of buffer.

nvim\_buf\_del\_extmark(`{buffer}`, `{ns_id}`, `{id}`) [nvim\_buf\_del\_extmark()]  
Removes an [extmark].

Attributes:

Since: 0.5.0

Parameters:

`{buffer}` Buffer id, or 0 for current buffer

`{ns_id}` Namespace id from [nvim\_create\_namespace()]

`{id}` Extmark id

Return:

true if the extmark was found, else false

[nvim\_buf\_get\_extmark\_by\_id()]  
nvim\_buf\_get\_extmark\_by\_id(`{buffer}`, `{ns_id}`, `{id}`, `{opts}`) Gets the position (0-indexed) of an [extmark].

Attributes:

Since: 0.5.0

Parameters:

`{buffer}` Buffer id, or 0 for current buffer

`{ns_id}` Namespace id from [nvim\_create\_namespace()]

`{id}` Extmark id

`{opts}` Optional parameters. Keys:

details: Whether to include the details dict

hl\_name: Whether to include highlight group name instead of id, true if omitted

Return:

0-indexed (row, col) tuple or empty list () if extmark id was absent

[nvim\_buf\_get\_extmarks()]  
nvim\_buf\_get\_extmarks(`{buffer}`, `{ns_id}`, `{start}`, `{end}`, `{opts}`) Gets [extmarks] in "traversal order" from a [charwise] region defined by buffer positions (inclusive, 0-indexed [api-indexing](https://neovim.io/doc/user/api.html#api-indexing)).

Region can be given as (row,col) tuples, or valid extmark ids (whose positions define the bounds). 0 and -1 are understood as (0,0) and (-1,-1) respectively, thus the following are equivalent:

    vim.api.nvim_buf_get_extmarks(0, my_ns, 0, -1, {})
    vim.api.nvim_buf_get_extmarks(0, my_ns, {0,0}, {-1,-1}, {})

If `end` is less than `start`, marks are returned in reverse order. (Useful with `limit`, to get the first marks prior to a given position.)

**Note:** For a reverse range, `limit` does not actually affect the traversed range, just how many marks are returned

**Note:** when using extmark ranges (marks with a end\_row/end\_col position) the `overlap` option might be useful. Otherwise only the start position of an extmark will be considered.

**Note:** legacy signs placed through the [:sign] commands are implemented as extmarks and will show up here. Their details array will contain a `sign_name` field.

Example:

    local api = vim.api
    local pos = api.nvim_win_get_cursor(0)
    local ns  = api.nvim_create_namespace('my-plugin')
    -- Create new extmark at line 1, column 1.
    local m1  = api.nvim_buf_set_extmark(0, ns, 0, 0, {})
    -- Create new extmark at line 3, column 1.
    local m2  = api.nvim_buf_set_extmark(0, ns, 2, 0, {})
    -- Get extmarks only from line 3.
    local ms  = api.nvim_buf_get_extmarks(0, ns, {2,0}, {2,0}, {})
    -- Get all marks in this buffer + namespace.
    local all = api.nvim_buf_get_extmarks(0, ns, 0, -1, {})
    vim.print(ms)

Attributes:

Since: 0.5.0

Parameters:

`{buffer}` Buffer id, or 0 for current buffer

`{ns_id}` Namespace id from [nvim\_create\_namespace()] or -1 for all namespaces

`{start}` Start of range: a 0-indexed (row, col) or valid extmark id (whose position defines the bound). [api-indexing]

`{end}` End of range (inclusive): a 0-indexed (row, col) or valid extmark id (whose position defines the bound). [api-indexing]

`{opts}` Optional parameters. Keys:

limit: Maximum number of marks to return

details: Whether to include the details dict

hl\_name: Whether to include highlight group name instead of id, true if omitted

overlap: Also include marks which overlap the range, even if their start position is less than `start`

type: Filter marks by type: "highlight", "sign", "virt\_text" and "virt\_lines"

Return:

List of `[extmark_id, row, col]` tuples in "traversal order".

[nvim\_buf\_set\_extmark()]  
nvim\_buf\_set\_extmark(`{buffer}`, `{ns_id}`, `{line}`, `{col}`, `{opts}`) Creates or updates an [extmark].

By default a new extmark is created when no id is passed in, but it is also possible to create a new mark by passing in a previously unused id or move an existing mark by passing in its id. The caller must then keep track of existing and unused ids itself. (Useful over RPC, to avoid waiting for the return value.)

Using the optional arguments, it is possible to use this to highlight a range of text, and also to associate virtual text to the mark.

If present, the position defined by `end_col` and `end_row` should be after the start position in order for the extmark to cover a range. An earlier end position is not an error, but then it behaves like an empty range (no highlighting).

Attributes:

Since: 0.5.0

Parameters:

`{buffer}` Buffer id, or 0 for current buffer

`{ns_id}` Namespace id from [nvim\_create\_namespace()]

`{line}` Line where to place the mark, 0-based. [api-indexing]

`{col}` Column where to place the mark, 0-based. [api-indexing]

`{opts}` Optional parameters.

id : id of the extmark to edit.

end\_row : ending line of the mark, 0-based inclusive.

end\_col : ending col of the mark, 0-based exclusive.

hl\_group : highlight group used for the text range. This and below highlight groups can be supplied either as a string or as an integer, the latter of which can be obtained using [nvim\_get\_hl\_id\_by\_name()]. Multiple highlight groups can be stacked by passing an array (highest priority last).

hl\_eol : when true, for a multiline highlight covering the EOL of a line, continue the highlight for the rest of the screen line (just like for diff and cursorline highlight).

virt\_text : virtual text to link to this mark. A list of `[text, highlight]` tuples, each representing a text chunk with specified highlight. `highlight` element can either be a single highlight group, or an array of multiple highlight groups that will be stacked (highest priority last).

virt\_text\_pos : position of virtual text. Possible values:

"eol": right after eol character (default).

"eol\_right\_align": display right aligned in the window unless the virtual text is longer than the space available. If the virtual text is too long, it is truncated to fit in the window after the EOL character. If the line is wrapped, the virtual text is shown after the end of the line rather than the previous screen line.

"overlay": display over the specified column, without shifting the underlying text.

"right\_align": display right aligned in the window.

"inline": display at the specified column, and shift the buffer text to the right as needed.

virt\_text\_win\_col : position the virtual text at a fixed window column (starting from the first text column of the screen line) instead of "virt\_text\_pos".

virt\_text\_hide : hide the virtual text when the background text is selected or hidden because of scrolling with ['nowrap'] or ['smoothscroll']. Currently only affects "overlay" virt\_text.

virt\_text\_repeat\_linebreak : repeat the virtual text on wrapped lines.

hl\_mode : control how highlights are combined with the highlights of the text. Currently only affects virt\_text highlights, but might affect `hl_group` in later versions.

"replace": only show the virt\_text color. This is the default.

"combine": combine with background text color.

"blend": blend with background text color. Not supported for "inline" virt\_text.

virt\_lines : virtual lines to add next to this mark This should be an array over lines, where each line in turn is an array over `[text, highlight]` tuples. In general, buffer and window options do not affect the display of the text. In particular ['wrap'] and ['linebreak'] options do not take effect, so the number of extra screen lines will always match the size of the array. However the ['tabstop'](https://neovim.io/doc/user/options.html#'tabstop') buffer option is still used for hard tabs. By default lines are placed below the buffer line containing the mark.

virt\_lines\_above: place virtual lines above instead.

virt\_lines\_leftcol: Place virtual lines in the leftmost column of the window, bypassing sign and number columns.

virt\_lines\_overflow: controls how to handle virtual lines wider than the window. Currently takes the one of the following values:

"trunc": truncate virtual lines on the right (default).

"scroll": virtual lines can scroll horizontally with ['nowrap'], otherwise the same as "trunc".

ephemeral : for use with [nvim\_set\_decoration\_provider()] callbacks. The mark will only be used for the current redraw cycle, and not be permanently stored in the buffer.

right\_gravity : boolean that indicates the direction the extmark will be shifted in when new text is inserted (true for right, false for left). Defaults to true.

end\_right\_gravity : boolean that indicates the direction the extmark end position (if it exists) will be shifted in when new text is inserted (true for right, false for left). Defaults to false.

undo\_restore : Restore the exact position of the mark if text around the mark was deleted and then restored by undo. Defaults to true.

invalidate : boolean that indicates whether to hide the extmark if the entirety of its range is deleted. For hidden marks, an "invalid" key is added to the "details" array of [nvim\_buf\_get\_extmarks()] and family. If "undo\_restore" is false, the extmark is deleted instead.

priority: a priority value for the highlight group, sign attribute or virtual text. For virtual text, item with highest priority is drawn last. For example treesitter highlighting uses a value of 100.

strict: boolean that indicates extmark should not be placed if the line or column value is past the end of the buffer or end of the line respectively. Defaults to true.

sign\_text: string of length 1-2 used to display in the sign column.

sign\_hl\_group: highlight group used for the sign column text.

number\_hl\_group: highlight group used for the number column.

line\_hl\_group: highlight group used for the whole line.

cursorline\_hl\_group: highlight group used for the sign column text when the cursor is on the same line as the mark and ['cursorline'] is enabled.

conceal: string which should be either empty or a single character. Enable concealing similar to [:syn-conceal]. When a character is supplied it is used as [:syn-cchar]. "hl\_group" is used as highlight for the cchar if provided, otherwise it defaults to [hl-Conceal](https://neovim.io/doc/user/syntax.html#hl-Conceal).

conceal\_lines: string which should be empty. When provided, lines in the range are not drawn at all ; the next unconcealed line is drawn instead.

spell: boolean indicating that spell checking should be performed within this extmark

ui\_watched: boolean that indicates the mark should be drawn by a UI. When set, the UI will receive win\_extmark events. **Note:** the mark is positioned by virt\_text attributes. Can be used together with virt\_text.

url: A URL to associate with this extmark. In the TUI, the OSC 8 control sequence is used to generate a clickable hyperlink to this URL.

Return:

Id of the created/updated extmark

nvim\_create\_namespace(`{name}`) [nvim\_create\_namespace()]  
Creates a new namespace or gets an existing one. [namespace]  

Namespaces are used for buffer highlights and virtual text, see [nvim\_buf\_set\_extmark()].

Namespaces can be named or anonymous. If `name` matches an existing namespace, the associated id is returned. If `name` is an empty string a new, anonymous namespace is created.

Attributes:

Since: 0.3.2

Parameters:

`{name}` Namespace name or empty string

Return:

Namespace id

nvim\_get\_namespaces() [nvim\_get\_namespaces()]  
Gets existing, non-anonymous [namespace]s.

Attributes:

Since: 0.3.2

Return:

dict that maps from names to namespace ids.

[nvim\_set\_decoration\_provider()]  
nvim\_set\_decoration\_provider(`{ns_id}`, `{opts}`) Set or change decoration provider for a [namespace]

This is a very general purpose interface for having Lua callbacks being triggered during the redraw code.

The expected usage is to set [extmarks] for the currently redrawn buffer. [nvim\_buf\_set\_extmark()] can be called to add marks on a per-window or per-lines basis. Use the `ephemeral` key to only use the mark for the current screen redraw (the callback will be called again for the next redraw).

**Note:** this function should not be called often. Rather, the callbacks themselves can be used to throttle unneeded callbacks. the `on_start` callback can return `false` to disable the provider until the next redraw. Similarly, return `false` in `on_win` will skip the `on_line` calls for that window (but any extmarks set in `on_win` will still be used). A plugin managing multiple sources of decoration should ideally only set one provider, and merge the sources internally. You can use multiple `ns_id` for the extmarks set/modified inside the callback anyway.

**Note:** doing anything other than setting extmarks is considered experimental. Doing things like changing options are not explicitly forbidden, but is likely to have unexpected consequences (such as 100% CPU consumption). Doing `vim.rpcnotify` should be OK, but `vim.rpcrequest` is quite dubious for the moment.

**Note:** It is not allowed to remove or update extmarks in `on_line` callbacks.

Attributes:

Lua [vim.api] only Since: 0.5.0

Parameters:

`{ns_id}` Namespace id from [nvim\_create\_namespace()]

`{opts}` Table of callbacks:

on\_start: called first on each screen redraw

\["start", tick\]

on\_buf: called for each buffer being redrawn (once per edit, before window callbacks)

\["buf", bufnr, tick\]

on\_win: called when starting to redraw a specific window.

\["win", winid, bufnr, toprow, botrow\]

on\_line: called for each buffer line being redrawn. (The interaction with fold lines is subject to change)

\["line", winid, bufnr, row\]

on\_end: called at the end of a redraw cycle

\["end", tick\]

nvim\_\_ns\_get(`{ns_id}`) [nvim\_\_ns\_get()]  
EXPERIMENTAL: this API will change in the future.

Get the properties for namespace

Parameters:

`{ns_id}` Namespace

Return:

Map defining the namespace properties, see [nvim\_\_ns\_set()]

nvim\_\_ns\_set(`{ns_id}`, `{opts}`) [nvim\_\_ns\_set()]  
EXPERIMENTAL: this API will change in the future.

Set some properties for namespace

Parameters:

`{ns_id}` Namespace

`{opts}` Optional parameters to set:

wins: a list of windows to be scoped in

## Window Functions [api-window]

nvim\_win\_call(`{window}`, `{fun}`) [nvim\_win\_call()]  
Calls a function with window as temporary current window.

Attributes:

Lua [vim.api] only Since: 0.5.0

Parameters:

`{window}` [window-ID], or 0 for current window

`{fun}` Function to call inside the window (currently Lua callable only)

Return:

Return value of function.

See also:

[win\_execute()]

[nvim\_buf\_call()]

nvim\_win\_close(`{window}`, `{force}`) [nvim\_win\_close()]  
Closes the window .

Attributes:

not allowed when [textlock] is active Since: 0.4.0

Parameters:

`{window}` [window-ID], or 0 for current window

`{force}` Behave like `:close!` The last window of a buffer with unwritten changes can be closed. The buffer will become hidden, even if ['hidden'] is not set.

nvim\_win\_del\_var(`{window}`, `{name}`) [nvim\_win\_del\_var()]  
Removes a window-scoped (w:) variable

Attributes:

Since: 0.1.0

Parameters:

`{window}` [window-ID], or 0 for current window

`{name}` Variable name

nvim\_win\_get\_buf(`{window}`) [nvim\_win\_get\_buf()]  
Gets the current buffer in a window

Attributes:

Since: 0.1.0

Parameters:

`{window}` [window-ID], or 0 for current window

Return:

Buffer id

nvim\_win\_get\_cursor(`{window}`) [nvim\_win\_get\_cursor()]  
Gets the (1,0)-indexed, buffer-relative cursor position for a given window (different windows showing the same buffer have independent cursor positions). [api-indexing]

Attributes:

Since: 0.1.0

Parameters:

`{window}` [window-ID], or 0 for current window

Return:

(row, col) tuple

See also:

[getcurpos()]

nvim\_win\_get\_height(`{window}`) [nvim\_win\_get\_height()]  
Gets the window height

Attributes:

Since: 0.1.0

Parameters:

`{window}` [window-ID], or 0 for current window

Return:

Height as a count of rows

nvim\_win\_get\_number(`{window}`) [nvim\_win\_get\_number()]  
Gets the window number

Attributes:

Since: 0.1.0

Parameters:

`{window}` [window-ID], or 0 for current window

Return:

Window number

nvim\_win\_get\_position(`{window}`) [nvim\_win\_get\_position()]  
Gets the window position in display cells. First position is zero.

Attributes:

Since: 0.1.0

Parameters:

`{window}` [window-ID], or 0 for current window

Return:

(row, col) tuple with the window position

nvim\_win\_get\_tabpage(`{window}`) [nvim\_win\_get\_tabpage()]  
Gets the window tabpage

Attributes:

Since: 0.1.0

Parameters:

`{window}` [window-ID], or 0 for current window

Return:

Tabpage that contains the window

nvim\_win\_get\_var(`{window}`, `{name}`) [nvim\_win\_get\_var()]  
Gets a window-scoped (w:) variable

Attributes:

Since: 0.1.0

Parameters:

`{window}` [window-ID], or 0 for current window

`{name}` Variable name

Return:

Variable value

nvim\_win\_get\_width(`{window}`) [nvim\_win\_get\_width()]  
Gets the window width

Attributes:

Since: 0.1.0

Parameters:

`{window}` [window-ID], or 0 for current window

Return:

Width as a count of columns

nvim\_win\_hide(`{window}`) [nvim\_win\_hide()]  
Closes the window and hide the buffer it contains .

Like [:hide] the buffer becomes hidden unless another window is editing it, or ['bufhidden'] is `unload`, `delete` or `wipe` as opposed to [:close](https://neovim.io/doc/user/windows.html#%3Aclose) or [nvim\_win\_close()](https://neovim.io/doc/user/api.html#nvim_win_close()), which will close the buffer.

Attributes:

not allowed when [textlock] is active Since: 0.5.0

Parameters:

`{window}` [window-ID], or 0 for current window

nvim\_win\_is\_valid(`{window}`) [nvim\_win\_is\_valid()]  
Checks if a window is valid

Attributes:

Since: 0.1.0

Parameters:

`{window}` [window-ID], or 0 for current window

Return:

true if the window is valid, false otherwise

nvim\_win\_set\_buf(`{window}`, `{buffer}`) [nvim\_win\_set\_buf()]  
Sets the current buffer in a window, without side effects

Attributes:

not allowed when [textlock] is active Since: 0.3.2

Parameters:

`{window}` [window-ID], or 0 for current window

`{buffer}` Buffer id

nvim\_win\_set\_cursor(`{window}`, `{pos}`) [nvim\_win\_set\_cursor()]  
Sets the (1,0)-indexed cursor position in the window. [api-indexing] This scrolls the window even if it is not the current one.

Attributes:

Since: 0.1.0

Parameters:

`{window}` [window-ID], or 0 for current window

`{pos}` (row, col) tuple representing the new position

nvim\_win\_set\_height(`{window}`, `{height}`) [nvim\_win\_set\_height()]  
Sets the window height.

Attributes:

Since: 0.1.0

Parameters:

`{window}` [window-ID], or 0 for current window

`{height}` Height as a count of rows

nvim\_win\_set\_hl\_ns(`{window}`, `{ns_id}`) [nvim\_win\_set\_hl\_ns()]  
Set highlight namespace for a window. This will use highlights defined with [nvim\_set\_hl()] for this namespace, but fall back to global highlights (ns=0) when missing.

This takes precedence over the ['winhighlight'] option.

Attributes:

Since: 0.8.0

Parameters:

`{ns_id}` the namespace to use

nvim\_win\_set\_var(`{window}`, `{name}`, `{value}`) [nvim\_win\_set\_var()]  
Sets a window-scoped (w:) variable

Attributes:

Since: 0.1.0

Parameters:

`{window}` [window-ID], or 0 for current window

`{name}` Variable name

`{value}` Variable value

nvim\_win\_set\_width(`{window}`, `{width}`) [nvim\_win\_set\_width()]  
Sets the window width. This will only succeed if the screen is split vertically.

Attributes:

Since: 0.1.0

Parameters:

`{window}` [window-ID], or 0 for current window

`{width}` Width as a count of columns

nvim\_win\_text\_height(`{window}`, `{opts}`) [nvim\_win\_text\_height()]  
Computes the number of screen lines occupied by a range of text in a given window. Works for off-screen text and takes folds into account.

Diff filler or virtual lines above a line are counted as a part of that line, unless the line is on "start\_row" and "start\_vcol" is specified.

Diff filler or virtual lines below the last buffer line are counted in the result when "end\_row" is omitted.

Line indexing is similar to [nvim\_buf\_get\_text()].

Attributes:

Since: 0.10.0

Parameters:

`{window}` [window-ID], or 0 for current window.

`{opts}` Optional parameters:

start\_row: Starting line index, 0-based inclusive. When omitted start at the very top.

end\_row: Ending line index, 0-based inclusive. When omitted end at the very bottom.

start\_vcol: Starting virtual column index on "start\_row", 0-based inclusive, rounded down to full screen lines. When omitted include the whole line.

end\_vcol: Ending virtual column index on "end\_row", 0-based exclusive, rounded up to full screen lines. When 0 only include diff filler and virtual lines above "end\_row". When omitted include the whole line.

max\_height: Don't add the height of lines below the row for which this height is reached. Useful to e.g. limit the height to the window height, avoiding unnecessary work. Or to find out how many buffer lines beyond "start\_row" take up a certain number of logical lines (returned in "end\_row" and "end\_vcol").

Return:

Dict containing text height information, with these keys:

all: The total number of screen lines occupied by the range.

fill: The number of diff filler or virtual lines among them.

end\_row: The row on which the returned height is reached (first row of a closed fold).

end\_vcol: Ending virtual column in "end\_row" where "max\_height" or the returned height is reached. 0 if "end\_row" is a closed fold.

See also:

[virtcol()] for text width.

## Win\_config Functions [api-win\_config]

nvim\_open\_win(`{buffer}`, `{enter}`, `{config}`) [nvim\_open\_win()]  
Opens a new split window, or a floating window if `relative` is specified, or an external window (managed by the UI) if `external` is specified.

Floats are windows that are drawn above the split layout, at some anchor position in some other window. Floats can be drawn internally or by external GUI with the [ui-multigrid] extension. External windows are only supported with multigrid GUIs, and are displayed as separate top-level windows.

For a general overview of floats, see [api-floatwin].

The `width` and `height` of the new window must be specified when opening a floating window, but are optional for normal windows.

If `relative` and `external` are omitted, a normal "split" window is created. The `win` property determines which window will be split. If no `win` is provided or `win == 0`, a window will be created adjacent to the current window. If -1 is provided, a top-level split will be created. `vertical` and `split` are only valid for normal windows, and are used to control split direction. For `vertical`, the exact direction is determined by ['splitright'] and ['splitbelow']. Split windows cannot have `bufpos`/\`row\`/\`col\`/\`border\`/\`title\`/\`footer\` properties.

With relative=editor (row=0,col=0) refers to the top-left corner of the screen-grid and (row=Lines-1,col=Columns-1) refers to the bottom-right corner. Fractional values are allowed, but the builtin implementation (used by non-multigrid UIs) will always round down to nearest integer.

Out-of-bounds values, and configurations that make the float not fit inside the main editor, are allowed. The builtin implementation truncates values so floats are fully within the main screen grid. External GUIs could let floats hover outside of the main window like a tooltip, but this should not be used to specify arbitrary WM screen positions.

Example (Lua): window-relative float

    vim.api.nvim_open_win(0, false,
      {relative='win', row=3, col=3, width=12, height=3})

Example (Lua): buffer-relative float (travels as buffer is scrolled)

    vim.api.nvim_open_win(0, false,
      {relative='win', width=12, height=3, bufpos={100,10}})

Example (Lua): vertical split left of the current window

    vim.api.nvim_open_win(0, false, {
      split = 'left',
      win = 0
    })

Attributes:

not allowed when [textlock] is active Since: 0.4.0

Parameters:

`{buffer}` Buffer to display, or 0 for current buffer

`{enter}` Enter the window (make it the current window)

`{config}` Map defining the window configuration. Keys:

relative: Sets the window layout to "floating", placed at (row,col) coordinates relative to:

"cursor" Cursor position in current window.

"editor" The global editor grid.

"laststatus" ['laststatus'] if present, or last row.

"mouse" Mouse position.

"tabline" Tabline if present, or first row.

"win" Window given by the `win` field, or current window.

win: [window-ID] window to split, or relative window when creating a float (relative="win").

anchor: Decides which corner of the float to place at (row,col):

"NW" northwest (default)

"NE" northeast

"SW" southwest

"SE" southeast

width: Window width (in character cells). Minimum of 1.

height: Window height (in character cells). Minimum of 1.

bufpos: Places float relative to buffer text (only when relative="win"). Takes a tuple of zero-indexed `[line, column]`. `row` and `col` if given are applied relative to this position, else they default to:

`row=1` and `col=0` if `anchor` is "NW" or "NE"

`row=0` and `col=0` if `anchor` is "SW" or "SE" (thus like a tooltip near the buffer text).

row: Row position in units of "screen cell height", may be fractional.

col: Column position in units of screen cell width, may be fractional.

focusable: Enable focus by user actions (wincmds, mouse events). Defaults to true. Non-focusable windows can be entered by [nvim\_set\_current\_win()], or, when the `mouse` field is set to true, by mouse events. See [focusable].

mouse: Specify how this window interacts with mouse events. Defaults to `focusable` value.

If false, mouse events pass through this window.

If true, mouse events interact with this window normally.

external: GUI should display the window as an external top-level window. Currently accepts no other positioning configuration together with this.

zindex: Stacking order. floats with higher `zindex` go on top on floats with lower indices. Must be larger than zero. The following screen elements have hard-coded z-indices:

100: insert completion popupmenu

200: message scrollback

250: cmdline completion popupmenu (when wildoptions+=pum) The default value for floats are 50. In general, values below 100 are recommended, unless there is a good reason to overshadow builtin elements.

style: (optional) Configure the appearance of the window. Currently only supports one value:

"minimal" Nvim will display the window with many UI options disabled. This is useful when displaying a temporary float where the text should not be edited. Disables ['number'], ['relativenumber'], ['cursorline'](https://neovim.io/doc/user/options.html#'cursorline'), ['cursorcolumn'](https://neovim.io/doc/user/options.html#'cursorcolumn'), ['foldcolumn'](https://neovim.io/doc/user/options.html#'foldcolumn'), ['spell'](https://neovim.io/doc/user/options.html#'spell') and ['list'](https://neovim.io/doc/user/options.html#'list') options. ['signcolumn'](https://neovim.io/doc/user/options.html#'signcolumn') is changed to `auto` and ['colorcolumn'](https://neovim.io/doc/user/options.html#'colorcolumn') is cleared. ['statuscolumn'](https://neovim.io/doc/user/options.html#'statuscolumn') is changed to empty. The end-of-buffer region is hidden by setting `eob` flag of ['fillchars'](https://neovim.io/doc/user/options.html#'fillchars') to a space char, and clearing the [hl-EndOfBuffer](https://neovim.io/doc/user/syntax.html#hl-EndOfBuffer) region in ['winhighlight'](https://neovim.io/doc/user/options.html#'winhighlight').

border: (`string|string[]`)  Window border. The string form accepts the same values as the ['winborder'] option. The array form must have a length of eight or any divisor of eight, specifying the chars that form the border in a clockwise fashion starting from the top-left corner. For example, the double-box style can be specified as:

\[ "╔", "═" ,"╗", "║", "╝", "═", "╚", "║" \].

If fewer than eight chars are given, they will be repeated. An ASCII border could be specified as:

\[ "/", "-", \\"\\\\\\\\\\", "|" \],

Or one char for all sides:

\[ "x" \].

Empty string can be used to hide a specific border. This example will show only vertical borders, not horizontal:

\[ "", "", "", ">", "", "", "", "<" \]

By default, [hl-FloatBorder] highlight is used, which links to [hl-WinSeparator] when not defined. Each border side can specify an optional highlight:

\[ \["+", "MyCorner"\], \["x", "MyBorder"\] \].

title: (optional) Title in window border, string or list. List should consist of `[text, highlight]` tuples. If string, or a tuple lacks a highlight, the default highlight group is `FloatTitle`.

title\_pos: Title position. Must be set with `title` option. Value can be one of "left", "center", or "right". Default is `"left"`.

footer: (optional) Footer in window border, string or list. List should consist of `[text, highlight]` tuples. If string, or a tuple lacks a highlight, the default highlight group is `FloatFooter`.

footer\_pos: Footer position. Must be set with `footer` option. Value can be one of "left", "center", or "right". Default is `"left"`.

noautocmd: If true then all autocommands are blocked for the duration of the call.

fixed: If true when anchor is NW or SW, the float window would be kept fixed even if the window would be truncated.

hide: If true the floating window will be hidden and the cursor will be invisible when focused on it.

vertical: Split vertically [:vertical].

split: Split direction: "left", "right", "above", "below".

\_cmdline\_offset: (EXPERIMENTAL) When provided, anchor the [cmdline-completion] popupmenu to this window, with an offset in screen cell width.

Return:

[window-ID], or 0 on error

nvim\_win\_get\_config(`{window}`) [nvim\_win\_get\_config()]  
Gets window configuration.

The returned value may be given to [nvim\_open\_win()].

`relative` is empty for normal windows.

Attributes:

Since: 0.4.0

Parameters:

`{window}` [window-ID], or 0 for current window

Return:

Map defining the window configuration, see [nvim\_open\_win()]

nvim\_win\_set\_config(`{window}`, `{config}`) [nvim\_win\_set\_config()]  
Configures window layout. Cannot be used to move the last window in a tabpage to a different one.

When reconfiguring a window, absent option keys will not be changed. `row`/\`col\` and `relative` must be reconfigured together.

Attributes:

Since: 0.4.0

Parameters:

`{window}` [window-ID], or 0 for current window

`{config}` Map defining the window configuration, see [nvim\_open\_win()]

See also:

[nvim\_open\_win()]

## Tabpage Functions [api-tabpage]

nvim\_tabpage\_del\_var(`{tabpage}`, `{name}`) [nvim\_tabpage\_del\_var()]  
Removes a tab-scoped (t:) variable

Attributes:

Since: 0.1.0

Parameters:

`{tabpage}` [tab-ID], or 0 for current tabpage

`{name}` Variable name

nvim\_tabpage\_get\_number(`{tabpage}`) [nvim\_tabpage\_get\_number()]  
Gets the tabpage number

Attributes:

Since: 0.1.0

Parameters:

`{tabpage}` [tab-ID], or 0 for current tabpage

Return:

Tabpage number

nvim\_tabpage\_get\_var(`{tabpage}`, `{name}`) [nvim\_tabpage\_get\_var()]  
Gets a tab-scoped (t:) variable

Attributes:

Since: 0.1.0

Parameters:

`{tabpage}` [tab-ID], or 0 for current tabpage

`{name}` Variable name

Return:

Variable value

nvim\_tabpage\_get\_win(`{tabpage}`) [nvim\_tabpage\_get\_win()]  
Gets the current window in a tabpage

Attributes:

Since: 0.1.0

Parameters:

`{tabpage}` [tab-ID], or 0 for current tabpage

Return:

[window-ID]

nvim\_tabpage\_is\_valid(`{tabpage}`) [nvim\_tabpage\_is\_valid()]  
Checks if a tabpage is valid

Attributes:

Since: 0.1.0

Parameters:

`{tabpage}` [tab-ID], or 0 for current tabpage

Return:

true if the tabpage is valid, false otherwise

nvim\_tabpage\_list\_wins(`{tabpage}`) [nvim\_tabpage\_list\_wins()]  
Gets the windows in a tabpage

Attributes:

Since: 0.1.0

Parameters:

`{tabpage}` [tab-ID], or 0 for current tabpage

Return:

List of windows in `tabpage`

[nvim\_tabpage\_set\_var()]  
nvim\_tabpage\_set\_var(`{tabpage}`, `{name}`, `{value}`) Sets a tab-scoped (t:) variable

Attributes:

Since: 0.1.0

Parameters:

`{tabpage}` [tab-ID], or 0 for current tabpage

`{name}` Variable name

`{value}` Variable value

nvim\_tabpage\_set\_win(`{tabpage}`, `{win}`) [nvim\_tabpage\_set\_win()]  
Sets the current window in a tabpage

Attributes:

Since: 0.10.0

Parameters:

`{tabpage}` [tab-ID], or 0 for current tabpage

`{win}` [window-ID], must already belong to `{tabpage}`

## Autocmd Functions [api-autocmd]

nvim\_clear\_autocmds(`{opts}`) [nvim\_clear\_autocmds()]  
Clears all autocommands selected by `{opts}`. To delete autocmds see [nvim\_del\_autocmd()].

Attributes:

Since: 0.7.0

Parameters:

`{opts}` Parameters

event: (string|table) Examples:

event: "pat1"

event: { "pat1" }

event: { "pat1", "pat2", "pat3" }

pattern: (string|table)

pattern or patterns to match exactly.

For example, if you have `*.py` as that pattern for the autocmd, you must pass `*.py` exactly to clear it. `test.py` will not match the pattern.

defaults to clearing all patterns.

**NOTE:** Cannot be used with `{buffer}`

buffer: (bufnr)

clear only [autocmd-buflocal] autocommands.

**NOTE:** Cannot be used with `{pattern}`

group: (string|int) The augroup name or id.

**NOTE:** If not passed, will only delete autocmds not in any group.

nvim\_create\_augroup(`{name}`, `{opts}`) [nvim\_create\_augroup()]  
Create or get an autocommand group [autocmd-groups].

To get an existing group id, do:

    local id = vim.api.nvim_create_augroup('my.lsp.config', {
        clear = false
    })

Attributes:

Since: 0.7.0

Parameters:

`{name}` String: The name of the group

`{opts}` Dict Parameters

clear (bool) optional: defaults to true. Clear existing commands if the group already exists [autocmd-groups].

Return:

Integer id of the created group.

See also:

[autocmd-groups]

nvim\_create\_autocmd(`{event}`, `{opts}`) [nvim\_create\_autocmd()]  
Creates an [autocommand] event handler, defined by `callback` (Lua function or Vimscript function name string) or `command` (Ex command string).

Example using Lua callback:

    vim.api.nvim_create_autocmd({'BufEnter', 'BufWinEnter'}, {
      pattern = {'*.c', '*.h'},
      callback = function(ev)
        print(string.format('event fired: %s', vim.inspect(ev)))
      end
    })

Example using an Ex command as the handler:

    vim.api.nvim_create_autocmd({'BufEnter', 'BufWinEnter'}, {
      pattern = {'*.c', '*.h'},
      command = "echo 'Entering a C or C++ file'",
    })

**Note:** `pattern` is NOT automatically expanded , thus names like "$HOME" and "~" must be expanded explicitly:

    pattern = vim.fn.expand('~') .. '/some/path/*.py'

Attributes:

Since: 0.7.0

Parameters:

`{event}` (string|array) Event(s) that will trigger the handler (`callback` or `command`).

`{opts}` Options dict:

group (string|integer) optional: autocommand group name or id to match against.

pattern (string|array) optional: pattern(s) to match literally [autocmd-pattern].

buffer (integer) optional: buffer number for buffer-local autocommands [autocmd-buflocal]. Cannot be used with `{pattern}`.

desc (string) optional: description (for documentation and troubleshooting).

callback (function|string) optional: Lua function (or Vimscript function name, if string) called when the event(s) is triggered. Lua callback can return a truthy value (not `false` or `nil`) to delete the autocommand, and receives one argument, a table with these keys: [event-args]  

id: (number) autocommand id

event: (string) name of the triggered event [autocmd-events]

group: (number|nil) autocommand group id, if any

file: (string) `<afile>` (not expanded to a full path)

match: (string) `<amatch>` (expanded to a full path)

buf: (number) `<abuf>`

data: (any) arbitrary data passed from [nvim\_exec\_autocmds()] [event-data]  

command (string) optional: Vim command to execute on event. Cannot be used with `{callback}`

once (boolean) optional: defaults to false. Run the autocommand only once [autocmd-once].

nested (boolean) optional: defaults to false. Run nested autocommands [autocmd-nested].

Return:

Autocommand id (number)

See also:

[autocommand]

[nvim\_del\_autocmd()]

nvim\_del\_augroup\_by\_id(`{id}`) [nvim\_del\_augroup\_by\_id()]  
Delete an autocommand group by id.

To get a group id one can use [nvim\_get\_autocmds()].

**NOTE:** behavior differs from [:augroup-delete]. When deleting a group, autocommands contained in this group will also be deleted and cleared. This group will no longer exist.

Attributes:

Since: 0.7.0

Parameters:

`{id}` Integer The id of the group.

See also:

[nvim\_del\_augroup\_by\_name()]

[nvim\_create\_augroup()]

nvim\_del\_augroup\_by\_name(`{name}`) [nvim\_del\_augroup\_by\_name()]  
Delete an autocommand group by name.

**NOTE:** behavior differs from [:augroup-delete]. When deleting a group, autocommands contained in this group will also be deleted and cleared. This group will no longer exist.

Attributes:

Since: 0.7.0

Parameters:

`{name}` String The name of the group.

See also:

[autocmd-groups]

nvim\_del\_autocmd(`{id}`) [nvim\_del\_autocmd()]  
Deletes an autocommand by id.

Attributes:

Since: 0.7.0

Parameters:

`{id}` Integer Autocommand id returned by [nvim\_create\_autocmd()]

nvim\_exec\_autocmds(`{event}`, `{opts}`) [nvim\_exec\_autocmds()]  
Execute all autocommands for `{event}` that match the corresponding `{opts}` [autocmd-execute].

Attributes:

Since: 0.7.0

Parameters:

`{event}` (String|Array) The event or events to execute

`{opts}` Dict of autocommand options:

group (string|integer) optional: the autocommand group name or id to match against. [autocmd-groups].

pattern (string|array) optional: defaults to "\*" [autocmd-pattern]. Cannot be used with `{buffer}`.

buffer (integer) optional: buffer number [autocmd-buflocal]. Cannot be used with `{pattern}`.

modeline (bool) optional: defaults to true. Process the modeline after the autocommands `<nomodeline>`.

data (any): arbitrary data to send to the autocommand callback. See [nvim\_create\_autocmd()] for details.

See also:

[:doautocmd]

nvim\_get\_autocmds(`{opts}`) [nvim\_get\_autocmds()]  
Get all autocommands that match the corresponding `{opts}`.

These examples will get autocommands matching ALL the given criteria:

    -- Matches all criteria
    autocommands = vim.api.nvim_get_autocmds({
      group = 'MyGroup',
      event = {'BufEnter', 'BufWinEnter'},
      pattern = {'*.c', '*.h'}
    })
    -- All commands from one group
    autocommands = vim.api.nvim_get_autocmds({
      group = 'MyGroup',
    })

**NOTE:** When multiple patterns or events are provided, it will find all the autocommands that match any combination of them.

Attributes:

Since: 0.7.0

Parameters:

`{opts}` Dict with at least one of the following:

buffer: (integer) Buffer number or list of buffer numbers for buffer local autocommands [autocmd-buflocal]. Cannot be used with `{pattern}`

event: (string|table) event or events to match against [autocmd-events].

id: (integer) Autocommand ID to match.

group: (string|table) the autocommand group name or id to match against.

pattern: (string|table) pattern or patterns to match against [autocmd-pattern]. Cannot be used with `{buffer}`

Return:

Array of autocommands matching the criteria, with each item containing the following fields:

buffer: (integer) the buffer number.

buflocal: (boolean) true if the autocommand is buffer local.

command: (string) the autocommand command. **Note:** this will be empty if a callback is set.

callback: (function|string|nil): Lua function or name of a Vim script function which is executed when this autocommand is triggered.

desc: (string) the autocommand description.

event: (string) the autocommand event.

id: (integer) the autocommand id (only when defined with the API).

group: (integer) the autocommand group id.

group\_name: (string) the autocommand group name.

once: (boolean) whether the autocommand is only run once.

pattern: (string) the autocommand pattern. If the autocommand is buffer local [autocmd-buffer-local]:

## UI Functions [api-ui]

nvim\_ui\_attach(`{width}`, `{height}`, `{options}`) [nvim\_ui\_attach()]  
Activates UI events on the channel.

Entry point of all UI clients. Allows [\--embed] to continue startup. Implies that the client is ready to show the UI. Adds the client to the list of UIs. [nvim\_list\_uis()]

**Note:**

If multiple UI clients are attached, the global screen dimensions degrade to the smallest client. E.g. if client A requests 80x40 but client B requests 200x100, the global screen has size 80x40.

Attributes:

[RPC] only Since: 0.1.0

Parameters:

`{width}` Requested screen columns

`{height}` Requested screen rows

`{options}` [ui-option] map

nvim\_ui\_detach() [nvim\_ui\_detach()]  
Deactivates UI events on the channel.

Removes the client from the list of UIs. [nvim\_list\_uis()]

Attributes:

[RPC] only Since: 0.1.0

[nvim\_ui\_pum\_set\_bounds()]  
nvim\_ui\_pum\_set\_bounds(`{width}`, `{height}`, `{row}`, `{col}`) Tells Nvim the geometry of the popupmenu, to align floating windows with an external popup menu.

Note that this method is not to be confused with [nvim\_ui\_pum\_set\_height()], which sets the number of visible items in the popup menu, while this function sets the bounding box of the popup menu, including visual elements such as borders and sliders. Floats need not use the same font size, nor be anchored to exact grid corners, so one can set floating-point numbers to the popup menu geometry.

Attributes:

[RPC] only Since: 0.5.0

Parameters:

`{width}` Popupmenu width.

`{height}` Popupmenu height.

`{row}` Popupmenu row.

`{col}` Popupmenu height.

nvim\_ui\_pum\_set\_height(`{height}`) [nvim\_ui\_pum\_set\_height()]  
Tells Nvim the number of elements displaying in the popupmenu, to decide `<PageUp>` and `<PageDown>` movement.

Attributes:

[RPC] only Since: 0.4.0

Parameters:

`{height}` Popupmenu height, must be greater than zero.

nvim\_ui\_set\_focus(`{gained}`) [nvim\_ui\_set\_focus()]  
Tells the nvim server if focus was gained or lost by the GUI

Attributes:

[RPC] only Since: 0.9.0

nvim\_ui\_set\_option(`{name}`, `{value}`) [nvim\_ui\_set\_option()]  

Attributes:

[RPC] only Since: 0.1.0

nvim\_ui\_term\_event(`{event}`, `{value}`) [nvim\_ui\_term\_event()]  
Tells Nvim when a terminal event has occurred

The following terminal events are supported:

"termresponse": The terminal sent an OSC or DCS response sequence to Nvim. The payload is the received response. Sets [v:termresponse] and fires [TermResponse].

Attributes:

[RPC] only Since: 0.10.0

Parameters:

`{event}` Event name

`{value}` Event payload

nvim\_ui\_try\_resize(`{width}`, `{height}`) [nvim\_ui\_try\_resize()]  

Attributes:

[RPC] only Since: 0.1.0

[nvim\_ui\_try\_resize\_grid()]  
nvim\_ui\_try\_resize\_grid(`{grid}`, `{width}`, `{height}`) Tell Nvim to resize a grid. Triggers a grid\_resize event with the requested grid size or the maximum size if it exceeds size limits.

On invalid grid handle, fails with error.

Attributes:

[RPC] only Since: 0.4.0

Parameters:

`{grid}` The handle of the grid to be changed.

`{width}` The new requested width.

`{height}` The new requested height.
