-- Start Mavriq Debugging --
-----------------  Added by Mavriq Debugging -------------------------
------- You may remove this if accidentally left behind --------------

---- DO NOT FORGET 'Project->Start Debugger Server' IN ZEROBRANE -----

mav_repo = '/Scripts/Mavriq ReaScript Repository/Various/'
package.cpath = package.path .. ';' .. reaper.GetResourcePath() .. 
   mav_repo .. 'Mavriq-Lua-Sockets/?.dll' .. ';' .. reaper.GetResourcePath() .. 
   mav_repo .. 'Mavriq-Lua-Sockets/?.so'
package.path = package.path .. ';' .. reaper.GetResourcePath() .. 
   mav_repo .. 'Debugging/?.lua' .. ';' .. reaper.GetResourcePath() .. 
   mav_repo .. 'Mavriq-Lua-Sockets/?.lua' 

require("mobdebug").start()
-- End Mavriq Debugging --



-- get script path
local script_path = debug.getinfo(1,'S').source:match[[^@?(.*[\/])[^\/]-$]]
-- dofile all files inside functions folder
dofile(script_path .. 'Functions/reaper_utilities.lua') -- General Utility Functions



PPQ = reaper.SNM_GetIntConfigVar("MidiTicksPerBeat", 0)
if (PPQ == 0) then
  PPQ = 960
end


function main()
    logFile = io.open("D:\\Reaper\\debugAdditive.txt", "w")
    local generated_track_name = '!Generation Track'
    local itemStartPosition =0
    local itemEndPosition = 7.5
    reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.
    local lengthOfPhraseQN = 0
    local notes = {} -- create a notes table
    -- We get the basic note pattern for the references track which we assume to be track 0
    local referenceMelodyTrack  = reaper.GetTrack(0,0) -- get reference track assuming it is the first track
    mediaItem = reaper.GetTrackMediaItem(referenceMelodyTrack, 0)
    local referenceTake = GetTakeFromTrack(referenceMelodyTrack,0,0)
    if(referenceTake) then
        local index = 0
        retval, noteCount, ccs, sysex = reaper.MIDI_CountEvts( referenceTake )
        Msg("Processing " .. noteCount .. " notes in this take")
        LogTakeData(logFile, referenceTake ) -- Execute your main function
        for retval, selected, muted, notestartppqpos, noteendppqpos, chan, pitch, vel in IterateMIDINotes(referenceTake) do
            local projectTimeSecondsNoteStart = trunc(reaper.MIDI_GetProjTimeFromPPQPos(referenceTake, notestartppqpos),2)
            if(retval and (projectTimeSecondsNoteStart >= 0)) then
                local note = {}
                note["selected"] = selected
                note["muted"] = muted
                note["notestartppqpos"] = notestartppqpos
                note["noteendppqpos"] = noteendppqpos
                note["startqn"] = trunc(reaper.MIDI_GetProjQNFromPPQPos(referenceTake,notestartppqpos),2)
                note["endqn"] = trunc(reaper.MIDI_GetProjQNFromPPQPos(referenceTake,noteendppqpos),2)
                note["lengthqn"] =  note["endqn"] -  note["startqn"]
                note["chan"] = chan
                note["pitch"] = pitch    
                note["vel"] = vel 
                table.insert (notes,note)  
                index = index + 1  
                lengthOfPhraseQN =   lengthOfPhraseQN + note["lengthqn"]
            end
        end  
        Msg("Process " .. index .. " notes in track with a QN length of " .. lengthOfPhraseQN)
    end
    local generated_track = CreateGeneratedTrack(generated_track_name)
    local mediaItem = reaper.GetTrackMediaItem(generated_track, 0)
    local generatedTake = GetTakeFromMidiMediaItem(mediaItem,0)
    if(generatedTake == nil) then
        Msg("The generated track " .. generated_track_name .. " does not exist, generating a new one " )
        generatedTake = CreateMidiItemForTrack(generated_track,itemStartPosition,itemEndPosition,true)
    end    
    local retval,name = reaper.GetTrackName(generated_track)
    Msg("Adding notes for " .. name)
    CreateAdditiveMeasure(notes)
    InsertNotesInTake(generatedTake,notes)
    reaper.Undo_EndBlock("Additive", 0) -- End of the undo block. Leave it at the bottom of your main function.  
    retval, noteCount, ccs, sysex = reaper.MIDI_CountEvts( generatedTake)
    Msg("Found " .. tostring(noteCount) .. " notes in this take" )
    retval, noteCount, ccs, sysex = reaper.MIDI_CountEvts( referenceTake)
    Msg("Found " .. tostring(noteCount) .. " notes in the original take" )
    reaper.UpdateArrange() -- Update the arrangement 
    io.close(logFile)
end



main()
