

-- Truncate a number to the given number of places

function trunc(num, digits)
    local mult = 10^(digits)
    return math.modf(num*mult)/mult
  end
  


  -- Get the number of measures in a given media item

  function GetNumberOfMeasures(media_item)
    if(media_item) then
      local beatsPerMinute,timeSignatureNumerator, timeSignatureDenominator = getTempoTimeSignatureForItem(media_item)
      local projectLength = reaper.GetProjectLength(0)
      local measureLengthSeconds =((60/beatsPerMinute) * timeSignatureDenominator)
      numberOfMeasures = trunc(projectLength/measureLengthSeconds,0)
      return numberOfMeasures
    else  
      reaper.ShowConsoleMsg("GetNumberOfMeasures: Invalid or empty media item")
      return nil
    end
  
  end


    -- Get the number of Quarter Notes per measure in a given media item
    ---@param item, the items which contains the measures
    ---@return the number of quarter notes
  function GetQNPerMeasure(item)
    local beatsPerMinute,timeSignatureNumerator, timeSignatureDenominator = getTempoTimeSignatureForItem(item)
    if(beatsPerMinute) then
      return ((4/timeSignatureDenominator) * timeSignatureNumerator)
    else  
      return nil
    end  
  end

  -- Given a ppq for a particular take, find the containing measure
  function FindMeasurePPQ(take, ppq)
    local startppqMeasure = reaper.MIDI_GetPPQPos_StartOfMeasure(take, ppq) + 1 -- returns the Midi tick position associated with the start of the measure
    local measure = startppqMeasure/(PPQ * 4)
    return  math.floor(measure + 0.5)
  end

-- Given a QN for a particular project, find the containing measure's start and end position for a given quarter note position
function FindMeasureQNPositions(project, qn)
      local retval,startQNMeasure,endQNMeasure = reaper.TimeMap_QNToMeasures(project, qn) -- returns the QN start and end of the measure
      return  startQNMeasure,endQNMeasure
end


-- Given a QN for a particular project, find the measure in which the qn starts as an index where 0 is the first measure
function FindMeasureNumberForQN(project, qn, item)
  local retval,startQNMeasure,endQNMeasure = reaper.TimeMap_QNToMeasures(project, qn) -- returns the QN start and end of the measure
  qnPerMeasure = GetQNPerMeasure(item)
  return startQNMeasure/qnPerMeasure    
end

-- returns the bpm, timesig_num and timesig_denom for a given item
function getTempoTimeSignatureForItem(item)
    if(item) then
      local itemLen = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")  -- The item length in seconds
      local itemPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")  -- The item position in seconds
      local tempoID =  reaper.FindTempoTimeSigMarker( 0, itemPos ) -- Find the Time Signature and Tempo marker for this position
      if (tempoID == -1) then
        warning = "No time signature marker found, go to the Insert menu and select Tempo/time signature change marker\n" 
        reaper.ShowConsoleMsg(warning)
        logFile:write(warning )
        return nil
      else  
        retval, pos, measure_pos, beat_pos, bpm, timesig_num, timesig_denom, lineartempoOut = reaper.GetTempoTimeSigMarker(0, tempoID)  -- Retrieve the time signature and tempo data
        if(retval) then
          return bpm, timesig_num, timesig_denom
        else
          return nil
        end
      end  
    else  
      warning = "getTempoTimeSignatureForItem: not a valid item\n" 
      reaper.ShowConsoleMsg(warning)
      return nil
    end
  end  
  
--- checks if a given track has items in the given measure, if it has it then returns the measure start, measure end in both time and quarter notes
---@param track, the given track containing the item
---@param measure, an index into the desired measure
---@return returns the measure start, measure end in both time and quarter notes
  function HasItemsInMeasure(track, measure)
    local retval_0, measure_start_pos, qn_end_0 = reaper.TimeMap_GetMeasureInfo(0, measure) 
    local retval_1, measure_end_pos, qn_end_1 = reaper.TimeMap_GetMeasureInfo(0, measure + 1)
    for i = 0, reaper.CountTrackMediaItems(track) - 1 do
        local item = reaper.GetTrackMediaItem(track, i)
        local item_length = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
        local item_start_pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
        local item_end_pos = item_start_pos + item_length
        if item_start_pos > measure_end_pos then break end
        if item_start_pos <= measure_end_pos and item_end_pos >= measure_start_pos then
          local firstTake = reaper.GetMediaItemTake(item, 0)
          measure_start_pos_qn = reaper.MIDI_GetPPQPosFromProjQN(firstTake, measure_start_pos)
          measure_end_pos_qn = reaper.MIDI_GetPPQPosFromProjQN(firstTake, measure_end_pos)
            return true,measure_start_pos,measure_end_pos,measure_start_pos_qn,measure_end_pos_qn
        end
    end
  end


  --- iterate all notes in the given take
  ---@param take, the given take containing the notes
  ---@return function, the note properties; retval, selected, muted, notestartppqpos, noteendppqpos, chan, pitch, velretval, selected, muted, notestartppqpos, noteendppqpos, chan, pitch, vel
  function IterateMIDINotes(take)
    local retval, notecnt, ccevtcnt, textsyxevtcnt = reaper.MIDI_CountEvts(take)
    local noteidx = -1
    return function ()
        noteidx = noteidx + 1
        local retval, selected, muted, notestartppqpos, noteendppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, noteidx)
        if retval then 
            return retval, selected, muted, notestartppqpos, noteendppqpos, chan, pitch, vel
        else
            return nil
        end        
    end    
  end
 
  ---Get MediaTrack by name if it exists. Return false if it dont find. From original code by Daniel Lumertz
