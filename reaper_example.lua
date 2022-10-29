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



local reaper = reaper


-- get script path
local script_path = debug.getinfo(1,'S').source:match[[^@?(.*[\/])[^\/]-$]]
-- dofile all files inside functions folder
dofile(script_path .. 'Functions/reaper_utilities.lua') -- General Utility Functions



PPQ = reaper.SNM_GetIntConfigVar("MidiTicksPerBeat", 0)
if (PPQ == 0) then
  PPQ = 960
end



-------------------------------
-- INIT
-------------------------------

function main()
  logFile = io.open("D:\\Reaper\\debug.txt", "w")
  local measures = {} -- this will hold a table of the positional data for each measure
  selectedTrack = reaper.GetSelectedTrack2( 0, 0, false )
  if not selectedTrack then
    reaper.ShowConsoleMsg("You must select a track first for this operation")
    return
  else
    media_item = reaper.GetTrackMediaItem(selectedTrack, 0)
    if(media_item) then
      local beatsPerMinute,timeSignatureNumerator, timeSignatureDenominator = getTempoTimeSignatureForItem(media_item)
      local projectLength = reaper.GetProjectLength(0)
      local measureLengthSeconds =((60/beatsPerMinute) * timeSignatureDenominator)
      numberOfMeasures = trunc(projectLength/measureLengthSeconds,0)
      if(numberOfMeasures < 1) then
        reaper.ShowConsoleMsg("There are no measures in the selected track")
      else
        reaper.ShowConsoleMsg("There are " .. numberOfMeasures .. " measures in the selected track")  

        for m = 0,numberOfMeasures
        do
          local projectTimeQN = reaper.TimeMap_QNToTime(m) 
          local measure = GetMeasureInformation(selectedTrack,m,nil,logFile) -- populate the measures table
          if(measure) then
            measures[m] = measure
            logFile:write("Measure: " .. m .. " Start: " ..  measure["start_ppq"] .. " QN:" .. startOfMeasureQN ..  " End: ".. measure["end_ppq"] .. " QN:" .. endOfMeasureQN .. " Project Time from QN: " .. projectTimeQN ..  "\n")
          end
        end 
      end
    else  
      reaper.ShowConsoleMsg("You must select a media item")
    end
  end  


  logFile:write(" \n")
  take = reaper.GetMediaItemTake(media_item, 0)
  logFile:write("Notes in Measure: " .. 0 .. " \n")
  -- for retval, selected, muted, notestartppqpos, noteendppqpos, chan, pitch, vel in IterateMIDINotesInMeasure(measures,take, 0) do
  if(measures[0]) then
    for retval, selected, muted, notestartppqpos, noteendppqpos, chan, pitch, vel in IterateMIDINotesInMeasure(measures[0],take, 0) do
        if(retval) then
            logFile:write("Measures: 0, pitch=" .. pitch ..  " note start:" .. notestartppqpos ..  " note end:" .. noteendppqpos .. "\n")
        end
    end  
  end
  logFile:write("\n")
  if selectedTrack then
    if take then
      -- reaper.ShowConsoleMsg("Take Found")
      reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.
      LogTakeData(logFile, take ) -- Execute your main function
      reaper.Undo_EndBlock("Phase Shirt duplicate track", 0) -- End of the undo block. Leave it at the bottom of your main function.      
      reaper.UpdateArrange() -- Update the arrangement (often needed)
    else
      reaper.ShowConsoleMsg("No Take Found")
    end -- ENDIF Take 
  end
  io.close(logFile)

end


main()
