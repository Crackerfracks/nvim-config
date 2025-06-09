I'm going to open up the list of tasks that you were given in the past (5-6-2025*Raw*-\_feedback_and_tasks_list.md) and talk about how this most recent version of the code is interacting with those items.
... I congratulated you initially when you achieved some of these things.
You had added all of the plug-in commands for numhi.
That's N-U-M-H-I with the N and the M... Sorry, the N and the H capitalized.
You made it so I could just hit Q to write and close the buffer.
That currently is broken in this most recent version of the code.
The... Let's see.
So currently I have to manually save the buffer, or the notes buffer, in order for the notes to persist attached to the highlight.
And obviously, as it says in this prompt and list of tasks, the point is for the note content to persist across sessions.
So I have to manually save the buffer, or the note content to persist across sessions.
So it should be saved to disk somehow.
I'm thinking into a JSON of some kind.
That also should be used to track any changes that happen to the file like the auto formatter that runs when the file saves, as we also mentioned in the prompt.
Anyway, let's see.
I congratulated you on having no errors when loading a file that contains highlights.
That is still the case.
There's no error.
The highlights still stay, and unfortunately also the color codes, although they stay, which is good, we want the color code names to stay, the assignments for those color codes should be on a per-file basis.
So a per-file basis, if there is a file where I have named a color code and used that color code to highlight text and perhaps attach notes, whatever, the color code name should be specific to that file, essentially.
In the future, I probably would want options to maybe set a number of default color codes, and then whenever I apply a color code, I would like an option to clear the name for it.
But again, this color code name, the label I give it, should be on a per-file basis.
Even though, like I said, I do want an option to maybe set it for a directory or something like that, but that would require an integration with probably oil or something like that, just some way to... Or maybe not oil, actually, now that I'm thinking about it.
Anyway, I'm getting sidetracked.
Then I congratulated you for the note content and tag content remaining, because saving doesn't error, and that still is true, and it saves the notes, and that still is true, but I have to actually explicitly save.
I can't just tap Q and have it auto-save, which is what we should be doing.
The... Yeah, the wording for the NumPy prompt, as far as I can tell, it still does not work.
Sorry, hitting backspace still does not work.
I'm going to try it again right here, live, while I'm recording this prompt.
Let's see.
If I hit backspace, it still cancels out completely.
What it should be doing is doing something similar to... Instead of having the prompt pop up in a notification, it should probably pop up in a little temporary floating buffer, kind of like the notes is acting, but obviously that prompt would be a prompt and not a writable buffer or anything, instead of popping up as a notification, because then it just disappears, and what the fuck do I do then? Once it disappears, there's no way to tell whether or not hitting a key like Enter or anything will apply the highlight, and whenever I try, it does not work.
I can only assume that when I hit backspace, not only does it clear the prompt, but it literally clears the prompt and then just shows me a blank window, a little blank notification labeled NumPy, and then it essentially exits out of the operator mode, or whatever that is.
Maybe instead of using the notification system and an explicit color code prompt, maybe it should be like an operator that just updates the color of the highlighted text as you're typing it in.
Oh shit, I don't know.
Actually, no.
Forget that.
I'm thinking more something along the lines of what mini.
surround does, where it pops up a prompt that you can actually see, and the things you type into the prompt, like your cursor goes there, you can actually type letters into the prompt, or numbers or whatever, and they will show up and be rendered.
It would be nice if that happened too with our prompt, and if the highlight color of that prompt area updated to match whatever three-number digit was there, the prompt should reject non-numeric inputs from 0 to 9.
It should reject and just not even recognize those keys for typing in there, just to avoid erroring.
It should only input what the person has typed in if it's a 1, a 2, a 3, a 4, a 5, a 6, a 7, an 8, a 9, or a 0.
Obviously with the exception of exiting the prompt via escape or hitting backspace to remove what's there, or you could even have it be where you pop into an insert mode, but you can exit into normal mode and highlight the digits that have been added so far and delete them like you would normally on a buffer.
The pencil icon now displays whether or not there is a note on that highlight, and it still displays along the left side, and it probably shouldn't.
I think the pencil icon should be used in the floating on hover window, which should only contain the color code name that we gave it.
The actual color code as well, like VID, whatever it is.
The tags that are attached to that note, like the hashtags.
And then the pencil icon to indicate if there is written note content that is not tags.
And then the alternate display mode for that on hover floating window should be to toggle the size of the window enough to display the full note content.

