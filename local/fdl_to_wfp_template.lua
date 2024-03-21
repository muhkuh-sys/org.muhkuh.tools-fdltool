local FDL = require 'fdl'
local argparse = require 'argparse'
local pl = require'pl.import_into'()

local tParser = argparse('fdl_to_wfp_template', 'Generate a WFP template from an existing FDL.')
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


local atKnownChipOffsets = {
  [0] = { ulOffset=0x00100000, strBus='IFlash', uiUnit=3, uiChipSelect=0 },
  [1] = { ulOffset=0x00100000, strBus='IFlash', uiUnit=3, uiChipSelect=0 },
  [2] = { ulOffset=0x64000000, strBus='Spi', uiUnit=0, uiChipSelect=0 }
}


local atKnownFlashAreas = {
  ['HWConfig']     = { isErase = false, strFile = '*.hwc' },
  ['FDL']          = { isErase = false, strFile = '*.fdl' },
  ['FW']           = { isErase = false, strFile = '*.nxi' },
  ['HWConfig_MFW'] = { isErase = false, strFile = '*.mwc' },
  ['MFW_HWConfig'] = { isErase = false, strFile = '*.mwc' },
  ['Maintenance']  = { isErase = false, strFile = '*.mxf' },
  ['FWcont']       = { isErase = false, strFile = '*.nxe' },
  ['Filesystem']   = { isErase = false, strFile = 'filesystem*.bin' },
  ['Remanent']     = { isErase = true },
  ['Management']   = { isErase = true },
  ['APPcont']      = { isErase = false, strFile = '*.nae' },
  ['FWUpdate']     = { isErase = false },
}


local atFlashElements = {}

for uiCnt, tArea in ipairs(tFDLContents.tFlashLayout.atArea) do
  -- Get the area name.
  local strAreaName = tArea.aucAreaName
  -- Cut off trailing NUL bytes.
  while string.byte(strAreaName, -1)==0 do
    strAreaName = string.sub(strAreaName, 1, -2)
  end

  if string.len(strAreaName)==0 then
    print(string.format('Skipping empty area %d.', uiCnt))
  else
    print(string.format('Found area %d: %s', uiCnt, strAreaName))
    local tAttr = atKnownFlashAreas[strAreaName]
    if tAttr==nil then
      error(string.format('Unknown area %d: %s', uiCnt, strAreaName))
    else
      -- Get the chip attributes.
      local strChipID = tArea.ulChipNumber
      local tChip = atKnownChipOffsets[strChipID]
      if tChip==nil then
        error(string.format('Error in area %d: unknown chip ID %s', uiCnt, sstrChipID))
      else
        local ulOffset = tArea.ulAreaStartAddress - tChip.ulOffset
        local strFlash = string.format('bus="%s" unit="%d" chip_select="%d"', tChip.strBus, tChip.uiUnit, tChip.uiChipSelect)

        if strAreaName=='FDL' then
          if strChipID~=0 or ulOffset~=0x002000 then
            error(string.format('The FDL must be in INTFLASH0 at offset 0x2000. Here it is in %s at offset 0x%06x.', tChip.strBus, ulOffset))
          end
        else
          local tFlash
          local tErase
          for _, tFlashCnt in ipairs(atFlashElements) do
            if tFlashCnt.strFlash==strFlash then
              tFlash = tFlashCnt.tFlash
              tErase = tFlashCnt.tErase
              break
            end
          end
          if tFlash==nil then
            tFlash = {}
            tErase = {}
            table.insert(atFlashElements, {['strFlash']=strFlash, ['tFlash']=tFlash, ['tErase']=tErase})
          end

          if tAttr.isErase==true then
            table.insert(tErase, string.format('offset="0x%06x" size="0x%06x"', ulOffset, tArea.ulAreaSize))
          else
            table.insert(tFlash, string.format('file="%s" offset="0x%06x"', tAttr.strFile, ulOffset))
          end
        end
      end
    end
  end
end

-- "NAI" has no entry in the area table.
table.insert(atFlashElements, {
  ['strFlash'] = 'bus="IFlash" unit="2" chip_select="0"',
  ['tFlash'] = {
    'file="*.nai" offset="0x000000"'
  },
  ['tErase'] = {}
})

-- Dump all data.
print('')
print('------8<------8<------8<------8<-----snip-----8<------8<------8<------8<------')
print('')
print('<FlasherPackage version="1.0.0">')
print('\t<Target netx="NETX90">')
for _, tFlash in ipairs(atFlashElements) do
  print(string.format('\t\t<Flash %s>', tFlash.strFlash))
  for _, strData in ipairs(tFlash.tFlash) do
    print(string.format('\t\t\t<Data %s/>', strData))
  end
  for _, strData in ipairs(tFlash.tErase) do
    print(string.format('\t\t\t<Erase %s/>', strData))
  end
  print('\t\t</Flash>')
end
print('\t</Target>')
print('</FlasherPackage>')
print('')
print('------>8------>8------>8------>8----snap------>8------>8------>8------>8------')
print('')
