[

# Autocmd

](https://neovim.io/doc/user/autocmd.html#autocmd)

_Nvim `:help` pages, [generated] from [source] using the [tree-sitter-vimdoc] parser._

---

Automatic commands [autocommand]

For a basic explanation, see section [40.3] in the user manual.

## 1\. Introduction [autocmd-intro]

You can specify commands to be executed automatically when reading or writing a file, when entering or leaving a buffer or window, and when exiting Vim. For example, you can create an autocommand to set the ['cindent'] option for files matching `*.c`. You can also use autocommands to implement advanced features, such as editing compressed files . The usual place to put autocommands is in your vimrc file.

[E203] [E204] [E143] [E855] [E937] [E952] **WARNING:** Using autocommands is very powerful, and may lead to unexpected side effects. Be careful not to destroy your text.

It's a good idea to do some testing on an expendable copy of a file first. For example: If you use autocommands to decompress a file when starting to edit it, make sure that the autocommands for compressing when writing work correctly.

Be prepared for an error halfway through (e.g., disk full). Vim will mostly be able to undo the changes to the buffer, but you may have to clean up the changes to other files by hand (e.g., compress a file that has been decompressed).

If the BufRead\* events allow you to edit a compressed file, the FileRead\* events should do the same (this makes recovery possible in some rare cases). It's a good idea to use the same autocommands for the File\* and Buf\* events when possible.

## 2\. Defining autocommands [autocmd-define]

[:au] [:autocmd] :au\[tocmd\] \[group\] `{event}` `{aupat}` \[++once\] \[++nested\] `{cmd}` Add `{cmd}` to the list of commands that Vim will execute automatically on `{event}` for a file matching `{aupat}` [autocmd-pattern]. **Note:** A quote character is seen as argument to the :autocmd and won't start a comment. Nvim always adds `{cmd}` after existing autocommands so they execute in the order in which they were defined. See [autocmd-nested] for \[++nested\]. [autocmd-once]  
If \[++once\] is supplied the command is executed once, then removed ("one shot").

The special pattern `<buffer>` or <buffer=N> defines a buffer-local autocommand. See [autocmd-buflocal].

**Note:** The ":autocmd" command can only be followed by another command when the "|" appears where the pattern is expected. This works:

:augroup mine | au! BufRead | augroup END

But this sees "augroup" as part of the defined command:

:augroup mine | au! BufRead \* | augroup END
:augroup mine | au BufRead \* set tw=70 | augroup END

Instead you can put the group name into the command:

:au! mine BufRead \*
:au mine BufRead \* set tw=70

Or use `:execute`:

:augroup mine | exe "au! BufRead \*" | augroup END
:augroup mine | exe "au BufRead \* set tw=70" | augroup END

[autocmd-expand]  
Note that special characters (e.g., "%", "<cword>") in the ":autocmd" arguments are not expanded when the autocommand is defined. These will be expanded when the Event is recognized, and the `{cmd}` is executed. The only exception is that "<sfile>" is expanded when the autocmd is defined. Example:

:au BufNewFile,BufRead \*.html so <sfile>:h/html.vim

Here Vim expands `<sfile>` to the name of the file containing this line.

`:autocmd` adds to the list of autocommands regardless of whether they are already present. When your .vimrc file is sourced twice, the autocommands will appear twice. To avoid this, define your autocommands in a group, so that you can easily clear them:

augroup vimrc
" Remove all vimrc autocommands
autocmd!
au BufNewFile,BufRead \*.html so <sfile>:h/html.vim
augroup END

If you don't want to remove all autocommands, you can instead use a variable to ensure that Vim includes the autocommands only once:

:if !exists("autocommands_loaded")
: let autocommands_loaded = 1
: au ...
:endif

When the \[group\] argument is not given, Vim uses the current group (as defined with ":augroup"); otherwise, Vim uses the group defined with \[group\]. Note that \[group\] must have been defined before. You cannot define a new group with ":au group ..."; use ":augroup" for that.

While testing autocommands, you might find the ['verbose'] option to be useful:

:set verbose=9

This setting makes Vim echo the autocommands as it executes them.

When defining an autocommand in a script, it will be able to call functions local to the script and use mappings local to the script. When the event is triggered and the command executed, it will run in the context of the script it was defined in. This matters if [<SID>] is used in a command.

When executing the commands, the message from one command overwrites a previous message. This is different from when executing the commands manually. Mostly the screen will not scroll up, thus there is no hit-enter prompt. When one command outputs two messages this can happen anyway.

## 3\. Removing autocommands [autocmd!] [autocmd-remove]

:au\[tocmd\]! \[group\] `{event}` `{aupat}` \[++once\] \[++nested\] `{cmd}` Remove all autocommands associated with `{event}` and `{aupat}`, and add the command `{cmd}`. See [autocmd-once] for \[++once\]. See [autocmd-nested] for \[++nested\].

:au\[tocmd\]! \[group\] `{event}` `{aupat}` Remove all autocommands associated with `{event}` and `{aupat}`.

:au\[tocmd\]! \[group\] \* `{aupat}` Remove all autocommands associated with `{aupat}` for all events.

:au\[tocmd\]! \[group\] `{event}` Remove ALL autocommands for `{event}`. **Warning:** You should not do this without a group for [BufRead] and other common events, it can break plugins, syntax highlighting, etc.

:au\[tocmd\]! \[group\] Remove ALL autocommands. **Note:** a quote will be seen as argument to the :autocmd and won't start a comment. **Warning:** You should normally not do this without a group, it breaks plugins, syntax highlighting, etc.

When the \[group\] argument is not given, Vim uses the current group (as defined with ":augroup"); otherwise, Vim uses the group defined with \[group\].

## 4\. Listing autocommands [autocmd-list]

:au\[tocmd\] \[group\] `{event}` `{aupat}` Show the autocommands associated with `{event}` and `{aupat}`.

:au\[tocmd\] \[group\] \* `{aupat}` Show the autocommands associated with `{aupat}` for all events.

:au\[tocmd\] \[group\] `{event}` Show all autocommands for `{event}`.

:au\[tocmd\] \[group\] Show all autocommands.

If you provide the \[group\] argument, Vim lists only the autocommands for \[group\]; otherwise, Vim lists the autocommands for ALL groups. Note that this argument behavior differs from that for defining and removing autocommands.

In order to list buffer-local autocommands, use a pattern in the form `<buffer>` or <buffer=N>. See [autocmd-buflocal].

[:autocmd-verbose]  
When ['verbose'] is non-zero, listing an autocommand will also display where it was last defined. Example:

:verbose autocmd BufEnter
FileExplorer BufEnter \* call s:LocalBrowse(expand("<amatch>"))
Last set from /usr/share/vim/vim-7.0/plugin/NetrwPlugin.vim

See [:verbose-cmd] for more information.

## 5\. Events [autocmd-events] [E215] [E216]

You can specify a comma-separated list of event names. No white space can be used in this list. The command applies to all the events in the list.

For READING FILES there are four kinds of events possible: BufNewFile starting to edit a non-existent file BufReadPre BufReadPost starting to edit an existing file FilterReadPre FilterReadPost read the temp file with filter output FileReadPre FileReadPost any other file read Vim uses only one of these four kinds when reading a file. The "Pre" and "Post" events are both triggered, before and after reading the file.

Note that the autocommands for the "\*ReadPre" events and all the Filter events are not allowed to change the current buffer (you will get an error message if this happens). This is to prevent the file to be read into the wrong buffer.

Note that the ['modified'] flag is reset AFTER executing the BufReadPost and BufNewFile autocommands. But when the ['modified'] option was set by the autocommands, this doesn't happen.

You can use the ['eventignore'] option to ignore a number of events or all events.

[events] [{event}] Nvim recognizes the following events. Names are case-insensitive.

[BufAdd]  
BufAdd After adding a new buffer or existing unlisted buffer to the buffer list , or renaming a listed buffer. Before [BufEnter]. **NOTE:** Current buffer "%" is not the target buffer "<afile>", "<abuf>". [<buffer=abuf>] [BufDelete]  
BufDelete Before deleting a buffer from the buffer list. The BufUnload may be called first (if the buffer was loaded). Also used just before a buffer in the buffer list is renamed. **NOTE:** Current buffer "%" is not the target buffer "<afile>", "<abuf>". [<buffer=abuf>] Do not change to another buffer. [BufEnter]  
BufEnter After entering (visiting, switching-to) a new or existing buffer. Useful for setting filetype options. Compare [BufNew] which does not trigger for existing buffers. After [BufAdd]. After [BufReadPost]. [BufFilePost]  
BufFilePost After changing the name of the current buffer with the ":file" or ":saveas" command. [BufFilePre]  
BufFilePre Before changing the name of the current buffer with the ":file" or ":saveas" command. [BufHidden]  
BufHidden Before a buffer becomes hidden: when there are no longer windows that show the buffer, but the buffer is not unloaded or deleted.

Not used for ":qa" or ":q" when exiting Vim. **NOTE:** Current buffer "%" is not the target buffer "<afile>", "<abuf>". [<buffer=abuf>] [BufLeave]  
BufLeave Before leaving to another buffer. Also when leaving or closing the current window and the new current window is not for the same buffer.

Not used for ":qa" or ":q" when exiting Vim. [BufModifiedSet]  
BufModifiedSet After the `'modified'` value of a buffer has been changed. [BufNew]  
BufNew After creating a new buffer or renaming an existing buffer. Unlike [BufEnter], visiting (switching to) an existing buffer will not trigger this again. **NOTE:** Current buffer "%" is not the target buffer "<afile>", "<abuf>". [<buffer=abuf>] See also [BufAdd], [BufNewFile](https://neovim.io/doc/user/autocmd.html#BufNewFile). [BufNewFile](https://neovim.io/doc/user/autocmd.html#BufNewFile)  
BufNewFile When starting to edit a file that doesn't exist. Can be used to read in a skeleton file. [BufRead] [BufReadPost] BufRead or BufReadPost When starting to edit a new buffer, after reading the file into the buffer, before processing modelines. See [BufWinEnter] to do something after processing modelines. Also triggered:

when writing an unnamed buffer in a way that the buffer gets a name

after successfully recovering a file

for the "filetypedetect" group when executing ":filetype detect" Not triggered:

for the `:read file` command

when the file doesn't exist [BufReadCmd]  
BufReadCmd Before starting to edit a new buffer. Should read the file into the buffer. [Cmd-event] [BufReadPre] [E200] [E201] BufReadPre When starting to edit a new buffer, before reading the file into the buffer. Not used if the file doesn't exist. [BufUnload](https://neovim.io/doc/user/autocmd.html#BufUnload)  
BufUnload Before unloading a buffer, when the text in the buffer is going to be freed. After BufWritePost. Before BufDelete. Triggers for all loaded buffers when Vim is going to exit. **NOTE:** Current buffer "%" is not the target buffer "<afile>", "<abuf>". [<buffer=abuf>] Do not switch buffers or windows! Not triggered when exiting and v:dying is 2 or more. [BufWinEnter]  
BufWinEnter After a buffer is displayed in a window. This may be when the buffer is loaded (after processing modelines) or when a hidden buffer is displayed (and is no longer hidden).

Not triggered for [:split] without arguments, since the buffer does not change, or :split with a file already open in a window. Triggered for ":split" with the name of the current buffer, since it reloads that buffer. [BufWinLeave]  
BufWinLeave Before a buffer is removed from a window. Not when it's still visible in another window. Also triggered when exiting. Before BufUnload, BufHidden. **NOTE:** Current buffer "%" is not the target buffer "<afile>", "<abuf>". [<buffer=abuf>] Not triggered when exiting and v:dying is 2 or more. [BufWipeout]  
BufWipeout Before completely deleting a buffer. The BufUnload and BufDelete events may be called first (if the buffer was loaded and was in the buffer list). Also used just before a buffer is renamed (also when it's not in the buffer list). **NOTE:** Current buffer "%" is not the target buffer "<afile>", "<abuf>". [<buffer=abuf>] Do not change to another buffer. [BufWrite] [BufWritePre] BufWrite or BufWritePre Before writing the whole buffer to a file. [BufWriteCmd]  
BufWriteCmd Before writing the whole buffer to a file. Should do the writing of the file and reset ['modified'] if successful, unless '+' is in ['cpo'] and writing to another file [cpo-+]. The buffer contents should not be changed. When the command resets ['modified'] the undo information is adjusted to mark older undo states as ['modified'](https://neovim.io/doc/user/options.html#'modified'), like [:write](https://neovim.io/doc/user/editing.html#%3Awrite) does. Use the ['\[](https://neovim.io/doc/user/motion.html#'%5B) and ['\]](https://neovim.io/doc/user/motion.html#'%5D) marks for the range of lines. [Cmd-event](https://neovim.io/doc/user/autocmd.html#Cmd-event) [BufWritePost](https://neovim.io/doc/user/autocmd.html#BufWritePost)  
BufWritePost After writing the whole buffer to a file (should undo the commands for BufWritePre). [ChanInfo]  
ChanInfo State of channel changed, for instance the client of a RPC channel described itself. This is triggered even when inside an autocommand defined without [autocmd-nested]. Sets these [v:event] keys: info as from [nvim\_get\_chan\_info()] [ChanOpen]  
ChanOpen Just after a channel was opened. This is triggered even when inside an autocommand defined without [autocmd-nested]. Sets these [v:event] keys: info as from [nvim\_get\_chan\_info()] [CmdUndefined]  
CmdUndefined When a user command is used but it isn't defined. Useful for defining a command only when it's used. The pattern is matched against the command name. Both `<amatch>` and `<afile>` expand to the command name. This is triggered even when inside an autocommand defined without [autocmd-nested]. **NOTE:** Autocompletion won't work until the command is defined. An alternative is to always define the user command and have it invoke an autoloaded function. See [autoload]. [CmdlineChanged]  
CmdlineChanged After a change was made to the text inside command line. Be careful not to mess up the command line, it may cause Vim to lock up. `<afile>` expands to the [cmdline-char]. [CmdlineEnter]  
CmdlineEnter After entering the command-line . The pattern is matched against [cmdline-char]. `<afile>` expands to the [cmdline-char]. Sets these [v:event] keys: cmdlevel cmdtype [CmdlineLeave](https://neovim.io/doc/user/autocmd.html#CmdlineLeave)  
CmdlineLeave Before leaving the command-line . `<afile>` expands to the [cmdline-char]. Sets these [v:event] keys: abort (mutable) cmdlevel cmdtype **Note:** `abort` can only be changed from false to true: cannot execute an already aborted cmdline by changing it to false. [CmdlineLeavePre]  
CmdlineLeavePre Just before leaving the command line, and before [CmdlineLeave]. Useful for capturing completion info with [cmdcomplete\_info()], as this information is cleared before [CmdlineLeave] is triggered. Triggered for non-interactive use of ":" in a mapping, but not when using [<Cmd>]. Also triggered when abandoning the command line by typing `CTRL-C` or `<Esc>`. `<afile>` is set to [cmdline-char](https://neovim.io/doc/user/cmdline.html#cmdline-char). [CmdwinEnter](https://neovim.io/doc/user/autocmd.html#CmdwinEnter)  
CmdwinEnter After entering the command-line window. Useful for setting options specifically for this special type of window. `<afile>` expands to a single character, indicating the type of command-line. [cmdwin-char] [CmdwinLeave]  
CmdwinLeave Before leaving the command-line window. Useful to clean up any global setting done with CmdwinEnter. `<afile>` expands to a single character, indicating the type of command-line. [cmdwin-char] [ColorScheme]  
ColorScheme After loading a color scheme. [:colorscheme] Not triggered if the color scheme is not found. The pattern is matched against the colorscheme name. `<afile>` can be used for the name of the actual file where this option was set, and `<amatch>` for the new colorscheme name.

[ColorSchemePre]  
ColorSchemePre Before loading a color scheme. [:colorscheme] Useful to setup removing things added by a color scheme, before another one is loaded.

CompleteChanged [CompleteChanged]  
After each time the Insert mode completion menu changed. Not fired on popup menu hide, use [CompleteDonePre] or [CompleteDone] for that.

Sets these [v:event] keys: completed_item See [complete-items]. height nr of items visible width screen cells row top screen row col leftmost screen column size total nr of items scrollbar TRUE if visible

Non-recursive (event cannot trigger itself). Cannot change the text. [textlock]

The size and position of the popup are also available by calling [pum\_getpos()].

[CompleteDonePre]  
CompleteDonePre After Insert mode completion is done. Either when something was completed or discarded. [ins-completion] [complete\_info()] is valid during this event. [v:completed\_item] gives the completed item.

[CompleteDone]  
CompleteDone After Insert mode completion is done. Either when something was completed or discarded. [ins-completion] [complete\_info()] is cleared before this; use CompleteDonePre if you need it. [v:completed\_item] gives the completed item, or empty dict if completion was discarded.

Sets these [v:event] keys: complete_word The word that was selected, empty if completion was abandoned (discarded). complete_type [complete\_info\_mode] reason Reason for completion being done. Can be one of:

"accept": completion was accepted by [complete\_CTRL-Y].

"cancel": completion was stopped by [complete\_CTRL-E].

"discard": completion was abandoned for other reason.

[CursorHold]  
CursorHold When the user doesn't press a key for the time specified with ['updatetime']. Not triggered until the user has pressed a key See [CursorHold-example] for previewing tags. This event is only triggered in Normal mode. It is not triggered when waiting for a command argument to be typed, or a movement after an operator. While recording the CursorHold event is not triggered. [q] [<CursorHold>](https://neovim.io/doc/user/autocmd.html#%3CCursorHold%3E)  
Internally the autocommand is triggered by the `<CursorHold>` key. In an expression mapping [getchar()] may see this character.

**Note:** Interactive commands cannot be used for this event. There is no hit-enter prompt, the screen is updated directly (when needed). **Note:** In the future there will probably be another option to set the time. Hint: to force an update of the status lines use:

:let &ro = &ro

[CursorHoldI]  
CursorHoldI Like CursorHold, but in Insert mode. Not triggered when waiting for another key, e.g. after `CTRL-V`, and not in `CTRL-X` mode [insert\_expand].

[CursorMoved]  
CursorMoved After the cursor was moved in Normal or Visual mode or to another window. Also when the text of the cursor line has been changed, e.g. with "x", "rx" or "p". Not always triggered when there is typeahead, while executing commands in a script file, or when an operator is pending. For an example see [match-parens]. **Note:** Cannot be skipped with [:noautocmd]. Careful: This is triggered very often, don't do anything that the user does not expect or that is slow. [CursorMovedC]  
CursorMovedC After the cursor was moved in the command line. Be careful not to mess up the command line, it may cause Vim to lock up. `<afile>` expands to the [cmdline-char]. [CursorMovedI]  
CursorMovedI After the cursor was moved in Insert mode. Not triggered when the popup menu is visible. Otherwise the same as CursorMoved. [DiffUpdated]  
DiffUpdated After diffs have been updated. Depending on what kind of diff is being used (internal or external) this can be triggered on every change or when doing [:diffupdate]. [DirChanged]  
DirChanged After the [current-directory] was changed. The pattern can be: "window" to trigger on `:lcd` "tabpage" to trigger on `:tcd` "global" to trigger on `:cd` "auto" to trigger on ['autochdir']. Sets these [v:event] keys: cwd: current working directory scope: "global", "tabpage", "window" changed_window: v:true if we fired the event switching window (or tab) `<afile>` is set to the new directory name. Non-recursive (event cannot trigger itself). [DirChangedPre]  
DirChangedPre When the [current-directory] is going to be changed, as with [DirChanged]. The pattern is like with [DirChanged]. Sets these [v:event] keys: directory: new working directory scope: "global", "tabpage", "window" changed_window: v:true if we fired the event switching window (or tab) `<afile>` is set to the new directory name. Non-recursive (event cannot trigger itself). [ExitPre](https://neovim.io/doc/user/autocmd.html#ExitPre)  
ExitPre When using `:quit`, `:wq` in a way it makes Vim exit, or using `:qall`, just after [QuitPre]. Can be used to close any non-essential window. Exiting may still be cancelled if there is a modified buffer that isn't automatically saved, use [VimLeavePre] for really exiting. See also [QuitPre], [WinClosed]. [FileAppendCmd](https://neovim.io/doc/user/autocmd.html#FileAppendCmd)  
FileAppendCmd Before appending to a file. Should do the appending to the file. Use the '\[ and '\] marks for the range of lines. [Cmd-event] [FileAppendPost]  
FileAppendPost After appending to a file. [FileAppendPre]  
FileAppendPre Before appending to a file. Use the '\[ and '\] marks for the range of lines. [FileChangedRO]  
FileChangedRO Before making the first change to a read-only file. Can be used to checkout the file from a source control system. Not triggered when the change was caused by an autocommand. Triggered when making the first change in a buffer or the first change after ['readonly'] was set, just before the change is applied to the text. **WARNING:** If the autocommand moves the cursor the effect of the change is undefined. [E788]  
Cannot switch buffers. You can reload the buffer but not edit another one. [E881]  
If the number of lines changes saving for undo may fail and the change will be aborted. [FileChangedShell]  
FileChangedShell When Vim notices that the modification time of a file has changed since editing started. Also when the file attributes of the file change or when the size of the file changes. [timestamp] Triggered for each changed file, after:

executing a shell command

[:checktime]

[FocusGained]

Not used when ['autoread'] is set and the buffer was not changed. If a FileChangedShell autocommand exists the warning message and prompt is not given. [v:fcs\_reason] indicates what happened. Set [v:fcs\_choice] to control what happens next. **NOTE:** Current buffer "%" is not the target buffer "<afile>" and "<abuf>". [<buffer=abuf>] [E246](https://neovim.io/doc/user/autocmd.html#E246) [E811](https://neovim.io/doc/user/autocmd.html#E811) Cannot switch, jump to or delete buffers. Non-recursive (event cannot trigger itself). [FileChangedShellPost](https://neovim.io/doc/user/autocmd.html#FileChangedShellPost)  
FileChangedShellPost After handling a file that was changed outside of Vim. Can be used to update the statusline. [FileReadCmd]  
FileReadCmd Before reading a file with a ":read" command. Should do the reading of the file. [Cmd-event] [FileReadPost]  
FileReadPost After reading a file with a ":read" command. Note that Vim sets the '\[ and '\] marks to the first and last line of the read. This can be used to operate on the lines just read. [FileReadPre]  
FileReadPre Before reading a file with a ":read" command. [FileType]  
FileType When the ['filetype'] option has been set. The pattern is matched against the filetype. `<afile>` is the name of the file where this option was set. `<amatch>` is the new value of ['filetype']. Cannot switch windows or buffers. See [filetypes]. [FileWriteCmd]  
FileWriteCmd Before writing to a file, when not writing the whole buffer. Should do the writing to the file. Should not change the buffer. Use the ['\[] and ['\]] marks for the range of lines. [Cmd-event] [FileWritePost]  
FileWritePost After writing to a file, when not writing the whole buffer. [FileWritePre]  
FileWritePre Before writing to a file, when not writing the whole buffer. Use the ['\[] and ['\]] marks for the range of lines. [FilterReadPost]  
FilterReadPost After reading a file from a filter command. Vim checks the pattern against the name of the current buffer as with FilterReadPre. Not triggered when ['shelltemp'] is off. [FilterReadPre] [E135] FilterReadPre Before reading a file from a filter command. Vim checks the pattern against the name of the current buffer, not the name of the temporary file that is the output of the filter command. Not triggered when ['shelltemp'] is off. [FilterWritePost](https://neovim.io/doc/user/autocmd.html#FilterWritePost)  
FilterWritePost After writing a file for a filter command or making a diff with an external diff . Vim checks the pattern against the name of the current buffer as with FilterWritePre. Not triggered when ['shelltemp'] is off. [FilterWritePre]  
FilterWritePre Before writing a file for a filter command or making a diff with an external diff. Vim checks the pattern against the name of the current buffer, not the name of the temporary file that is the output of the filter command. Not triggered when ['shelltemp'] is off. [FocusGained]  
FocusGained Nvim got focus. [FocusLost]  
FocusLost Nvim lost focus. Also (potentially) when a GUI dialog pops up. [FuncUndefined]  
FuncUndefined When a user function is used but it isn't defined. Useful for defining a function only when it's used. The pattern is matched against the function name. Both `<amatch>` and `<afile>` are set to the name of the function. This is triggered even when inside an autocommand defined without [autocmd-nested]. **NOTE:** When writing Vim scripts a better alternative is to use an autoloaded function. See [autoload-functions]. [UIEnter]  
UIEnter After a UI connects via [nvim\_ui\_attach()], or after builtin TUI is started, after [VimEnter]. Sets these [v:event] keys: chan: [channel-id] of the UI [UILeave](https://neovim.io/doc/user/autocmd.html#UILeave)  
UILeave After a UI disconnects from Nvim, or after builtin TUI is stopped, after [VimLeave]. Sets these [v:event] keys: chan: [channel-id] of the UI [InsertChange]  
InsertChange When typing `<Insert>` while in Insert or Replace mode. The [v:insertmode] variable indicates the new mode. Be careful not to move the cursor or do anything else that the user does not expect. [InsertCharPre]  
InsertCharPre When a character is typed in Insert mode, before inserting the char. The [v:char] variable indicates the char typed and can be changed during the event to insert a different character. When [v:char] is set to more than one character this text is inserted literally.

Cannot change the text. [textlock] [InsertEnter]  
InsertEnter Just before starting Insert mode. Also for Replace mode and Virtual Replace mode. The [v:insertmode] variable indicates the mode. Be careful not to do anything else that the user does not expect. The cursor is restored afterwards. If you do not want that set [v:char] to a non-empty string. [InsertLeavePre]  
InsertLeavePre Just before leaving Insert mode. Also when using `CTRL-O` [i\_CTRL-O]. Be careful not to change mode or use `:normal`, it will likely cause trouble. [InsertLeave]  
InsertLeave Just after leaving Insert mode. Also when using `CTRL-O` [i\_CTRL-O]. But not for [i\_CTRL-C]. LspAttach See [LspAttach] LspDetach See [LspDetach] LspNotify See [LspNotify](https://neovim.io/doc/user/lsp.html#LspNotify) LspProgress See [LspProgress](https://neovim.io/doc/user/lsp.html#LspProgress) LspRequest See [LspRequest](https://neovim.io/doc/user/lsp.html#LspRequest) LspTokenUpdate See [LspTokenUpdate](https://neovim.io/doc/user/lsp.html#LspTokenUpdate) [MenuPopup](https://neovim.io/doc/user/autocmd.html#MenuPopup)  
MenuPopup Just before showing the popup menu (under the right mouse button). Useful for adjusting the menu for what is under the cursor or mouse pointer. The pattern is matched against one or two characters representing the mode: n Normal v Visual o Operator-pending i Insert c Command line tl Terminal [ModeChanged]  
ModeChanged After changing the mode. The pattern is matched against `'old_mode:new_mode'`, for example match against `*:c` to simulate [CmdlineEnter]. The following values of [v:event] are set: old_mode The mode before it changed. new_mode The new mode as also returned by [mode()] called with a non-zero argument. When ModeChanged is triggered, old_mode will have the value of new_mode when the event was last triggered. This will be triggered on every minor mode change. Usage example to use relative line numbers when entering visual mode:

:au ModeChanged \[vV\\x16\]\*:\* let &l:rnu = mode() =~# '^\[vV\\x16\]'
:au ModeChanged \*:\[vV\\x16\]\* let &l:rnu = mode() =~# '^\[vV\\x16\]'
:au WinEnter,WinLeave \* let &l:rnu = mode() =~# '^\[vV\\x16\]'

[OptionSet]  
OptionSet After setting an option . The [autocmd-pattern] is matched against the long option name. [<amatch>] indicates what option has been set.

[v:option\_type] indicates whether it's global or local scoped. [v:option\_command] indicates what type of set/let command was used (follow the tag to see the table). [v:option\_new] indicates the newly set value. [v:option\_oldlocal] has the old local value. [v:option_oldglobal](https://neovim.io/doc/user/vvars.html#v%3Aoption_oldglobal) has the old global value. [v:option_old](https://neovim.io/doc/user/vvars.html#v%3Aoption_old) indicates the old option value.

[v:option\_oldlocal] is only set when [:set] or [:setlocal] or a [modeline] was used to set the option. Similarly [v:option_oldglobal](https://neovim.io/doc/user/vvars.html#v%3Aoption_oldglobal) is only set when [:set](https://neovim.io/doc/user/options.html#%3Aset) or [:setglobal](https://neovim.io/doc/user/options.html#%3Asetglobal) was used.

This does not set [<abuf>], you could use [bufnr()].

Note that when setting a [global-local] option with [:set], then [v:option\_old] is the old global value. However, for all options that are not global-local it is the old local value.

Usage example: Check for the existence of the directory in the ['backupdir'] and ['undodir'] options, create the directory if it doesn't exist yet.

**Note:** Do not reset the same option during this autocommand, that may break plugins. You can always use [:noautocmd] to prevent triggering OptionSet.

Non-recursive: [:set] in the autocommand does not trigger OptionSet again.

Not triggered on startup.

[QuickFixCmdPre]  
QuickFixCmdPre Before a quickfix command is run . The pattern is matched against the command being run. When [:grep] is used but ['grepprg'] is set to "internal" it still matches "grep". This command cannot be used to set the ['makeprg'] and ['grepprg'](https://neovim.io/doc/user/options.html#'grepprg') variables. If this command causes an error, the quickfix command is not executed. [QuickFixCmdPost](https://neovim.io/doc/user/autocmd.html#QuickFixCmdPost)  
QuickFixCmdPost Like QuickFixCmdPre, but after a quickfix command is run, before jumping to the first location. For [:cfile] and [:lfile] commands it is run after the error file is read and before moving to the first error. See [QuickFixCmdPost-example]. [QuitPre]  
QuitPre When using `:quit`, `:wq` or `:qall`, before deciding whether it closes the current window or quits Vim. For `:wq` the buffer is written before QuitPre is triggered. Can be used to close any non-essential window if the current window is the last ordinary window. See also [ExitPre], [WinClosed]. [RemoteReply]  
RemoteReply When a reply from a Vim that functions as server was received server2client(). The pattern is matched against the `{serverid}`. `<amatch>` is equal to the `{serverid}` from which the reply was sent, and `<afile>` is the actual reply string. Note that even if an autocommand is defined, the reply should be read with remote_read() to consume it. [SearchWrapped]  
SearchWrapped After making a search with [n] or [N] if the search wraps around the document back to the start/finish respectively. [RecordingEnter]  
RecordingEnter When a macro starts recording. The pattern is the current file name, and [reg\_recording()] is the current register that is used. [RecordingLeave]  
RecordingLeave When a macro stops recording. The pattern is the current file name, and [reg\_recording()] is the recorded register. [reg\_recorded()] is only updated after this event. Sets these [v:event] keys: regcontents regname [SafeState]  
SafeState When nothing is pending, going to wait for the user to type a character. This will not be triggered when:

an operator is pending

a register was entered with "r

halfway executing a command

executing a mapping

there is typeahead

Insert mode completion is active

Command line completion is active You can use `mode()` to find out what state Vim is in. That may be:

Visual mode

Normal mode

Insert mode

Command-line mode Depending on what you want to do, you may also check more with `state()`, e.g. whether the screen was scrolled for messages.

[SessionLoadPost]  
SessionLoadPost After loading the session file created using the [:mksession] command. [SessionWritePost]  
SessionWritePost After writing a session file by calling the [:mksession] command. [ShellCmdPost]  
ShellCmdPost After executing a shell command with [:!cmd], [:make] and [:grep]. Can be used to check for any changed files. For non-blocking shell commands, see [job-control]. [Signal](https://neovim.io/doc/user/autocmd.html#Signal)  
Signal After Nvim receives a signal. The pattern is matched against the signal name. Only "SIGUSR1" and "SIGWINCH" are supported. This is triggered even when inside an autocommand defined without [autocmd-nested]. Example:

    autocmd Signal SIGUSR1 call some#func()

[ShellFilterPost]  
ShellFilterPost After executing a shell command with ":{range}!cmd", ":w !cmd" or ":r !cmd". Can be used to check for any changed files. [SourcePre]  
SourcePre Before sourcing a Vimscript/Lua file. [:source] `<afile>` is the name of the file being sourced. [SourcePost]  
SourcePost After sourcing a Vimscript/Lua file. [:source] `<afile>` is the name of the file being sourced. Not triggered when sourcing was interrupted. Also triggered after a SourceCmd autocommand was triggered. [SourceCmd]  
SourceCmd When sourcing a Vimscript/Lua file. [:source] `<afile>` is the name of the file being sourced. The autocommand must source that file. [Cmd-event] [SpellFileMissing]  
SpellFileMissing When trying to load a spell checking file and it can't be found. The pattern is matched against the language. `<amatch>` is the language, ['encoding'] also matters. See [spell-SpellFileMissing]. [StdinReadPost]  
StdinReadPost During startup, after reading from stdin into the buffer, before executing modelines. [\--] [StdinReadPre]  
StdinReadPre During startup, before reading from stdin into the buffer. [\--] [SwapExists]  
SwapExists Detected an existing swap file when starting to edit a file. Only when it is possible to select a way to handle the situation, when Vim would ask the user what to do. The [v:swapname] variable holds the name of the swap file found, `<afile>` the file being edited. [v:swapcommand] may contain a command to be executed in the opened file. The commands should set the [v:swapchoice] variable to a string with one character to tell Vim what should be done next: 'o' open read-only 'e' edit the file anyway 'r' recover 'd' delete the swap file 'q' quit, don't edit the file 'a' abort, like hitting `CTRL-C` When set to an empty string the user will be asked, as if there was no SwapExists autocmd. [E812]  
Cannot change to another buffer, change the buffer name or change directory. [Syntax]  
Syntax When the ['syntax'] option has been set. The pattern is matched against the syntax name. `<afile>` expands to the name of the file where this option was set. `<amatch>` expands to the new value of ['syntax']. See [:syn-on]. [TabEnter]  
TabEnter Just after entering a tab page. [tab-page] After WinEnter. Before BufEnter. [TabLeave]  
TabLeave Just before leaving a tab page. [tab-page] After WinLeave. [TabNew]  
TabNew When creating a new tab page. [tab-page] After WinEnter. Before TabEnter. [TabNewEntered]  
TabNewEntered After entering a new tab page. [tab-page] After BufEnter. [TabClosed]  
TabClosed After closing a tab page. `<afile>` expands to the tab page number. [TermOpen]  
TermOpen When a [terminal] job is starting. Can be used to configure the terminal buffer. [TermEnter]  
TermEnter After entering [Terminal-mode]. After TermOpen. [TermLeave]  
TermLeave After leaving [Terminal-mode]. After TermClose. [TermClose]  
TermClose When a [terminal] job ends. Sets these [v:event] keys: status [TermRequest]  
TermRequest When a [:terminal] child process emits an OSC, DCS, or APC sequence. Sets [v:termrequest]. The [event-data] is a table with the following fields:

sequence: the received sequence

cursor: (1,0)-indexed, buffer-relative position of the cursor when the sequence was received

This is triggered even when inside an autocommand defined without [autocmd-nested].

[TermResponse]  
TermResponse When Nvim receives an OSC or DCS response from the host terminal. Sets [v:termresponse]. The [event-data] is a table with the following fields:

sequence: the received sequence

This is triggered even when inside an autocommand defined without [autocmd-nested].

May be triggered during another event (file I/O, a shell command, or anything else that takes time).

Example:

    -- Query the terminal palette for the RGB value of color 1
    -- (red) using OSC 4
    vim.api.nvim_create_autocmd('TermResponse', {
      once = true,
      callback = function(args)
        local resp = args.data.sequence
        local r, g, b = resp:match("\027%]4;1;rgb:(%w+)/(%w+)/(%w+)")
      end,
    })
    io.stdout:write("\027]4;1;?\027\\")

[TextChanged]  
TextChanged After a change was made to the text in the current buffer in Normal mode. That is after [b:changedtick] has changed (also when that happened before the TextChanged autocommand was defined). Not triggered when there is typeahead or when an operator is pending. **Note:** Cannot be skipped with `:noautocmd`. Careful: This is triggered very often, don't do anything that the user does not expect or that is slow. [TextChangedI]  
TextChangedI After a change was made to the text in the current buffer in Insert mode. Not triggered when the popup menu is visible. Otherwise the same as TextChanged. [TextChangedP]  
TextChangedP After a change was made to the text in the current buffer in Insert mode, only when the popup menu is visible. Otherwise the same as TextChanged. [TextChangedT]  
TextChangedT After a change was made to the text in the current buffer in [Terminal-mode]. Otherwise the same as TextChanged. [TextYankPost]  
TextYankPost Just after a [yank] or [deleting] command, but not if the black hole register [quote\_] is used nor for [setreg()]. Pattern must be "\*". Sets these [v:event](https://neovim.io/doc/user/vvars.html#v%3Aevent) keys: inclusive operator regcontents regname regtype visual The `inclusive` flag combined with the ['\[](https://neovim.io/doc/user/motion.html#'%5B) and ['\]](https://neovim.io/doc/user/motion.html#'%5D) marks can be used to calculate the precise region of the operation.

Non-recursive (event cannot trigger itself). Cannot change the text. [textlock] [User]  
User Not executed automatically. Use [:doautocmd] to trigger this, typically for "custom events" in a plugin. Example:

:autocmd User MyPlugin echom 'got MyPlugin event'
:doautocmd User MyPlugin

[UserGettingBored]  
UserGettingBored When the user presses the same key 42 times. Just kidding! :-) [VimEnter]  
VimEnter After doing all the startup stuff, including loading vimrc files, executing the "-c cmd" arguments, creating all windows and loading the buffers in them. Just before this event is triggered the [v:vim\_did\_enter] variable is set, so that you can do:

if v:vim_did_enter
call s:init()
else
au VimEnter \* call s:init()
endif

[VimLeave]  
VimLeave Before exiting Vim, just after writing the .shada file. Executed only once, like VimLeavePre. Use [v:dying] to detect an abnormal exit. Use [v:exiting] to get the exit code. Not triggered if [v:dying] is 2 or more. [VimLeavePre]  
VimLeavePre Before exiting Vim, just before writing the [shada] file. Executed only once, if the pattern matches the current buffer on exit. Mostly useful with a "\*" pattern.

:autocmd VimLeavePre \* call CleanupStuff()

Use [v:dying] to detect an abnormal exit. Use [v:exiting] to get the exit code. Not triggered if [v:dying] is 2 or more. [VimResized]  
VimResized After the Vim window was resized, thus ['lines'] and/or ['columns'] changed. Not when starting up though. [VimResume]  
VimResume After Nvim resumes from [suspend] state. [VimSuspend]  
VimSuspend Before Nvim enters [suspend] state. [WinClosed]  
WinClosed When closing a window, just before it is removed from the window layout. The pattern is matched against the [window-ID]. Both `<amatch>` and `<afile>` are set to the [window-ID]. After WinLeave. Non-recursive (event cannot trigger itself). See also [ExitPre], [QuitPre]. [WinEnter](https://neovim.io/doc/user/autocmd.html#WinEnter)  
WinEnter After entering another window. Not done for the first window, when Vim has just started. Useful for setting the window height. If the window is for another buffer, Vim executes the BufEnter autocommands after the WinEnter autocommands. **Note:** For split and tabpage commands the WinEnter event is triggered after the split or tab command but before the file is loaded.

[WinLeave]  
WinLeave Before leaving a window. If the window to be entered next is for a different buffer, Vim executes the BufLeave autocommands before the WinLeave autocommands (but not for ":new"). Not used for ":qa" or ":q" when exiting Vim. Before WinClosed. [WinNew]  
WinNew When a new window was created. Not done for the first window, when Vim has just started. Before WinEnter.

[WinScrolled]  
WinScrolled After any window in the current tab page scrolled the text (horizontally or vertically) or changed width or height. See [win-scrolled-resized].

**Note:** This can not be skipped with `:noautocmd`, because it triggers after processing normal commands when Vim is back in the main loop. If you want to disable this, consider setting the ['eventignore'] option instead.

The pattern is matched against the [window-ID] of the first window that scrolled or resized. Both `<amatch>` and `<afile>` are set to the [window-ID].

[v:event] is set with information about size and scroll changes. [WinScrolled-event]

Only starts triggering after startup finished and the first screen redraw was done. Does not trigger when defining the first WinScrolled or WinResized event, but may trigger when adding more.

Non-recursive: the event will not trigger while executing commands for the WinScrolled event. However, if the command causes a window to scroll or change size, then another WinScrolled event will be triggered later.

[WinResized]  
WinResized After a window in the current tab page changed width or height. See [win-scrolled-resized].

[v:event] is set with information about size changes. [WinResized-event]

Same behavior as [WinScrolled] for the pattern, triggering and recursiveness.

## 6\. Patterns [autocmd-pattern] [{aupat}]

The `{aupat}` argument of `:autocmd` can be a comma-separated list. This works as if the command was given with each pattern separately. Thus this command:

:autocmd BufRead \*.txt,\*.info set et

Is equivalent to:

:autocmd BufRead \*.txt set et
:autocmd BufRead \*.info set et

The file pattern `{aupat}` is tested for a match against the file name in one of two ways: 1. When there is no '/' in the pattern, Vim checks for a match against only the tail part of the file name (without its leading directory path). 2. When there is a '/' in the pattern, Vim checks for a match against both the short file name (as you typed it) and the full file name (after expanding it to a full path and resolving symbolic links).

The special pattern `<buffer>` or <buffer=N> is used for buffer-local autocommands [autocmd-buflocal]. This pattern is not matched against the name of a buffer.

Examples:

:autocmd BufRead \*.txt set et

Set the ['et'] option for all text files.

:autocmd BufRead /vim/src/\*.c set cindent

Set the ['cindent'] option for C files in the /vim/src directory.

:autocmd BufRead /tmp/\*.c set ts=5

If you have a link from "/tmp/test.c" to "/home/nobody/vim/src/test.c", and you start editing "/tmp/test.c", this autocommand will match.

**Note:** To match part of a path, but not from the root directory, use a "\*" as the first character. Example:

:autocmd BufRead \*/doc/\*.txt set tw=78

This autocommand will for example be executed for "/tmp/doc/xx.txt" and "/usr/home/piet/doc/yy.txt". The number of directories does not matter here.

The file name that the pattern is matched against is after expanding wildcards. Thus if you issue this command:

:e $ROOTDIR/main.$EXT

The argument is first expanded to:

/usr/root/main.py

Before it's matched with the pattern of the autocommand. Careful with this when using events like FileReadCmd, the value of `<amatch>` may not be what you expect.

Environment variables can be used in a pattern:

:autocmd BufRead $VIMRUNTIME/doc/\*.txt set expandtab

And ~ can be used for the home directory (if $HOME is defined):

:autocmd BufWritePost ~/.config/nvim/init.vim so <afile>
:autocmd BufRead ~archive/\* set readonly

The environment variable is expanded when the autocommand is defined, not when the autocommand is executed. This is different from the command!

[file-pattern]  
The pattern is interpreted like mostly used in file names: \* matches any sequence of characters; Unusual: includes path separators ? matches any single character \\? matches a '?' . matches a '.' ~ matches a '~' , separates patterns \\, matches a ',' { } like \\( \\) in a [pattern] , inside { }: like \\| in a [pattern] \\} literal } \\{ literal { \\\\\\{n,m\\} like \\{n,m} in a [pattern] \\ special meaning like in a [pattern] \[ch\] matches 'c' or 'h' \[^ch\] match any character but 'c' and 'h'

Note that for all systems the '/' character is used for path separator (even Windows). This was done because the backslash is difficult to use in a pattern and to make the autocommands portable across different systems.

It is possible to use [pattern] items, but they may not work as expected, because of the translation done for the above.

[autocmd-changes]  
Matching with the pattern is done when an event is triggered. Changing the buffer name in one of the autocommands, or even deleting the buffer, does not change which autocommands will be executed. Example:

au BufEnter \*.foo bdel
au BufEnter \*.foo set modified

This will delete the current buffer and then set ['modified'] in what has become the current buffer instead. Vim doesn't take into account that "\*.foo" doesn't match with that buffer name. It matches "\*.foo" with the name of the buffer at the moment the event was triggered.

However, buffer-local autocommands will not be executed for a buffer that has been wiped out with [:bwipe]. After deleting the buffer with [:bdel] the buffer actually still exists (it becomes unlisted), thus the autocommands are still executed.

## 7\. Buffer-local autocommands [autocmd-buflocal] [autocmd-buffer-local]

[<buffer>] [<buffer=N>] [<buffer=abuf>] [E680]

Buffer-local autocommands are attached to a specific buffer. They are useful if the buffer does not have a name and when the name does not match a specific pattern. But it also means they must be explicitly added to each buffer.

Instead of a pattern buffer-local autocommands use one of these forms: `<buffer>` current buffer <buffer=99> buffer number 99 <buffer=abuf> using `<abuf>` (only when executing autocommands) [<abuf>]

Examples:

:au CursorHold <buffer> echo 'hold'
:au CursorHold <buffer=33> echo 'hold'
:au BufNewFile \* au CursorHold <buffer=abuf> echo 'hold'

All the commands for autocommands also work with buffer-local autocommands, simply use the special string instead of the pattern. Examples:

:au! \* <buffer> " remove buffer-local autocommands for
" current buffer
:au! \* <buffer=33> " remove buffer-local autocommands for
" buffer #33
:bufdo :au! CursorHold <buffer> " remove autocmd for given event for all
" buffers
:au \* <buffer> " list buffer-local autocommands for
" current buffer

Note that when an autocommand is defined for the current buffer, it is stored with the buffer number. Thus it uses the form "<buffer=12>", where 12 is the number of the current buffer. You will see this when listing autocommands, for example.

To test for presence of buffer-local autocommands use the [exists()] function as follows:

:if exists("#CursorHold#<buffer=12>") | ... | endif
:if exists("#CursorHold#<buffer>") | ... | endif " for current buffer

When a buffer is wiped out its buffer-local autocommands are also gone, of course. Note that when deleting a buffer, e.g., with ":bdel", it is only unlisted, the autocommands are still present. In order to see the removal of buffer-local autocommands:

:set verbose=6

It is not possible to define buffer-local autocommands for a non-existent buffer.

## 8\. Groups [autocmd-groups]

Autocommands can be put together in a group. This is useful for removing or executing a group of autocommands. For example, all the autocommands for syntax highlighting are put in the "highlight" group, to be able to execute ":doautoall highlight BufRead" when the GUI starts.

When no specific group is selected, Vim uses the default group. The default group does not have a name. You cannot execute the autocommands from the default group separately; you can execute them only by executing autocommands for all groups.

Normally, when executing autocommands automatically, Vim uses the autocommands for all groups. The group only matters when executing autocommands with ":doautocmd" or ":doautoall", or when defining or deleting autocommands.

The group name can contain any characters except white space. The group name "end" is reserved (also in uppercase).

The group name is case sensitive. Note that this is different from the event name!

[:aug] [:augroup] :aug\[roup\] `{name}` Define the autocmd group name for the following ":autocmd" commands. The name "end" or "END" selects the default group. To avoid confusion, the name should be different from existing `{event}` names, as this most likely will not do what you intended.

[:augroup-delete] [E367] [W19] [E936] :aug\[roup\]! `{name}` Delete the autocmd group `{name}`. Don't use this if there is still an autocommand using this group! You will get a warning if doing it anyway. When the group is the current group you will get error E936.

To enter autocommands for a specific group, use this method: 1. Select the group with ":augroup `{name}`". 2. Delete any old autocommands with ":au!". 3. Define the autocommands. 4. Go back to the default group with "augroup END".

Example:

:augroup uncompress
: au!
: au BufEnter \*.gz %!gunzip
:augroup END

This prevents having the autocommands defined twice (e.g., after sourcing the vimrc file again).

[FileExplorer]  
There is one group that is recognized by Vim: FileExplorer. If this group exists Vim assumes that editing a directory is possible and will trigger a plugin that lists the files in that directory. This is used by directory browser plugins. This allows you to do:

browse edit

## 9\. Executing autocommands [autocmd-execute]

Vim can also execute Autocommands non-automatically. This is useful if you have changed autocommands, or when Vim has executed the wrong autocommands (e.g., the file pattern match was wrong).

Note that the ['eventignore'] option applies here too. Events listed in this option will not cause any commands to be executed.

[:do] [:doau] [:doaut] [:doautocmd] [E217](https://neovim.io/doc/user/autocmd.html#E217) :do\[autocmd\] \[`<nomodeline>`\] \[group\] `{event}` \[fname\] Apply the autocommands matching \[fname\] (default: current file name) for `{event}` to the current buffer. You can use this when the current file name does not match the right pattern, after changing settings, or to execute autocommands for a certain event. It's possible to use this inside an autocommand too, so you can base the autocommands for one extension on another extension. Example:

:au BufEnter \*.cpp so ~/.config/nvim/init_cpp.vim
:au BufEnter \*.cpp doau BufEnter x.c

Be careful to avoid endless loops. [autocmd-nested]

When the \[group\] argument is not given, Vim executes the autocommands for all groups. When the \[group\] argument is included, Vim executes only the matching autocommands for that group. Undefined group is an error. [<nomodeline>]  
After applying the autocommands the modelines are processed, so that their settings overrule the settings from autocommands when editing a file. This is skipped if `<nomodeline>` is specified. You probably want to use `<nomodeline>` for events not used when loading a buffer, such as [User]. Modelines are also skipped when no matching autocommands were executed.

[:doautoa] [:doautoall] :doautoa\[ll\] \[`<nomodeline>`\] \[group\] `{event}` \[fname\] Like ":doautocmd", but apply the autocommands to each loaded buffer. The current buffer is done last.

Note that \[fname\] is used to select the autocommands, not the buffers to which they are applied. Example:

augroup mine
autocmd!
autocmd FileType \* echo expand('<amatch>')
augroup END
doautoall mine FileType Loaded-Buffer

Sourcing this script, you'll see as many "Loaded-Buffer" echoed as there are loaded buffers.

Careful: Don't use this for autocommands that delete a buffer, change to another buffer or change the contents of a buffer; the result is unpredictable. This command is intended for autocommands that set options, change highlighting, and things like that.

## 10\. Using autocommands [autocmd-use]

For WRITING FILES there are four possible sets of events. Vim uses only one of these sets for a write command:

BufWriteCmd BufWritePre BufWritePost writing the whole buffer FilterWritePre FilterWritePost writing to filter temp file FileAppendCmd FileAppendPre FileAppendPost appending to a file FileWriteCmd FileWritePre FileWritePost any other file write

When there is a matching "\*Cmd" autocommand, it is assumed it will do the writing. No further writing is done and the other events are not triggered. [Cmd-event]

Note that the "\*WritePost" commands should undo any changes to the buffer that were caused by the "\*WritePre" commands; otherwise, writing the file will have the side effect of changing the buffer.

Before executing the autocommands, the buffer from which the lines are to be written temporarily becomes the current buffer. Unless the autocommands change the current buffer or delete the previously current buffer, the previously current buffer is made the current buffer again.

The "\*WritePre" and "\*AppendPre" autocommands must not delete the buffer from which the lines are to be written.

The '\[ and '\] marks have a special position:

Before the "\*ReadPre" event the '\[ mark is set to the line just above where the new lines will be inserted.

Before the "\*ReadPost" event the '\[ mark is set to the first line that was just read, the '\] mark to the last line.

Before executing the "\*WriteCmd", "\*WritePre" and "\*AppendPre" autocommands the '\[ mark is set to the first line that will be written, the '\] mark to the last line. Careful: '\[ and '\] change when using commands that change the buffer.

In commands which expect a file name, you can use "<afile>" for the file name that is being read [:<afile>] (you can also use "%" for the current file name). "<abuf>" can be used for the buffer number of the currently effective buffer. This also works for buffers that don't have a name. But it doesn't work for files without a buffer (e.g., with ":r file").

[gzip-example]  
Examples for reading and writing compressed files:

:augroup gzip
: autocmd!
: autocmd BufReadPre,FileReadPre \*.gz set bin
: autocmd BufReadPost,FileReadPost \*.gz '\[,'\]!gunzip
: autocmd BufReadPost,FileReadPost \*.gz set nobin
: autocmd BufReadPost,FileReadPost \*.gz execute ":doautocmd BufReadPost " .. expand("%:r")
: autocmd BufWritePost,FileWritePost \*.gz !mv <afile> <afile>:r
: autocmd BufWritePost,FileWritePost \*.gz !gzip <afile>:r
: autocmd FileAppendPre \*.gz !gunzip <afile>
: autocmd FileAppendPre \*.gz !mv <afile>:r <afile>
: autocmd FileAppendPost \*.gz !mv <afile> <afile>:r
: autocmd FileAppendPost \*.gz !gzip <afile>:r
:augroup END

The "gzip" group is used to be able to delete any existing autocommands with ":autocmd!", for when the file is sourced twice.

The commands executed for the BufNewFile, BufRead/BufReadPost, BufWritePost, FileAppendPost and VimLeave events do not set or reset the changed flag of the buffer. When you decompress the buffer with the BufReadPost autocommands, you can still exit with ":q". When you use ":undo" in BufWritePost to undo the changes made by BufWritePre commands, you can still do ":q" (this also makes "ZZ" work). If you do want the buffer to be marked as modified, set the ['modified'] option.

To execute Normal mode commands from an autocommand, use the ":normal" command. Use with care! If the Normal mode command is not finished, the user needs to type characters (e.g., after ":normal m" you need to type a mark name).

If you want the buffer to be unmodified after changing it, reset the ['modified'] option. This makes it possible to exit the buffer with ":q" instead of ":q!".

[autocmd-nested] [E218] By default, autocommands do not nest. For example, if you use ":e" or ":w" in an autocommand, Vim does not execute the BufRead and BufWrite autocommands for those commands. If you do want this, use the "++nested" flag for those commands in which you want nesting. For example:

:autocmd FileChangedShell \*.c ++nested e!

The nesting is limited to 10 levels to get out of recursive loops.

It's possible to use the ":au" command in an autocommand. This can be a self-modifying command! This can be useful for an autocommand that should execute only once.

If you want to skip autocommands for one command, use the [:noautocmd] command modifier or the ['eventignore'] option.

**Note:** When reading a file (with ":read file" or with a filter command) and the last line in the file does not have an `<EOL>`, Vim remembers this. At the next write (with ":write file" or with a filter command), if the same line is written again as the last line in a file AND ['binary'] is set, Vim does not supply an `<EOL>`. This makes a filter command on the just read lines write the same file as was read, and makes a write command on just filtered lines write the same file as was read from the filter. For example, another way to write a compressed file:

:autocmd FileWritePre \*.gz set bin|'\[,'\]!gzip
:autocmd FileWritePost \*.gz undo|set nobin

[autocommand-pattern]  
You can specify multiple patterns, separated by commas. Here are some examples:

:autocmd BufRead \* set tw=79 nocin ic infercase fo=2croq
:autocmd BufRead .letter set tw=72 fo=2tcrq
:autocmd BufEnter .letter set dict=/usr/lib/dict/words
:autocmd BufLeave .letter set dict=
:autocmd BufRead,BufNewFile \*.c,\*.h set tw=0 cin noic
:autocmd BufEnter \*.c,\*.h abbr FOR for (i = 0; i < 3; ++i)<CR>{<CR>}<Esc>O
:autocmd BufLeave \*.c,\*.h unabbr FOR

For makefiles (makefile, Makefile, imakefile, makefile.unix, etc.):

:autocmd BufEnter ?akefile\* set include=^s\\=include
:autocmd BufLeave ?akefile\* set include&

To always start editing C files at the first function:

:autocmd BufRead \*.c,\*.h 1;/^{

Without the "1;" above, the search would start from wherever the file was entered, rather than from the start of the file.

[skeleton] [template] To read a skeleton (template) file when opening a new file:

:autocmd BufNewFile \*.c 0r ~/vim/skeleton.c
:autocmd BufNewFile \*.h 0r ~/vim/skeleton.h
:autocmd BufNewFile \*.java 0r ~/vim/skeleton.java

To insert the current date and time in a "\*.html" file when writing it:

:autocmd BufWritePre,FileWritePre \*.html ks|call LastMod()|'s
:fun LastMod()
: if line("$") > 20
:    let l = 20
:  else
:    let l = line("$")
: endif
: exe "1," .. l .. "g/Last modified: /s/Last modified: .\*/Last modified: " ..
: \\ strftime("%Y %b %d")
:endfun

You need to have a line "Last modified: <date time>" in the first 20 lines of the file for this to work. Vim replaces <date time> (and anything in the same line after it) with the current date and time. Explanation: ks mark current position with mark 's' call LastMod() call the LastMod() function to do the work 's return the cursor to the old position The LastMod() function checks if the file is shorter than 20 lines, and then uses the ":g" command to find lines that contain "Last modified: ". For those lines the ":s" command is executed to replace the existing date with the current one. The ":execute" command is used to be able to use an expression for the ":g" and ":s" commands. The date is obtained with the strftime() function. You can change its argument to get another date string.

When entering :autocmd on the command-line, completion of events and command names may be done (with `<Tab>`, `CTRL-D`, etc.) where appropriate.

Vim executes all matching autocommands in the order that you specify them. It is recommended that your first autocommand be used for all files by using "\*" as the file pattern. This means that you can define defaults you like here for any settings, and if there is another matching autocommand it will override these. But if there is no other matching autocommand, then at least your default settings are recovered (if entering this file from another for which autocommands did match). Note that "\*" will also match files starting with ".", unlike Unix shells.

[autocmd-searchpat]  
Autocommands do not change the current search patterns. Vim saves the current search patterns before executing autocommands then restores them after the autocommands finish. This means that autocommands do not affect the strings highlighted with the ['hlsearch'] option. Within autocommands, you can still use search patterns normally, e.g., with the "n" command. If you want an autocommand to set the search pattern, such that it is used after the autocommand finishes, use the ":let @/ =" command. The search-highlighting cannot be switched off with ":nohlsearch" in an autocommand. Use the 'h' flag in the ['shada'] option to disable search- highlighting when starting Vim.

[Cmd-event]  
When using one of the "\*Cmd" events, the matching autocommands are expected to do the file reading, writing or sourcing. This can be used when working with a special kind of file, for example on a remote system. CAREFUL: If you use these events in a wrong way, it may have the effect of making it impossible to read or write the matching files! Make sure you test your autocommands properly. Best is to use a pattern that will never match a normal file name, for example "ftp://\*".

When defining a BufReadCmd it will be difficult for Vim to recover a crashed editing session. When recovering from the original file, Vim reads only those parts of a file that are not found in the swap file. Since that is not possible with a BufReadCmd, use the [:preserve] command to make sure the original file isn't needed for recovery. You might want to do this only when you expect the file to be modified.

For file read and write commands the [v:cmdarg] variable holds the "++enc=" and "++ff=" argument that are effective. These should be used for the command that reads/writes the file. The [v:cmdbang] variable is one when "!" was used, zero otherwise.

See the $VIMRUNTIME/pack/dist/opt/netrw/plugin/netrwPlugin.vim for examples.

## 11\. Disabling autocommands [autocmd-disable]

To disable autocommands for some time use the ['eventignore'] option. Note that this may cause unexpected behavior, make sure you restore ['eventignore'] afterwards, using a [:try] block with [:finally].

To disable autocmds indefinitely in a specific window use the ['eventignorewin'] option. This can only be used to ignore window and buffer related events.

[:noautocmd] [:noa] To disable autocommands for just one command use the ":noautocmd" command modifier. This will set ['eventignore'] to "all" for the duration of the following command. Example:

:noautocmd w fname.gz

This will write the file without triggering the autocommands defined by the gzip plugin.

Note that some autocommands are not triggered right away, but only later. This specifically applies to [CursorMoved] and [TextChanged].