Moving on, you've fixed the persistence of the on-hover quote-unquote notification.
I love that it's its own floating buffer that shows the highlight.
I love that there is the potential for turning that into a on-hover display of the full note content and that it can move with the cursor.
I think it would be best if the trigger for it showing up were to happen quicker.
It doesn't seem to be very performance heavy to do it.
It doesn't necessarily need to be instantaneous but it would be nice if the note content re-rendered fairly fast assuming that the cursor weren't continually moving because we don't want to bog things down.
Whatever you can find to make that a fast process is probably good.
Obviously without fucking breaking it.
As far as hitting backspace with this new paradigm we're talking about maybe we don't necessarily even need to worry about backspace.
You can just use regular typed commands.
Just regular navigation and stuff.
Just have a little prompt.
You can do insert in normal mode in that little prompt area.
You can highlight words, move the cursor around.
Until you're in the buffer and hit enter or escape to leave enter to accept or escape to cancel then it just stays there.
Since I have flash.nvim and remote operator I could just remote operator grab a color code from somewhere in a document and paste it into the prompt if I wanted to.
That's cool.
Moving on.
I'm going through updating the NumHy highlighting and note-taking plugin open parenthesis, left-facing arrow made up of angle bracket and two dashes current task, close parenthesis.
The feedback and instructions part is what I'm going through bit by bit.
We are on... Let's see.
I've already mentioned that the note content does not persist anymore across... Oh no, the note content does not persist across sessions.
It never has persisted across sessions.
An interesting thing that happens now is that if the buffer is empty and I add... Sorry, the note buffer for a highlight that I've attached to a highlight is empty and then I add text to it, dismiss the buffer by hitting Q without saving it and then open a buffer, like open another note or just open a note again on that highlight the note text that I'd added before on the previous note buffer is nowhere to be seen.
But if I save that second empty buffer, the buffer that I reopened, then all of a sudden the next time I open it, it populates with the note content.
So something a little fucky is going on there, obviously.
I would like to call attention again to SQLite.
I have the SQLite plugin installed.
If that seems like a decent idea, maybe that would be a good way to keep the note content across sessions as well as the highlight content.
However you're storing the highlight information now could probably be stored the same way, but just in the SQLite database.
And I think the best thing about that is that I could password protect it too if I wanted to in the future, which would be really nice.
Anyway, let's see.
Let's see.
Let's see.
Oh yeah, the pencil icon is blocking out any ability for the left gutter to show me any warnings or errors if there were any.
Like I said, that needs to be on the floating on hover.
The on hover... I'm pretty sure this is a mini buffer, but right now I can't teleport Flash into it.
I can't teleport my cursor into it.
Maybe it would be better to literally just make the... to make that window accessible via Flash rather than needing to explicitly open it up.
Rather than needing to explicitly open a buffer, like a note buffer with leader, leader, triple N, like leader, leader, N, N, N.
Maybe it would be better that just once you highlight some text that if you added a color code, like a name for the color code, then you get that floating window that we have here.
If you don't add a name for the color code, then it shouldn't show, it shouldn't pop up a window.
At least not by default.
If you then attach a note by manually opening up with leader, leader, N, N, N, then I think it should show the on hover notification.
But it should always show it if there's a category title, like a color code title.
I really think that once you have this floating note thing here, it should just be able, since it can follow the cursor pretty fast, it should be able to serve as a floating note area where you can just type.
I think there should be some logic here so that the width of the floating buffer can grow depending on the line width, but it can only be up to maybe half of the current neovim pane width.
Or I guess it would be column width.
So it can only be half of that to make sure it can always fit within the pane itself.
And that the height of it should be able to grow pretty much indefinitely if you were to continue adding text so that it needed to grow indefinitely.
It should be able to grow indefinitely.
The view should scroll within it.
Actually, you know what? Maybe there should be a height limit.
The height limit can also be half of the current height in rows, I guess it would be, of the neovim buffer.
All right, let's section this part of the transcript.

