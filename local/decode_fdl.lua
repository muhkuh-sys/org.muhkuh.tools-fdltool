function hexdump(strData, uiBytesPerRow)
  local uiCnt
  local aDump

  uiBytesPerRow = uiBytesPerRow or 16

  local uiByteCnt = 0
  for uiCnt=1,strData:len() do
    if uiByteCnt==0 then
      aDump = { string.format("%08X :", uiCnt-1) }
    end
    table.insert(aDump, string.format(" %02X", strData:byte(uiCnt)))
    uiByteCnt = uiByteCnt + 1
    if uiByteCnt==uiBytesPerRow then
      uiByteCnt = 0
      print(table.concat(aDump))
    end
  end
  if uiByteCnt~=0 then
    print(table.concat(aDump))
  end
end



local FDL = require 'fdl'
local argparse = require 'argparse'
local pl = require'pl.import_into'()

local tParser = argparse('decode_fdl', 'Show the contents of an FDL.')
tParser:argument('file', 'Read the FDL from file FILE.')
  :argname('<FILE>')
  :target('strFile')
local tArgs = tParser:parse()

-- Read the flash device label.
local tFile = io.open(tArgs.strFile, 'rb')
local strFDL = tFile:read('*a')
tFile:close()

local tFDL = FDL()
local tFDLContents = tFDL:bin2fdl(strFDL)
if tFDLContents==nil then
  error('Failed to parse the FDL.')
end

--pl.pretty.dump(tFDLContents)
print('atMacCOM')
pl.pretty.dump(tFDLContents.atMacCOM)
print('tBasicDeviceData')
pl.pretty.dump(tFDLContents.tBasicDeviceData)
print('atMacAPP')
pl.pretty.dump(tFDLContents.atMacAPP)
print('tFlashLayout')
pl.pretty.dump(tFDLContents.tFlashLayout)
print('atChip')
pl.pretty.dump(tFDLContents.atChip)
print('tOEMIdentification')
pl.pretty.dump(tFDLContents.tOEMIdentification)
print('tProductIdentification')
pl.pretty.dump(tFDLContents.tProductIdentification)


hexdump(tFDLContents.atMacCOM[1].aucMAC)
hexdump(tFDLContents.atMacCOM[2].aucMAC)
hexdump(tFDLContents.atMacCOM[3].aucMAC)
hexdump(tFDLContents.atMacCOM[4].aucMAC)
hexdump(tFDLContents.atMacCOM[5].aucMAC)
hexdump(tFDLContents.atMacCOM[6].aucMAC)
hexdump(tFDLContents.atMacCOM[7].aucMAC)
hexdump(tFDLContents.atMacCOM[8].aucMAC)
