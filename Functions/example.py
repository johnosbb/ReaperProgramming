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
    local itemEndPosition = 20.5
    reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.
    local lengthOfPhraseQN = 0
    local notes = {} -- create a notes table
    -- We get the basic note pattern for the references track which we assume to be track 0
    local referenceMelodyTrack  = reaper.GetTrack(0,0) -- get reference track assuming it is the first track
    mediaItem = reaper.GetTrackMediaItem(referenceMelodyTrack, 0)
    local referenceTake = GetTakeFromTrack(referenceMelodyTrack,0,0)
    if(referenceTake) then
        local numNotesInReference = 0
        retval, noteCount, ccs, sysex = reaper.MIDI_CountEvts( referenceTake )
        Msg("Processing " .. noteCount .. " notes in this take")
        LogTakeData(logFile, referenceTake ) -- Execute your main function 
        lengthOfPhraseQ, numNotesInReference, notes =  CreateNoteCollectionFromTake(referenceTake)
        Msg("Process " .. numNotesInReference .. " notes in track with a QN length of " .. lengthOfPhraseQN)
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
    CreateAdditiveMeasure(notes,1)
    CreateAdditiveMeasure(notes,2)
    CreateAdditiveMeasure(notes,7)
    InsertNotesInTake(generatedTake,notes,logFile)
    reaper.Undo_EndBlock("Additive", 0) -- End of the undo block. Leave it at the bottom of your main function.  
    retval, noteCount, ccs, sysex = reaper.MIDI_CountEvts( generatedTake)
    Msg("Found " .. tostring(noteCount) .. " notes in this take" )
    retval, noteCount, ccs, sysex = reaper.MIDI_CountEvts( referenceTake)
    Msg("Found " .. tostring(noteCount) .. " notes in the original take" )
    reaper.UpdateArrange() -- Update the arrangement 
    io.close(logFile)
end

-- reaper.TrackFX_AddByName(reaper.GetSelectedTrack(0 ,0), "ReaEQ (Cockos)", false, 1) -- It works
-- reaper.TrackFX_AddByName(reaper.GetSelectedTrack(0 ,0), "gain_reduction_scope", false, 1) -- It doesn't work

main()