All right, and moving on... Oh yeah, we absolutely need to make the highlights more robust against the format on save.
I don't know if it's that... I don't know, like I said before in the previous prompt, I know that I can edit the file, and put new lines or delete lines from above the highlight, and it's robust when I'm in NeoVim and editing the file manually, but that automatic formatter just strips the highlights off of it.
I don't know what's happening, I don't know if it's because the highlights aren't updating or... It's got to be that.
It's got to be that the formatter changes the location of the text, the coordinates of the cells where all of the previously highlighted text is, by removing lines or removing a space or changing a character, removing a character or something like that.
And those changes propagate outward, and all of a sudden the program can't find the string anymore.
But that seems like a bit of a cop-out, because it feels like the code to make that more robust is really simple, and just would have to run whenever the format on save happened.
And in most cases the text that will be getting highlighted will have... will probably only have one match in the whole document, especially anywhere close to the coordinates where it was highlighted originally.
Most changes made by the formatter are going to be pretty small, and the probability of running into the same string of text equidistant on both sides of the original location of that text seems really improbable.
So I think a good way to do that would be the closest string in the document that matches the string you've been given, or maybe even the closest match, like the closest match spatially within the file, and then also the closest match as in least number of differences.
But that's something you can think about yourself.
I'm just spitballing over here.
Yeah.
Okay, moving on.
Yeah, the highlights are technically more robust, but they're actually fragile because of the formatter, and their note content is completely ephemeral, transient, doesn't last.
It's like Ryan Gosling.
Let's see.
Yeah, take your time, take your time, take your time, take your time, take your time, take your time, take your time.
And you also, you should have NeoVim and all its dependencies already installed on your system, in your workspace, in the environment.
So any tests you need to do, you should be able to run.
I'm going to see if there's a headless version of NeoVim for plug-in development that you can use to test.
Actually, just a second, I'm going to see if that exists.

