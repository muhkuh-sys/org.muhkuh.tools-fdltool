local __APPLICATION__ = 'fdltool'
local __VERSION__ = '1.0.0'

local FDL = require 'fdl'
local argparse = require 'argparse'
local dkjson = require 'dkjson'
local pl = require'pl.import_into'()

local atLogLevels = {
  ['debug'] = 'debug',
  ['info'] = 'info',
  ['warning'] = 'warning',
  ['error'] = 'error',
  ['fatal'] = 'fatal'
}
local atFileInputTypes = {
  ['BIN'] = 'BIN',
  ['JSON'] = 'JSON'
}
local atFileInputKeys = pl.tablex.keys(atFileInputTypes)
table.sort(atFileInputKeys)
local atFileOutputTypes = {
  ['BIN'] = 'BIN',
  ['JSON'] = 'JSON',
  ['TXT'] = 'TXT'
}
local atFileOutputKeys = pl.tablex.keys(atFileOutputTypes)
table.sort(atFileOutputKeys)


local tParser = argparse(__APPLICATION__, 'Decode, patch and convert FDLs.')
tParser:flag('--version')
  :description('Show the version and exit.')
  :action(function()
    print(string.format('%s %s', __APPLICATION__, __VERSION__))
    print('Copyright (C) 2020 by Christoph Thelen (doc_bacardi@users.sourceforge.net)')
    os.exit(0)
  end)
tParser:argument('input')
  :argname('<IN_FILE>')
  :description('Read the input data from IN_FILE.')
  :target('strInputFile')
tParser:argument('output')
  :argname('<OUT_FILE>')
  :description('Write the output data to OUT_FILE.')
  :target('strOutputFile')
  :args('?')
tParser:option('-p --patch')
  :description('Patch the input data with values from the JSON file PATCH_FILE.')
  :argname('<PATCH_FILE>')
  :default(nil)
  :target('strPatchFile')
tParser:option('--input-type')
  :description(string.format('Do not guess the type of the input file but set it to IN_TYPE. Possible values for IN_TYPE are %s.', table.concat(atFileInputKeys, ', ')))
  :argname('<IN_TYPE>')
  :convert(atFileInputTypes)
  :default(nil)
  :target('strInputType')
tParser:option('--output-type')
  :description(string.format('Do not guess the type of the output file but set it to OUT_TYPE. Possible values for OUT_TYPE are %s.', table.concat(atFileOutputKeys, ', ')))
  :argname('<OUT_TYPE>')
  :convert(atFileOutputTypes)
  :default(nil)
  :target('strOutputType')
tParser:option('-v --verbose')
  :description(string.format('Set the verbosity level to LEVEL. Possible values for LEVEL are %s.', table.concat(pl.tablex.keys(atLogLevels), ', ')))
  :argname('<LEVEL>')
  :convert(atLogLevels)
  :default('warning')
  :target('strLogLevel')
tParser:option('-s --skip-input')
  :description('Skip the first SKIP bytes when reading a binary input. The default is to skip no bytes.')
  :argname('<SKIP>')
  :convert(tonumber)
  :default(0)
  :target('ulSkip')
tParser:option('-l --logfile')
  :description('Write all output to FILE.')
  :argname('<FILE>')
  :default(nil)
  :target('strLogFileName')
tParser:mutex(
  tParser:flag('--color')
    :description('Use colors to beautify the console output. This is the default on Linux.')
    :action("store_true")
    :target('fUseColor'),
  tParser:flag('--no-color')
    :description('Do not use colors for the console output. This is the default on Windows.')
    :action("store_false")
    :target('fUseColor')
)
local tArgs = tParser:parse()

-----------------------------------------------------------------------------
--
-- Create a log writer.
--
  
local fUseColor = tArgs.fUseColor
if fUseColor==nil then
  if pl.path.is_windows==true then
    -- Running on windows. Do not use colors by default as cmd.exe
    -- does not support ANSI on all windows versions.
    fUseColor = false
  else
    -- Running on Linux. Use colors by default.
    fUseColor = true
  end
end

-- Collect all log writers.
local atLogWriters = {}

-- Create the console logger.
local tLogWriterConsole
if fUseColor==true then
  tLogWriterConsole = require 'log.writer.console.color'.new()
else
  tLogWriterConsole = require 'log.writer.console'.new()
end
table.insert(atLogWriters, tLogWriterConsole)

-- Create the file logger if requested.
local tLogWriterFile
if tArgs.strLogFileName~=nil then
  tLogWriterFile = require 'log.writer.file'.new{ log_name=tArgs.strLogFileName }
  table.insert(atLogWriters, tLogWriterFile)
end

-- Combine all writers.
if LUA_VER_NUM==501 then
  tLogWriter = require 'log.writer.list'.new(unpack(atLogWriters))
else
  tLogWriter = require 'log.writer.list'.new(table.unpack(atLogWriters))
end

