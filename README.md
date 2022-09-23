# Reaper Programming



## Glossary

- [Chunks - sections of a midi file](https://www.recordingblogs.com/wiki/track-chunk-of-a-midi-file)
- [Header Chunk](https://www.recordingblogs.com/wiki/header-chunk-of-a-midi-file)
- [Midi File Format Structure](http://www.music.mcgill.ca/~ich/classes/mumt306/StandardMIDIfileformat.html#:~:text=MIDI%20Files%20are%20made%20up,the%20chunk%20type%20is%20introduced.)
- [State Chunk Definitions](https://github.com/ReaTeam/Doc/blob/master/State%20Chunk%20Definitions)
- [Track -  A track in Reaper is a container that can hold both audio and midi information](https://reaperaccessibility.com/index.php/Tracks_and_Track_Folders)
- Media Items -  A track can contain one or more media items, this could be a section of midi or a section of audio
- Take, - A media item can have one or more takes

## Reapscript

- [Offical Documentation](https://www.reaper.fm/sdk/reascript/reascript.php)
- [Formatted and Annotated Version](https://www.extremraym.com/cloud/reascript-doc/)
- [Tutorial Docment](https://admiralbumblebee.com/music/2018/09/22/Reascript-Tutorial.html)
- [Tutorial - Youtube](https://www.youtube.com/watch?v=Z-tlfoHeCIc)
- [Rea Reference](https://www.extremraym.com/en/themes/son/)
- [Community Sourced Documentation](https://forum.cockos.com/showthread.php?t=207635)
- [Community Contributed Tutorials](https://forum.cockos.com/showpost.php?p=2111686&postcount=88)
- [ReaScripts-Templates - Boiler Plate Code for Scripts](https://github.com/ReaTeam/ReaScripts-Templates)

## Reference Projects

- [Chordgun](https://github.com/benjohnson2001/ChordGun)



## Notes

- From Reascript Browser, install : Lokasenna’s GUI library v2 for Lua and Lokasenna’s GUI library v2 for Lua (developer tools)
- Launching GUI Builder: Action then  - > “Script: Lokasenna_GUI Builder.lua”. Hit Run.
- GUI Builder files are stored in C:\Users\<username>\AppData\Roaming\REAPER\Scripts\ReaTeam Scripts\Development\Lokasenna_GUI v2\Developer Tools\GUI Builder by default.


## Design Interfaces in Lua

<br />
<a href="http://forum.cockos.com/showpost.php?p=1679270&amp;postcount=2" rel="nofollow" target="_blank">1. Creating and maintaining a window</a><br />
<a href="http://forum.cockos.com/showpost.php?p=1679273&amp;postcount=3" rel="nofollow" target="_blank">2. Colors</a><br />
<a href="http://forum.cockos.com/showpost.php?p=1679764&amp;postcount=13" rel="nofollow" target="_blank">3. Drawing (part 1)</a><br />
<a href="http://forum.cockos.com/showpost.php?p=1680258&amp;postcount=18" rel="nofollow" target="_blank">4. Text</a><br />
<a href="http://forum.cockos.com/showpost.php?p=1680681&amp;postcount=27" rel="nofollow" target="_blank">5. Getting user input (part 1)</a><br />
<a href="http://forum.cockos.com/showpost.php?p=1681283&amp;postcount=34" rel="nofollow" target="_blank">6. Introducing the LS GUI library</a><br />
<a href="http://forum.cockos.com/showpost.php?p=1681486&amp;postcount=40" rel="nofollow" target="_blank">7. Example class - Button</a><br />
<a href="http://forum.cockos.com/showpost.php?p=1682186&amp;postcount=45" rel="nofollow" target="_blank">8. Tables, classes, and methods</a><br />
<a href="http://forum.cockos.com/showpost.php?p=1682652&amp;postcount=50" rel="nofollow" target="_blank">9. Working with strings</a><br />
<a href="http://forum.cockos.com/showpost.php?p=1683783&amp;postcount=56" rel="nofollow" target="_blank">10. LS GUI in detail</a><br />
<a href="http://forum.cockos.com/showpost.php?p=1684419&amp;postcount=57" rel="nofollow" target="_blank">11. Example classes - TxtBox, Sldr, and Knb</a><br />
<a href="http://forum.cockos.com/showpost.php?p=1685011&amp;postcount=61" rel="nofollow" target="_blank">12. Using images</a><br />
<a href="http://forum.cockos.com/showpost.php?p=1692993&amp;postcount=64" rel="nofollow" target="_blank">13. Having your script interact with the GUI elements</a><br />
<br />

## Debugging ReaScripts

- [Interactive Debugging in Lua and Reaper](https://www.youtube.com/watch?v=chGmCKMP04s)
- [Mavriq Debugging](https://forum.cockos.com/showthread.php?p=2525000#post2525000)
- [Lua Debugger- ZeroBrane](https://studio.zerobrane.com/doc-lua-debugging)

## API Calls
- reaper.Main_OnCommand(40042, 0) --reset cursor to start
- reaper.Main_OnCommand(40699, 0) --cut selected items
- reaper.Main_OnCommand(40062, 0) --create duplicate track
- reaper.Main_OnCommand(40421, 0) --select all items on duplicate track
- reaper.Main_OnCommand(40129, 0) --delete them


### Midi Editor

- reaper.MainOnCommand (40153,0) -- Opens the midi editor window
- reaper.MainOnCommand (40003,0) -- Select all notes
- reaper.MainOnCommand (40002,0) -- Delete all notes

### File Handlin

- [File handling functions](https://github.com/ReaTeam/ReaScripts-Templates/blob/master/Files/spk77_Files%20management%20functions.lua)


### All Commands
- [All Midi Commands](https://stash.reaper.fm/oldsb/50479/REAPER_MIDI-Editor_command-identifiers.txt)
- [Main WIndow Commands](https://stash.reaper.fm/oldsb/50478/REAPER_Main-Window_command-identifiers.txt)
- [All Commands for Lua](https://www.reaper.fm/sdk/reascript/reascripthelp.html#l)


### Reaper Hierarchy in Lua

- MediaItem reaper.GetTrackMediaItem(MediaTrack tr, integer itemidx) - get the media item on track tr at index itemidx 