Actually, it looks like you can just run it headless.
I don't know what the limitations of that are, but you'll have access to the internet to find that out.
Let's see if that's even helpful for plugin development at all.
Moving on.
All right, so issue number one.
Prompt functionality. Backspace behaves like a cancel button.
That still is true.
By clearing the input, it seems like the code is literally clearing the prompt text and just outputting a blank notification that just shows up and goes away and the operator mode is done.
So that's dumb.
We don't want that.
No offense.
Objectively, that's not what we want.
Silly.
Escape definitely should escape the prompt.
Nothing changes about that.
But I think we're going to want to have that prompt be something that persists with... The cursor can be there.
And we can live update the text inside that prompt and using NeoVim methods, highlighting and deleting, substituting, changing, replacing, whatever it is, adding.
And whenever we type in there, the only thing that will ever show up for us until we press enter and accept it will be one to three numbers.
Any additional numbers should just probably remove the oldest number or just reset it to nothing and be the first number.
Rather than erroring out, we don't want things to just error out.
It seems pretty easy to handle or to like... Yeah, those seem like pretty easy exceptions to handle.
So backspace can legitimately just do what it normally would do.
If I'm in insert mode, it can delete one of the numbers in the floating num high prompt there.
And if I'm in normal mode, it can just move back by one space.
It doesn't have to clear any input or anything.
I'll literally do VIW or maybe just shift V and then D to clear shift that way.
Um, that's fine.
And then once you hit enter, obviously it should apply it all.
And it should live update the highlight inside that prompt for the three, the three digits should reflect the highlight for the number that has been typed plus the palette that's currently selected.
Um, notification section here for task two, um, for the first bullet point in the issue for your, uh, notifications on cursor hover are transient and incomplete.
That has pretty much been fixed.
Pretty much.
Uh, there is, um, an issue, kind of, not really an issue, um, where toggling tag display will cause tag displays or tags to display in the hovering notification.
Um, uh, see, um, it will display at the end of the color code name.
Um, and then it, the, the note content is written below that next to the pencil icon, which is pretty cool and an awesome UI choice, by the way, like I said earlier, or like I kind of, I don't think I really said it, but it's true.
Um, we just need to make it be able to grow with the length of the text, uh, horizontally up to a point about half of the current column width.
Um, cause I normally have wrapped turned on anyway.
So text wrap should be, um, turned on by default in this floating buffer and, um, yeah, the width of the window itself should cap out at a certain, uh, width, like I mentioned before.
And then the same thing should happen with the height of the note.
Um, I think there should be some key bindings inside for, for like, while you're inside this note to, uh, reposition it.
Um, I'm thinking that, um, it should probably position itself on the other side, or like, I guess, transverse, I guess, to the direction that the cursor last moved, right? It should try to, if I'm moving my cursor to the, uh, to the left from, you know, towards the beginning of the line, then the floating window should be, um, essentially as far over to the, um, to the right as possible with the left, um, edge of it aligned with the cursor, right? And that's currently the default position that it's always in.
Um, and it will currently actually, um, bust at, like, it's not contained, this on hover is not contained, uh, within the pane that it's, that it's from.
It can actually be, uh, it can display over, you know, a neighboring buffer if I make the, the pane where the highlight is very thin.
Um, so that's one reason why I think that one reason why I think that the, the, the tendency should be that if I'm moving the cursor in one direction, the note should try to display itself on the opposite direct, in the opposite direction.
If I move the cursor up, the note should display below the cursor.
If I move the cursor down, the note should display above the cursor, because if I move the cursor down, I'm probably trying to view the content of the buffer I'm in that's below the note.
Um, and I think now that I'm saying this, that this on hover, um, aspect of it should be one of several modes, uh, for this, like, note window.
This, this, um, yeah, this window of, that has a note attached to a particular highlight.
I think that while you're on, while you're hovering, you should be able to, I guess, attach the note to your cursor.
There should be a binding for, um, basically triggering the window to follow your cursor until you unbind it, until you, like, release the note window.
Um, so that if you want to, um, move around the document and look somewhere else, that you can bring the note with you, um, until you release it, at which point it should, you know, uh, the, you know, the, the window should disappear and the content should get saved to that highlight, and to a god, sorry for my language ahead of time, to a goddamn database of some kind, or a goddamn structured file for that specific buffer, so that when I load it up again, I didn't waste all of that time writing those notes.
I want to keep those notes, um, and those color code titles for that buffer until I decide to clear them for that buffer, um, and then having a way to have defaults set and to, for, for the names of the color codes, and to be able to clear them would be nice.
Um, I think that should all be built into the prompt itself, rather than having a bunch of different key bindings.
So, by all that, I mean, um, being able to, uh, use a default or, like, um, or, like, I don't know exactly how the default would, would work.
Maybe there should be, I think, automatically, when you apply, or when you, when you name a color code in a directory, it should make a, some kind of, like, a file in that directory that stores the name of that color code, um, as a default.
And then whenever you apply that color code, by default, it should start with that name, with that, um, that color code name, like, pre-filled in the prompt.
And then if I decide to delete that and give it a different name, then it'll have the different name.
Um, but otherwise, um, oh, let me be more specific.
If I, uh, take a red highlight and I name it, um, an instruction following, and, uh, I apply it to some text in a file and I save it into a folder named A-Responses, and then I create another file in that folder called, let's say, let's say the first file is called A-Response1, and I'll call this one A-Response2, and I'll put some more text in there, and then I highlight something and I highlight it, or I, I choose red, the red color code.
When I do that and open up the, um, or when I hit enter, um, it should pop up the, the prompt for naming the color code.
I guess currently it doesn't pop up the prompt if there's already a name for that, um, for that color code.
But it should always pop it up, and that's all, that should, that should be a chance to change whatever the name is for that color code.
Um, so, let's say I have, um, A-Response1 and A-Response2.
A-Response1 has some text that I've highlighted and called it instruction following.
Let's say I go to highlight some more text in, um, um, A-Response2, and I choose red again, and it comes up, and it has the text instruction following.
If I delete that text and then put, um, factuality or something like that, then it should, um, to that file that's in the directory where that default is stored, it should then add the, um, add factuality to that list of defaults, and when you go to open up a prompt for red, I think that you should be able to scroll up or down through that list, just like you can for, um, previous commands in, like, a terminal emulator or something like that.
Um, I think that would be a good idea.
Okay, um, right now, toggling the, uh, display of tags, uh, still only, uh, okay, so I have another bug, another bug.
Okay.
Just a moment.
Okay, so, uh, what I did was I toggled the virtual text that the tag display, um, on and off, and it's showing the, the tag that I had at that point, um, you know, blink in and out from the virtual text area at the end of the sentence, but, um, uh, when I went back into the note content itself, the tag that I put in there was gone.
I put hashtag test, and, um, when I toggled the, the tag display, it, it stripped, um, text out of that, that note.
Let me try it again.
This time, I put in testing, testing, hashtag one, hashtag two, hashtag three, so I'm going to do space, space, n, n, t, and it, this time, it removed the content that was in the note and replaced it with just hashtag test, so what it looks like it's doing, okay, so it looks like what it's doing is, um, when I, um, when I put tags in the note, it is, sorry, I'm doing another test, okay, so I really don't even, I don't even know, like, what's going on now, so it looks like, um, the, the way that the tags are being read when I toggle the tags, um, tag display is causing, like, the note content to just get wiped, um, but then sometimes it'll bring it back, and it's, like, weird, it's not acting the way it's supposed to, um, not great.

