

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

  -- Given a ppq for a particular take, find the containing measure
  function FindMeasure(take, ppq)
    local startppqMeasure = reaper.MIDI_GetPPQPos_StartOfMeasure(take, ppq) + 1
    local measure = startppqMeasure/(PPQ * 4)
    return  math.floor(measure + 0.5)
  end

-- returns the bpm, timesig_num and timesig_denom for a given item
function getTempoTimeSignatureForItem(item)
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
  end  
  
  -- checks if a given track has items in the given measure, if it has it then returns the measure start, measure end in noth time and quarter notes
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


  -- iterate all notes in the given take
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
 


    -- Returns retval, selected, muted, notestartppqpos, noteendppqpos, chan, pitch, vel for each note in a measure
function IterateMIDINotesInMeasure(measure,take, measureIndex)
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
      local projectTimeStart = trunc(reaper.MIDI_GetProjTimeFromPPQPos(take, notestartppq),2)
      local projectTimeEnd = trunc(reaper.MIDI_GetProjTimeFromPPQPos(take, noteendppq),2)
      local projectTimeQNStart = trunc(reaper.MIDI_GetProjQNFromPPQPos(take, notestartppq),2)
      local projectTimeQNEnd = trunc(reaper.MIDI_GetProjQNFromPPQPos(take, noteendppq),2)
      local startppqMeasure = trunc(reaper.MIDI_GetPPQPos_StartOfMeasure(take, notestartppq),2)
      local endppqMeasure = trunc(reaper.MIDI_GetPPQPos_EndOfMeasure(take, noteendppq),2)
     
      local measure = FindMeasure(take, notestartppq)
      log:write("" .. noteIndex .. " Start: " .. notestartppq .. " End: " .. noteendppq .. " duration: " .. noteDuration .. " projectTimeStart: " .. projectTimeStart .. " projectTimeEnd: " .. projectTimeEnd .. " projectTimeQNStart: " .. projectTimeQNStart .. " projectTimeQNEnd: " .. projectTimeQNEnd .. " Measure Start PPQ: " .. startppqMeasure .. " Measure End PPQ: " .. endppqMeasure ..  " Measure: " .. measure .. "\n")
    end
  end



-- Gets the Measure details for a given measure in a given track
-- The global measures table is updated
-- If logging is enabled we log the infomation
function GetMeasureInformation(selectedTrack,measureIndex,logging,log)
    timePosition = reaper.TimeMap2_QNToTime(0, measureIndex)
    retval,startOfMeasureQN,endOfMeasureQN,startOfMeasurePPQ,endOfMeasurePPQ = HasItemsInMeasure(selectedTrack,measureIndex) 
    if(retval) then
        local projectTimeQN = reaper.TimeMap_QNToTime(measureIndex)
        local measure = {}
        measure["start_qn"] = startOfMeasureQN
        measure["end_qn"]  = endOfMeasureQN
        measure["start_ppq"] = startOfMeasurePPQ
        measure["end_ppq"]  = endOfMeasurePPQ
        if(logging) then
          log:write("Measure: " .. measureIndex .. " Pos: " .. timePosition .. " Start: " ..  measure["start_ppq"] .. " QN:" .. startOfMeasureQN ..  " End: ".. measure["end_ppq"] .. " QN:" .. endOfMeasureQN .. " Project Time from QN: " .. projectTimeQN ..  "\n")
        end  
        return measure
    else    
        Msg("No measure information found for measure : " .. measureIndex )
        return nil
    end    
end
