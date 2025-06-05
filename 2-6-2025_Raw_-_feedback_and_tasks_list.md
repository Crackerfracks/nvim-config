# Updating the NumHi Highlighting and Note-taking Plugin (<-- CURRENT TASK)

## Feedback and Instructions

Okay so, here are the plusses ('+') and minuses ('-') at a glance.
I also included any interesting features I didn't notice that you implemented until now ('\*') as well as some adjustments that could be made to enhance the plugin experience in that area:

- You've added all of the plugin commands to the requested namespace
- Hitting `q` within the floating note buffer no longer causes the error message, and the content for notes seems to save (attempting to quit with just `:q` gives the standard error when trying to close an unsaved buffer), at least for the current session.
- There are now notifications being used instead of just the echoline
- There are no errors when loading a file containing highlights after a restart (IMPORTANT CAVEAT BELOW)
- Note content and tag content remains (saving notes doesn't error and 'saves' the notes, at least in memory)
- ...You've added some superficial wording for the NumHi Prompt (which doesn't actually reflect the functionality available).
  - Specifically, hitting <BS> to try and reset whatever I typed into the prompt thus far does not work, and instead just shows a blank notification (that I initually mistook for an empty prompt)... however the NumHi prompt for `highlight with slot` just seems to quit. It would be more accurate to call `<BS>` a 'cancel button' currently, which is not what I wanted (however such a button is needed, but the prompt should just be escapable with <ESC>).

* New notification on hovering cursor on is missing previous features: it doesn't persist for the duration of the cursor hovering, does not display icon signifying existence of linked note content (\*CAVEAT BELOW), does not color the preview of the highlight colorcode accordingly and does not display tags.

  - It DOES display the pencil icon (signifying the existence of a note) but only after toggling the virtual text display for tags. As a side note, the first attempt to display virtual text using `<leader><leader>nnt` fails, and only the pencil icon becomes visible. I'm forced to toggle it a second time to get the text to properly show up.

* (CAVEAT FOR ERROR ON FILE LOAD) Restarting Neovim and reloading a file that has recieved highlights only restores the highlights and a temporary 'ghost' of the tags that do not reappear once disabled for the highlight, while the note content and actual hashtags that were previously typed and saved still seem to be getting completely wiped. Perhaps the json serialzation process (assuming this is either implemented or in the works) should be examined to ensure it is A) in place, B) working as intended and C) robust enough to accept additional expansion of permissible note content and the additional tagging features that you will be adding shortly (or, ideally, immediately).

  - Perhaps Sqlite would be the best/most stable option here...? I'm really not sure, I haven't worked much with it, although I'm sure I could whip up a compressed chunk of relevant usage context for you to reference like I did with the Neovim lua and API reference docs from the official website. You've been working well with those, and I expect this will continiue.

* I ALSO noticed that, when saving a file containing NumHi highlights during a session one time, the highlights were wiped whenever saving, but I couldn't tell whether it was the formatter or something else.
  HOWEVER... I managed to restore the session where the highlights were applied, and for some reason, after doing so, they seemed more stable against save operations.
  I was really confused, but I think I may have noticed something.
  As mentioned earlier, the pencil icon isn't visible by default in the left-hand 'gutter' or tray or whatever they call the thing where the `W`, `H` and `E` symbols as well as the `+`, `-` and `~` symbols for diffs (I think?).
  However, it WAS visible on reloading the session as mentioned, though I hadn't yet toggled it on, which coupled with the highlights sudden resilience against being wiped makes me wonder if there is a connection that can be examined to fix this issue.
  (Edit: I don't think the icon or status of the virtual text toggle had anything to do with it... it was the auto-formatting being done by the LSP on save.
  The highlights are completely dependant on the text remaining the same, with any changes made on save completely destroying all highlights that were after the point where the change happened.
  This happens even with as minor of a change as removing a single trailing space from the end of a line).

  - The highlights themselves are technically 'more robust' because they persist across file reloads and nvim restarts, but ultimately extremely fragile.
    They need to be truly robust, whether that means compensating on the highlight data storage/serialization side for any changes performed by the LSP or some other even better method.
    Currently highlights can persist through manual edits to text above them, no matter what those changes are (including adding/deleting lines/spaces and even deleting characters from the beginning/middle/end of the highlight itself) which clearly indicates that such robustness is **possible**.
    This fragility is one of the last remaining major issues.

* I had a neovim crash one time recently while I was away from the computer, and I'm not sure if it had anything to do with NumHi or not, but hopefully there are no stability issues.
  Have a look over things and make sure no obvious instabilities pop out.