Okay, so moving on.
Yes, the toggling of tags seems to be into the virtual text, and toggling them off seems to just be wiping the note content.
I can't access it anymore.
It seems like there's no consistent location that it pulls the note content from.
I really think we need to have a consistent location that has persistence across sessions.
So just like an external file or database or something.
Okay.
Yeah, the quote unquote notification here persists as long as the hover is happening.
Don't forget, it needs to be able to resize automatically in response to text, and we need to be able to manually reposition it, hide it, reshow it, and just move it to each side of the cursor.
And it should always try and mirror what the position of the on hover window should mirror what the cursor is doing.
It should always say either above or below the cursor, and never obscure the current line or any of the lines where it's highlighted.
So it should be below the cursor, but also below any highlighted text, any of the highlight that's currently being hovered.
So if the highlight expands multiple lines, either actual multiple lines with new lines or fake new lines with word wrap, it should be below the very end of that line.
It should be below the final line that contains any highlighted string that's being hovered on.
So yeah, if I'm moving the cursor up, then it should be below the very lowest part of the highlight, unless I'm no longer hovering on the text on the highlight anymore, in which case it should disappear.
Unless I have attached it to my cursor using the whatever method you come up with for that that I mentioned before.
Virtual text toggle is still having issues like I mentioned, so definitely take a long hard look at that.
There's still a lag with tag display, it's not showing immediately.
Honestly, I feel like the tag display should just toggle between only showing them in the floating notification slash soon to be note buffer as well, or at the end of the line in virtual text.
Or, once we do add it, that inserted area of virtual text, because right now it's just a buffer on hover that I can't move my cursor into.
Maybe it is currently virtual text, technically, but... Because right now, trying to teleport the cursor into that area causes some major issues with flash.nvim.
And I think that's just because I'm trying to teleport my cursor into some area with virtual text, but it's still letting flash read from it.
Which I think it should let flash read from it, and it shouldn't be virtual text, this floating buffer thing, that's not what I was talking about when I mentioned virtual text.
I was talking about an actual virtual text line, like an additional 'virtual' line, or lines that would get inserted underneath the current line that has the highlight for the purposes of displaying the note content.
And it would be like a drawer, each line with a highlight would kind of be like a drawer that could essentially open up and show this note, even if it's really lengthy.
We already talked about the highlight data persistence and restoration.
Your best efforts here have not been good enough.
No model seems to be able to do this right now, so to do so would be to set yourself apart.
Let's see, I don't think that in the on hover window next to the note, like the pencil icon, I don't think that the tags should be displayed.
I don't think they should be displayed there.
Even if they're on the first line, I think the display should act like those aren't there, and they should only show up next to the color code in the on hover.
And if the display option has been toggled to show virtual text, then in the virtual text area at the end of the line, or if the alternate virtual text has been implemented with the virtual area below the line, then it should use that instead.
Yeah, we already talked about the LSP, formatting, and breaking the highlights.
It says possible instability linked to the EM crashes.
I've only had that happen one time.
And I think there was something else that caused that.
Tag virtual text color has been fixed and now shows the same color as the tag itself.
I wonder if it should be better identified as tag text.
I have a feeling that the foreground, like the letter color, the font color, should be what takes on the color of the highlight, not the background.
Because that's just kind of distracting to have a second set of text with a brightly highlighted background that makes it look like an additional highlight of that color.
So anyway, I think that the text color should be what takes on the color of the highlight.
Okay.
Ah, of course I need to break this down.
That's one of the ways I'm going to get to that.
Let me just sort of see what... Okay.
That can be disregarded.
As long as the tag text is showing up the way that it's supposed to, then that should be fine.
And this is a little bit more complicated.
And the virtual text should... If any part of it is going to get cut off by the edge, like the boundary of the buffer, instead of just continuing off the buffer, it should then just place itself on a new line below that, on a virtual new line below the current line where the highlight is.
There's no way to tell if there are multiple highlights on a note.
I think that's about it.

---