---@param proj number Project number or project.
---@param name string Track name to find.
function GetTrackByName(proj,name)
    local track_cnt = reaper.CountTracks(proj)
    for i = 0, track_cnt-1 do
        local loop_track = reaper.GetTrack(proj, i)
        local bol, loop_name = reaper.GetTrackName(loop_track)
        if loop_name == name then
            return loop_track
        end
    end
    return false
end


--- Created a generated track
function CreateGeneratedTrack(generated_track_name)
  --Get Generated Track

  local generated_track = GetTrackByName(0,generated_track_name)
  if not generated_track then
      local track_cnt = reaper.CountTracks(0)
      reaper.InsertTrackAtIndex(track_cnt, true)
      generated_track = reaper.GetTrack(0,track_cnt)
      reaper.GetSetMediaTrackInfo_String(generated_track, 'P_NAME', generated_track_name, true) -- rename track
  end
  return generated_track
end


--- Creates a midi item on the given track at the given start and end positions, returns the take associated with that item
---@param track, the track on which to create the item
---@param itemStartPosition , Position at which the item starts
---@param itemEndPosition , Position at which the item ends
function CreateMidiItemForTrack(track,itemStartPosition,itemEndPosition)
    -- create MIDI Item
  local genItem = reaper.CreateNewMIDIItemInProj(track,itemStartPosition,itemEndPosition,false) -- false = do not use QN time
  local genTake = reaper.GetActiveTake(genItem)
  return genTake
end


--- Returns the requested take for a given media item in a given track
---@param track, the track for which we require the take
---@param itemIndex , the item index in the track
---@param takeIndex , the take index in the item
function GetTakeFromTrack(track,itemIndex,takeIndex)
  mediaItem = reaper.GetTrackMediaItem(track, itemIndex)
  if(mediaItem) then
      local take = reaper.GetMediaItemTake(mediaItem, takeIndex)
      return take
  else    
      return nil
  end
end

-- Given a measure this function creates an additve pattern based on that measure
  function CreateAdditiveMeasure()
 
    
  end

    --- Returns retval, selected, muted, notestartppqpos, noteendppqpos, chan, pitch, vel for each note in a measure
    ---@param measure, the measure object we will iterate
    ---@param take, the take that contains this measure