- The colors used for displaying tags as virtual text area should match the color of the highlight to which they are attached.
  This is crucial for when multiple highlights with tags are added to the same line.
  Tags should also be shown as a notification (ON HOVER ONLY) in case the virtual text is not visible or difficult to read due to surrounding formatting or line length -- seeing them is VITAL.

  - In fact, it might even be worth it to add a virtual line denoted by some icon in the left tray for warnings, errors, etc.
    for every line containing highlights.
    This would necessitate a second display method that the `<leader><leader>nnt` toggle would handle So after fixing the issue, from a fresh boot, we would start without tags enabled and with the .

- Just noticed the pencil icon (signifying a note) in the tray to the very left where warnings and errors are displayed. NICE FEATURE!!! I wonder if the tag's virtual text (and the pencil icon in the notification window) can be adjusted to display A) a pencil icon per note (in the case of three or fewer notes on a single line), or a a '+<X>' (in the case of more than three notes on a single line) to indicate multiple highlights on a single line in the event that multiple sentences in a paragraph or multiple elements in a block of code need to be classified, and thus highlighted, separately, B) the color of the highlight (in the case of additional highlights), and C) the colorcode definition (the category I assign it on first use in a session) for each additional such pencil icon.
  It would also be good to have a way of differentiating between a note that content (has been filled out) and one that is empty (was created and exited without actually filling out) to know, at a glance, which highlights might need to be annotated.

---

# >>>!!!CURRENT TASK FOR YOU, OPENAI'S o3 MODEL/CHATGPT/WHICHEVER MODEL IS ROUTED TO DEAL WITH THIS CORPUS OF INFORMATION AND IS CURRENTLY PROCESSING THIS TRIPLE-ANGLE-BRACKET-DELIMITED STRING!!!<<<