-- Set the logger level from the command line options.
local cLogWriter = require 'log.writer.filter'.new(tArgs.strLogLevel, tLogWriter)
local tLog = require "log".new(
  -- maximum log level
  "trace",
  cLogWriter,
  -- Formatter
  require "log.formatter.format".new()
)


------------------------------------------------------------------------------
--
-- Guess the input and output types if they are not fixed.
-- This is rather simple: if the file suffix is ".json" then the type is
-- "JSON". Otherwise it is "BIN".
-- For the output there is the additional "TXT" format. It is used by default
-- if no output file is specified. For a file, the ending is used. A suffix
-- of '.json' results in "JSON" type, a ".txt" ending gives a "TXT" type. All
-- other endings produce binary output-
--
local strInputType = tArgs.strInputType
if strInputType==nil then
  tLog.debug('Guessing the type of the input file based on the file name "%s".', tArgs.strInputFile)
  local strSuffix = pl.path.extension(tArgs.strInputFile)
  if strSuffix=='.json' then
    strInputType = 'JSON'
  else
    strInputType = 'BIN'
  end
  tLog.debug('  Guessed file type "%s".', strInputType)
end
local strOutputType = tArgs.strOutputType
if tArgs.strOutputFile==nil then
  strOutputType = 'TXT'
elseif strOutputType==nil then
  tLog.debug('Guessing the type of the output file based on the file name "%s".', tArgs.strOutputFile)
  local strSuffix = pl.path.extension(tArgs.strOutputFile)
  if strSuffix=='.json' then
    strOutputType = 'JSON'
  elseif strSuffix=='.txt' then
    strOutputType = 'TXT'
  else
    strOutputType = 'BIN'
  end
  tLog.debug('  Guessed file type "%s".', strOutputType)
end



local tFDL = FDL(tLog)

------------------------------------------------------------------------------
--
-- Read the input file.
--
local tFdlData
tLog.info('Reading "%s".', tArgs.strInputFile)
if strInputType=='BIN' then
  local tFile, strError = io.open(tArgs.strInputFile, 'rb')
  if tFile==nil then
    tLog.error('Failed to read the input file from "%s": %s', tArgs.strInputFile, strError)
    error('Failed to read the input file.')
  end
  if tArgs.ulSkip>0 then
    local tResult, strError = tFile:seek('set', tArgs.ulSkip)
    if tResult==nil then
      tLog.error('Failed to seek the input file "%s" to offset %d: %s', tArgs.strInputFile, tArgs.ulSkip, strError)
      error('Failed to seek the input file.')
    end
  end
  local strInputData = tFile:read(tFDL.sizBinaryFdlMaxInBytes)
  if strInputData==nil then
    tLog.error('Failed to read the input file "%s".', tArgs.strInputFile)
    error('Failed to read the input file.')
  end
  tFile:close()

  -- Parse the input.
  tFdlData = tFDL:bin2fdl(strInputData)

else
  -- Read the complete file.
  local strInputData, strError = pl.utils.readfile(tArgs.strInputFile, false)
  if strInputData==nil then
    tLog.error('Failed to read the input file "%s": %s.', tArgs.strInputFile, strError)
    error('Failed to read the input file.')
  end

  -- Parse the input.
  tFdlData = tFDL:json2fdl(strInputData)
end


------------------------------------------------------------------------------
--
-- Do something with the data...
--
if tArgs.strPatchFile~=nil then
  tLog.info('Patching with "%s"...', tArgs.strPatchFile)

  -- Read the complete file.
  local strPatchData, strError = pl.utils.readfile(tArgs.strPatchFile, false)
  if strPatchData==nil then
    tLog.error('Failed to read the patch file "%s": %s.', tArgs.strPatchFile, tostring(strError))
    error('Failed to read the patch file.')
  end

  -- Convert the JSON data to a table.
  local tPatchData, strError = dkjson.decode(strPatchData)
  if tPatchData==nil then
    tLog.error('Failed to parse the JSON data: %s', strError)
    error('Patch file is no valid JSON.')
  end

  tFDL:patchFdl(tFdlData, tPatchData)
end


------------------------------------------------------------------------------
--
-- Write the data to the selected output.
--
local strOutputData
if strOutputType=='BIN' then
  strOutputData = tFDL:fdl2bin(tFdlData)

elseif strOutputType=='JSON' then
  strOutputData = tFDL:fdl2json(tFdlData)

else
  strOutputData = tFDL:fdl2prettyPrint(tFdlData)
end

if tArgs.strOutputFile==nil then
  print(strOutputData)

else
  tLog.info('Writing "%s".', tArgs.strOutputFile)
  if strOutputType=='BIN' then
    local tFile = io.open(tArgs.strOutputFile, 'wb')
    tFile:write(strOutputData)
    tFile:close()

  else
    local tFile = io.open(tArgs.strOutputFile, 'w')
    tFile:write(strOutputData)
    tFile:close()
  end
end