function IterateMIDINotesInMeasure(measure,take)
    local retval, notecnt, ccevtcnt, textsyxevtcnt = reaper.MIDI_CountEvts(take)
    local noteidx = -1
    return function ()
        noteidx = noteidx + 1
        local retval, selected, muted, notestartppqpos, noteendppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, noteidx)
        if notestartppqpos >= measure["start_ppq"] and  noteendppqpos <= measure["end_ppq"] then 
            return retval, selected, muted, notestartppqpos, noteendppqpos, chan, pitch, vel
        else
            return nil
        end        
    end    
  end

  
  function Msg (param)
    reaper.ShowConsoleMsg(tostring (param).."\n")
  end

  -- Log all of the data for a given media item to the given log file
  
  function LogTakeData( log, take )
    local item = reaper.GetSelectedMediaItem(0,0)
    local bpm,timesig_num, timesig_denom = getTempoTimeSignatureForItem(item)
    if(bmp) then
      proj_QN=reaper.TimeMap2_timeToQN(0, pos)
      ppq=reaper.MIDI_GetPPQPosFromProjQN(take,proj_QN)
      local bpmStr = tostring(bpm) 
      local ticksPerMinute = PPQ * bpm
      local ticksPerSecond = ticksPerMinute/60
      local ticksPerMicroSecond = ticksPerMinute/60000
      local ticksPerBeat = PPQ
      local ticksInOneSecond = trunc(1/ticksPerMicroSecond,2)
      log:write("Tempo: " .. bpmStr  .. " bpm, Time Signature: " .. timesig_num .. "/" .. timesig_denom .. " Ticks Per Minute: " .. ticksPerMinute .. " Ticks Per Second: " .. ticksPerSecond .. " Ticks Per Micro Second: " .. ticksPerMicroSecond .. " Ticks Per Beat: " .. ticksPerBeat .. " Ticks in 1 Second: " .. ticksInOneSecond .. "\n")
      retval, qn_start, qn_end,  timesig_num,  timesig_denom,  tempo = reaper.TimeMap_GetMeasureInfo(0, 1)
    end
  -- GET SELECTED NOTES (from 0 index)
    retval, notes, ccs, sysex = reaper.MIDI_CountEvts( take )
    for index = 0, notes - 1 do          
      local retval, sel, muted, notestartppq, noteendppq, chan, pitch, vel = reaper.MIDI_GetNote( take, index )
      local noteDuration = noteendppq - notestartppq
      noteIndex = index + 1
      local projectTimeSecondsNoteStart = trunc(reaper.MIDI_GetProjTimeFromPPQPos(take, notestartppq),2)
      local projectTimeSecondsNoteEnd = trunc(reaper.MIDI_GetProjTimeFromPPQPos(take, noteendppq),2)
      local NoteQNTimeStart = trunc(reaper.MIDI_GetProjQNFromPPQPos(take, notestartppq),2)
      local NoteQNTimeEnd = trunc(reaper.MIDI_GetProjQNFromPPQPos(take, noteendppq),2)
      local startppqMeasure = trunc(reaper.MIDI_GetPPQPos_StartOfMeasure(take, notestartppq),2)
      local endppqMeasure = trunc(reaper.MIDI_GetPPQPos_EndOfMeasure(take, noteendppq),2)
     
      local measure = FindMeasurePPQ(take, notestartppq)
      local measureQNStart = FindMeasureQNPositions(0, NoteQNTimeStart)
      measureQN = FindMeasureNumberForQN(0, NoteQNTimeStart, item)
      log:write("" .. noteIndex .. " Note Start PPQ: " .. notestartppq .. " Note End PPQ: " .. noteendppq .. " duration(ppq): " .. noteDuration .. " Project Time in SecondsNote Start: " .. projectTimeSecondsNoteStart .. " Project Time in Seconds NoteEnd: " .. projectTimeSecondsNoteEnd .. " Note QN Time Start: " .. NoteQNTimeStart .. " Note QN Time End: " .. NoteQNTimeEnd .. " Measure Start PPQ: " .. startppqMeasure .. " Measure End PPQ: " .. endppqMeasure ..  " Measure: " .. measure .. " Measure QN Start: " .. measureQN .. " Measure QN: " .. measureQN .. "\n")
    end
  end



--- Gets the Measure details for a given measure in a given track
---@param selectedTrack, the given track containing the measure
---@param measureIndex, an index into the desired measure
---@param log, the desired log if logging is required
---@return returns the measure object
function GetMeasureInformation(selectedTrack,measureIndex,log)
    timePosition = reaper.TimeMap2_QNToTime(0, measureIndex)
    retval,startOfMeasureQN,endOfMeasureQN,startOfMeasurePPQ,endOfMeasurePPQ = HasItemsInMeasure(selectedTrack,measureIndex) 
    if(retval) then
        local projectTimeQN = reaper.TimeMap_QNToTime(measureIndex)
        local measure = {}
        measure["start_qn"] = startOfMeasureQN
        measure["end_qn"]  = endOfMeasureQN
        measure["start_ppq"] = startOfMeasurePPQ
        measure["end_ppq"]  = endOfMeasurePPQ
        if(log) then
          log:write("Measure: " .. measureIndex .. " Pos: " .. timePosition .. " Start: " ..  measure["start_ppq"] .. " QN:" .. startOfMeasureQN ..  " End: ".. measure["end_ppq"] .. " QN:" .. endOfMeasureQN .. " Project Time from QN: " .. projectTimeQN ..  "\n")
        end  
        return measure
    else    
        Msg("No measure information found for measure : " .. measureIndex )
        return nil
    end    
end


function Print(...) 
  local t = {}
  for i, v in ipairs( { ... } ) do
    t[i] = tostring( v )
  end
  reaper.ShowConsoleMsg( table.concat( t, "\n" ) .. "\n" )
end

function TablePrint (tbl, indent)
  if not indent then indent = 0 end
  for k, v in pairs(tbl) do
    formatting = string.rep("  ", indent) .. tostring(k) .. ": "
    if type(v) == "table" then
      Print(formatting)
      TablePrint(v, indent+1)
    elseif type(v) == 'boolean' then
      Print(formatting .. tostring(v))      
    else
      Print(formatting .. tostring(v))
    end
  end
end