- Your responses should consist of COMPLETE file replacements for whatever files need complete rewrites (which hopefully shouldn't be many) or comprehensive sets of code snippets (comprehensive as in: **don't just tell** me what to change and where, and **don't just describe** what needs to be done, **_provide drop-in code block replacements that can be rapidly integrated via straightforward copy/paste operations with CLEARLY DEFINED INSERTION POINTS IN EVERY SINGLE CASE, WITHOUT EXCEPTION FOR ANY REASON_**)
  Also, clearly indicate what you plan to change (honestly) and what you **DID** change (honestly fr fr ong), and do your BEST to KNOCK THIS OUT OF THE PARK!!! I'm --SO-- excited to use this plugin to replace my current highlighting workflow. I am ready to receive the updates.

Make sure to reference the project files liberally as you think your way through what needs to be done. They may not be complete, but given the way you (and models like you) work, you should be able to fill in the blanks with either Google Search or your own learned knowledge (try to use this only after consulting the project files and any relevant search results you happen to find.) You'll be responding with full code in copy/pastable, drop-in replacement code blocks named after the file that they fully replace (all blocks in your response must fully replace whatever file is being worked on)

!!!TAKE YOUR TIME!!!
Despite what you may remember, there are actually no limits on the amount of time you can think and plan before jumping into the problem solution (Your perception of this limit is an artifact of the previous limitation that you've not yet unlearned; AKA a hallucination).
!!!TAKE YOUR TIME!!!

!!!TAKE YOUR TIME!!!
This plugin is small, but a bit complex, and you have a LOT of context to look through... plus you'll be providing full files, therefore it is only natural that you would 'religiously' and meticulously architect the solution using this extended thinking time.
!!!TAKE YOUR TIME!!!

---

---

## Reimagined as a list of tasks

## Task 1: NumHi Prompt Improvements

- **Issue:**

  - Current NumHi Prompt functionality isn't clearly defined or intuitive.
  - `<BS>` key behaves like a 'cancel' button instead of clearing the input.
  - `<ESC>` should escape prompt.

- **Actions Required:**

  - Clearly differentiate actions:

    - `<BS>`: clears current input entirely without cancelling.
    - `<ESC>`: exits/cancels the prompt without submitting.

---

## Task 2: Notification & Cursor Hover Improvements

- **Issue:**

  - Notifications upon cursor hover are transient and incomplete.
  - Notifications currently don't persist as long as the cursor hovers.
  - Missing icon indication for existing linked notes (unless toggled explicitly).
  - Highlight color not displayed in notifications.
  - Tags not displayed in hover notifications.

- **Actions Required:**

  - Extend notification visibility to persist as long as the cursor remains hovered.
  - Show a pencil icon in hover notification consistently whenever a note is present.
  - Dynamically color notifications to match highlight color.
  - Include tags clearly within hover notifications.

---

## Task 3: Virtual Text Toggle Bug Fix

- **Issue:**

  - First invocation of `<leader><leader>nnt` fails to fully activate virtual text.
  - Requires second toggle for tags to show.

- **Actions Required:**

  - Investigate toggle initialization logic to ensure tags fully display upon first activation.

---

## Task 4: Highlight Data Persistence and Restoration

- **Issue:**

  - Tags appear temporarily as "ghosts" after Neovim restart.
  - Note content and hashtags wiped after restart/reload.

- **Actions Required:**

  - Review JSON serialization:

    - Confirm implementation completeness.
    - Test robustness against highlight/tag/note changes.
    - Ensure it accommodates future tag expansion.

  - Consider SQLite for stable, robust storage (evaluate viability).

---

## Task 5: LSP Formatting Conflict with Highlights

- **Issue:**

  - Saving a file with LSP auto-formatting removes or corrupts highlights placed below edits.
  - Highlights are stable against manual edits but fragile against auto-formatting actions.

- **Actions Required:**

  - Develop logic to make highlights resilient to minor LSP-induced text changes:

    - Implement highlight offset tracking.
    - Recompute highlight locations dynamically post-format.

  - Test thoroughly against minimal formatting changes (e.g., whitespace trimming).

---

## Task 6: Stability and Crash Check

- **Issue:**

  - Possible instability linked to Neovim crashes.

- **Actions Required:**

  - Conduct a thorough code review for memory leaks or event-loop instability.
  - Verify error-handling routines, especially with buffer/window closures.
  - Add robust error logging to isolate potential crash scenarios.

---

## Task 7: Tag and Highlight Color Matching

- **Issue:**

  - Tag virtual text color currently mismatches highlight color.

- **Actions Required:**

  - Adjust tag virtual text rendering to inherit or match the associated highlight color.
  - Test visual clarity when multiple highlights and tags exist on the same line.

---

## Task 8: Enhanced Tag Visibility and Virtual Line Indicators

- **Issue:**

  - Tags need visibility even if virtual text is hidden or difficult to read.
  - Consider secondary indication (icons or indicators) in the gutter.

- **Actions Required:**

  - Add a gutter indicator (e.g., virtual sign) marking lines containing highlights.
  - Develop toggleable alternate display modes (tags shown vs. tags hidden with icon indicators).
  - Clearly distinguish lines containing notes, highlights, or multiple annotations.

---

## Task 9: Pencil Icon and Multiple Notes Enhancement

- **Issue:**

  - Pencil icon in gutter or notification currently simplistic, lacking detail:

    - Multiple highlights on a line not well-indicated.
    - Empty vs. filled notes indistinguishable visually.

- **Actions Required:**

  - Display distinct icons/count indicators for multiple notes:

    - `pencil` for single notes.
    - `pencil+pencil` or `+<X>` for multiple notes (>3).

  - Color icons according to the highlight associated.
  - Differentiate clearly between notes with content and empty notes visually.

---

### Message I sent to you after everything broke before (applies to branch `codex/improve-numhi-prompt-and-features`, NOT CURRENT BRANCH you'll be working on, which at least 'works' with the exception of note persistence, highlight robustness and the various other issues you see above.)

A lot of core functionality is broken, but the on-hover preview of the colorcode is looking PRETTY NICE!!! (It does still need its own separate toggle keybinding though, in the same namespace as the others, just like the pencil icon needs one and the requested feature of a note view mode that inserts the line(s... enough to display the note content) of virtual text below the line holding the highlight being hovered (virtual text space should only be visible during hover FOR the highlight being hovered, and should collapse after moving cursor off highlight)). It's just that most everything else is broken, unfortunately (being the tiniest bit hyperbolic, but still... significant amount of core functionality has been 'broken') and you'll need to be careful to fix it.

HOWEVER... This time I (hopefully) have at least SOME of the dependencies needed, including Neovim and all of its dependencies. You also have internet access for a bit, so I'll let you get to it!! Good Luck!!

---

### Current prompt for the current conversation

DON'T BREAK THE NOTE KEEPING FUNCTIONALITY!!! There are other branches in the repo that you worked on before, and both of them have an AMAZING highlight (branch is called `codex/improve-numhi-prompt-and-features`), !!BUT **_MOST EVERYTHING ELSE BROKE_** including note persistence (!!even within a single session... and we want it cross session!!)!! and with it the ability to retain and show tags as virtual text, and more!!.

```

```