---

---

## 📋 Task Review: Reflections on 2025-06-05 NumHi Update + Feedback Integration

I'm opening the task list from `5-6-2025*Raw*_feedback_and_tasks_list.md` to go over how the **current version** of the code interacts with those items.

---

### ✅ Previously Completed Tasks (Partial Retention)

- You **added all the plugin commands** for `NumHi` (`N-U-M-H-I`, with `N` and `H` capitalized) — good job there.
- You made it so I could **just hit `q` to write and close** the notes buffer...
  - ❌ But that **no longer works**.
  - Right now, I have to **manually save the buffer** for note content to persist.

> The notes **should persist across sessions**.  
> That means: **write to disk** — preferably via `JSON`.  
> This should also integrate with **on-save formatters**, as mentioned earlier.

---

### 🎉 Highlight File Load Behavior

- ✅ No errors when loading a file with highlights.
- ✅ Color code names are retained.

But...

> 🛑 **Color code names should be stored on a per-file basis.**

Future wants:

- Option to **set default color code names** (maybe scoped per directory)
- Option to **clear assigned names** as needed

---

### ✏️ Note and Tag Content

- ✅ They are being saved and don’t error — **only if I explicitly save**.

🔧 But:

- `q` should **auto-save** on exit
- Should not need to run `:w` manually in a scratch buffer for note retention

---

### 🚫 NumHi Prompt: Backspace Behavior Still Broken

Live test:

- Hitting **Backspace** immediately clears the prompt and kills the input
- This drops me out with a blank notification labeled `NumHi`, and **nothing happens**

Suggested Fix:

- Don’t use notifications for this kind of prompt
- Instead, use a **temporary floating buffer** (like `mini.surround`)
  - Cursor should be visible
  - Input should be **typed in directly**
  - Should **update background color** in real time for valid 1–3 digit entries
  - Only accept input for keys `0–9`
  - Invalid keys should be **ignored**, not cause errors

---

### 🖋️ Pencil Icon Placement

Current:

- Pencil icon displays along **left gutter** — not ideal
- Should be part of the **floating on-hover window** only

Floating On-hover Window Should Include:

- **Color code name** (e.g., `"Instruction Following"`)
- **Palette name/code** (e.g., `VID-1`)
- **Tags** (`#grammar`, `#model-A`, etc.)
- ✏️ Pencil icon to signal **written note content**
- Alternate display: allow toggling to show **full note content**

---

### 🪄 Hover Window Behavior

✔️ Persistence of on-hover quote-style display works well.  
👍 It acts as a floating buffer, which is fantastic.

🧠 Ideas:

- Should **trigger faster** (hover delay is too slow)
- Render content quickly if cursor isn’t moving
- Should act like a **live scratch note editor**
- Let users **type into the window** directly
- View should **scroll** if height exceeds limits
- Cap **width** at 50% of `vim.o.columns`
- Cap **height** at 50% of `vim.o.lines`

---

### 💾 Saving Note Content

❌ Still **not persisting across sessions**

Weird behavior:

- Write note → `q` (without save) → reopen = note is missing
- If you save the **empty** note buffer next time, old content appears again 🤔

💡 Suggestion:

- Consider **SQLite** (plugin is installed)
  - Could store both **highlights and notes**
  - Benefits: encryption, queryable metadata, persistence

---

### ❗ Gutter Display Conflicts

- Pencil icon is **blocking** diagnostics (LSP warnings, etc.)
- Should **not appear in the gutter**
- Keep indicators in the **floating on-hover** UI only

---

### ⚡ Flash.nvim + Cursor Teleportation

- Floating window isn’t accessible via `flash.nvim`
- Would be better if it were **teleportable** and **cursor-accessible**
- Triggering note window via `leader leader N N N` is fine, but:
  - If a **color code has been named**, then:
    - The floating window **should always display** by default
    - Only suppress if **no name or note exists**

---

### 💡 Floating Note Window

Let’s make it act like:

- A **floating pane** that can grow as needed
- Maintain cursor proximity
- Allow resizing/repositioning
- Mirror cursor motion:
  - If cursor moves **left**, place window to the **right**
  - If moving **down**, place note **above**
  - If moving **up**, place note **below**
- Prevent overlaps:
  - **Never cover** highlighted lines or current line

---

### 🧷 Note Mode States

Have modes:

- On-hover floating buffer (read-only)
- Focused editable buffer (manual open or hover-click)
- **Attached to cursor** (follow mode until “released”)

---

### 🧷 Per-Buffer Color Code Defaults

- Assigning a **name to a color code** should create a file in that directory
- Default name should:
  - Be **pre-filled** in prompt on reuse
  - Be **editable** at prompt time
  - Add new label to that color if changed

📜 Scrolling through **past names** for the same color code = ✅ (like shell history)

---

### 🐞 Tag Display Glitches

New bugs:

- Toggling virtual tag display sometimes:
  - **Wipes note content**
  - Replaces it with only `#tag` string
- Going back into the note buffer shows the rest **missing**
- Tag toggle causes **state loss or corruption**

🧰 We need:

- **Consistent tag storage location**
- Proper serialization of note + tags in external structured data

---

### 🗂️ Virtual Text Mode

Tag display toggles between:

- End-of-line virtual text ✅
- Hover buffer (preferred)

Request:

- Eventually support “virtual drawer” lines **beneath** the highlighted line

---

### 🔄 Highlight Update & LSP Formatting

Highlights don’t survive **format-on-save**.

Problem:

- Formatter **changes positions**, so coordinates break
- Highlight isn’t reapplied after undo/paste

💡 Fix Ideas:

- Match on **closest string match** by:
  - Proximity to original location
  - String similarity (Levenshtein?)

Don’t rely on coordinates alone. Match on **both text & location** heuristics.

---

### 🧪 Testing Support

You should be able to:

- Run **NeoVim headless** for plugin testing
- Access a **headless API** to test:
  - Command results
  - Highlight accuracy
  - Buffer contents

---

### 🎯 Prompt Redesign (Again)

**Backspace = cancel** is _still broken_.

Proper behavior:

- Backspace should **edit** input (not cancel)
- Only `Escape` should exit prompt
- Input should:
  - Accept **only 1–3 digits**
  - Reject everything else
  - Remove old input if max exceeded
- Support **insert + normal mode editing**
- Use Neovim’s built-in navigation (`x`, `dw`, `diw`, etc.)

---

### 🧾 Floating Prompt Highlighting

- Prompt should **live-update** its own background
- Match the typed code + current palette (`VID`, `MTL`, etc.)

---

### 📣 Notification Status (Cursor Hover)

- Works **mostly fine**
- Tags can now appear beside color code
- Full note content shows **beneath** that, with the ✏️ icon

UX suggestions:

- Cap width at 50% screen width
- Enable **text wrap**
- Keybindings inside the buffer for **manual reposition**
- Buffer should try to auto-place **opposite of cursor movement**
- Support **follow mode**: bind/unbind note window to cursor

---

### 🧰 Notes Must Persist

When I take the time to:

- Name color codes
- Write detailed notes

...I expect them to be saved. **Always.**  
To **a database** or **structured file** with predictable format.

---

### 🌱 Color Code Naming Propagation

Example:

- `A-Response1` uses red = `"Instruction Following"`
- In `A-Response2`, red should default to `"Instruction Following"`
- Prompt should **pre-fill that name**, but allow **override**

If I rename it:

- That new name should be added to a **list of options** for that code in this folder

---

### 🔁 Prompt Recall

When naming a color code:

- Be able to **scroll up/down** through previous entries
- Like command history in terminal

---

### 🧪 Tag Display Bugs (Again)

Bug:

- Toggling tag view wipes the note
- Tags randomly appear/disappear
- There’s no centralized source of truth for tag/note data

We need:

- External **persistence layer**
- Unified data structure
- Graceful toggle logic

---

### 📏 Virtual Text + Display Overflow

Issue:

- Virtual text overflows buffer boundaries
- Should detect overflow, and:
  - Push content to **virtual line below**

---

### 🧩 Pencil Icon + Gutter Collisions

Suggestion:

- Only display pencil icon **in hover buffer**
- Or in “virtual drawer lines” if we implement that
- Do **not block** diagnostics

---

## ✅ Wrap-Up

That’s about it.  
Please remember to retain:

- **Data integrity**
- **Persistent metadata**
- **Responsive UI**
- **Editor-agnostic highlight behavior**

> If you get this right... NumHi will be _unlike any other Neovim plugin_.

Take your time.

Take your time. Browse the plugin development documentation. see what you can do in the environment since you have neovim there. Take your time and cook. I want to let you cook.
