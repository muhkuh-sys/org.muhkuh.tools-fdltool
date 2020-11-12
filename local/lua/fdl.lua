local class = require 'pl.class'
local FDL = class()

function FDL:_init()
  local vstruct = require "vstruct"
  self.pl = require'pl.import_into'()
  self.template = require 'pl.template'
  self.mhash = require 'mhash'

  self.tStructureFdlHeader = vstruct.compile([[
    abStartToken:s12
    usLabelSize:u2
    usContentSize:u2
  ]])
  self.sizHeader = 16

  self.tStructureFdlContents = vstruct.compile([[
    tBasicDeviceData:{
      usManufacturerID:u2
      usDeviceClassificationNumber:u2
      ulDeviceNumber:u4
      ulSerialNumber:u4
      ucHardwareCompatibilityNumber:u1
      ucHardwareRevisionNumber:u1
      usProductionDate:u2
      ucReserved1:u1
      ucReserved2:u1
      aucReservedFields:s14
    }
    atMacCOM:{
      8*{
        aucMAC:s6
        aucReserved:s2
      }
    }
    atMacAPP:{
      4*{
        aucMAC:s6
        aucReserved:s2
      }
    }
    tProductIdentification:{
      usUSBVendorID:u2
      usUSBProductID:u2
      aucUSBVendorName:s16
      aucUSBProductName:s16
      aucReservedFields:s76
    }
    tOEMIdentification:{
      ulOEMDataOptionFlags:u4
      aucOEMSerialNumber:s28
      aucOEMOrderNumber:s32
      aucOEMHardwareRevision:s16
      aucOEMProductionDateTime:s32
      aucOEMReservedFields:s12
      aucOEMSpecificData:s112
    }
    tFlashLayout:{
      atArea:{
        10*{
          ulAreaContentType:u4
          ulAreaStartAddress:u4
          ulAreaSize:u4
          ulChipNumber:u4
          aucAreaName:s16
          ucAreaAccessType:u1
          aucReserved:s3
        }
      }
      atChip:{
        4*{
          ulChipNumber:u4
          aucFlashDriverName:s16
          ulBlockSize:u4
          ulFlashSize:u4
          ulMaxEraseWriteCycles:u4
        }
      }
    }
  ]])

  self.tStructureFdlFooter = vstruct.compile([[
    ulChecksum:u4
    aucEndLabel:s12
  ]])
  self.sizFooter = 16

  self.strPrettyPrint = [[
  tBasicDeviceData
    usManufacturerID:              $(string.format('%d', data.tBasicDeviceData.usManufacturerID))
    usDeviceClassificationNumber:  $(string.format('%d', data.tBasicDeviceData.usDeviceClassificationNumber))
    ulDeviceNumber:                $(string.format('%d', data.tBasicDeviceData.ulDeviceNumber))
    ulSerialNumber:                $(string.format('%d', data.tBasicDeviceData.ulSerialNumber))
    ucHardwareCompatibilityNumber: $(string.format('%d', data.tBasicDeviceData.ucHardwareCompatibilityNumber))
    ucHardwareRevisionNumber:      $(string.format('%d', data.tBasicDeviceData.ucHardwareRevisionNumber))
    usProductionDate:              $(string.format('0x%04x', data.tBasicDeviceData.usProductionDate))
    ucReserved1:                   $(string.format('0x%02x', data.tBasicDeviceData.ucReserved1))
    ucReserved2:                   $(string.format('0x%0x2', data.tBasicDeviceData.ucReserved2))
    aucReservedFields:             [$(hexdump(data.tBasicDeviceData.aucReservedFields))]

  atMacCOM
# for uiCnt, tMac in ipairs(data.atMacCOM) do
    aucMAC[$(string.format('%d', uiCnt))]:      $(macdump(tMac.aucMAC))
    aucReserved[$(string.format('%d', uiCnt))]: [$(hexdump(tMac.aucReserved))]
# end

  atMacAPP
# for uiCnt, tMac in ipairs(data.atMacAPP) do
    aucMAC[$(string.format('%d', uiCnt))]:      $(macdump(tMac.aucMAC))
    aucReserved[$(string.format('%d', uiCnt))]: [$(hexdump(tMac.aucReserved))]
# end

  tProductIdentification
    usUSBVendorID:     $(string.format('0x%04x', data.tProductIdentification.usUSBVendorID))
    usUSBProductID:    $(string.format('0x%04x', data.tProductIdentification.usUSBProductID))
    aucUSBVendorName:  [$(asciihexdump(data.tProductIdentification.aucUSBVendorName))]
    aucUSBProductName: [$(asciihexdump(data.tProductIdentification.aucUSBProductName))]
    aucReservedFields: [$(hexdump(data.tProductIdentification.aucReservedFields))]

  tOEMIdentification
    ulOEMDataOptionFlags:     $(string.format('0x%08x', data.tOEMIdentification.ulOEMDataOptionFlags))
    aucOEMSerialNumber:       [$(asciihexdump(data.tOEMIdentification.aucOEMSerialNumber))]
    aucOEMOrderNumber:        [$(asciihexdump(data.tOEMIdentification.aucOEMOrderNumber))]
    aucOEMHardwareRevision:   [$(asciihexdump(data.tOEMIdentification.aucOEMHardwareRevision))]
    aucOEMProductionDateTime: [$(asciihexdump(data.tOEMIdentification.aucOEMProductionDateTime))]
    aucOEMReservedFields:     [$(hexdump(data.tOEMIdentification.aucOEMReservedFields))]
    aucOEMSpecificData:       [$(asciihexdump(data.tOEMIdentification.aucOEMSpecificData))]

  tFlashLayout
# for uiCnt, tArea in ipairs(data.tFlashLayout.atArea) do
    atArea[$(string.format('%02d', uiCnt))]
      ulAreaContentType:     $(string.format('0x%08x', tArea.ulAreaContentType))
      ulAreaStartAddress:    $(string.format('0x%08x', tArea.ulAreaStartAddress))
      ulAreaSize:            $(string.format('0x%08x', tArea.ulAreaSize))
      ulChipNumber:          $(string.format('0x%08x', tArea.ulChipNumber))
      aucAreaName:           "$(escape(tArea.aucAreaName))"
      ucAreaAccessType:      $(string.format('0x%02x', tArea.ucAreaAccessType))
      aucReserved:           [$(hexdump(tArea.aucReserved))]
# end

# for uiCnt, tChip in ipairs(data.tFlashLayout.atChip) do
    atChip[$(string.format('%02d', uiCnt))]
      ulChipNumber:          $(string.format('0x%08x', tChip.ulChipNumber))
      aucFlashDriverName:    "$(escape(tChip.aucFlashDriverName))"
      ulBlockSize:           $(string.format('0x%08x', tChip.ulBlockSize))
      ulFlashSize:           $(string.format('0x%08x', tChip.ulFlashSize))
      ulMaxEraseWriteCycles: $(string.format('%d', tChip.ulMaxEraseWriteCycles))
# end
  ]]
end



function FDL:__build_contents_crc(strContents)
  local mh = self.mhash.mhash_state()
  mh:init(self.mhash.MHASH_CRC32B)
  mh:hash(strContents)
  local tHash = mh:hash_end()
  local ulCrc32 = string.byte(tHash,1) + 0x00000100*string.byte(tHash,2) + 0x00010000*string.byte(tHash,3) + 0x01000000*string.byte(tHash,4)
  return ulCrc32
end



function FDL:bin2fdl(strFdl)
  local tFDLContents

  -- A minimal FDL must be at least header, 1 data byte and the footer.
  if string.len(strFdl)>(self.sizHeader+self.sizFooter) then
    -- Extract the header data.
    local tFDLHeader = self.tStructureFdlHeader:read(strFdl)
--    self.pl.pretty.dump(tFDLHeader)

    if tFDLHeader.abStartToken~='ProductData>' then
      -- Missing start token.
      print('Missing start token.')

    elseif tFDLHeader.usLabelSize~=(tFDLHeader.usContentSize+self.sizHeader+self.sizFooter) then
      -- Label and header size do not match.
      print(tFDLHeader.usLabelSize, tFDLHeader.usContentSize, self.sizHeader, self.sizFooter)
      print('Label and header size do not match.')

    elseif string.len(strFdl)<tFDLHeader.usLabelSize then
      -- The FDL is smaller than the header requests.
      print('The FDL is smaller than the header requests.')

    else
      -- Extract the contents.
      local strFDLContents = string.sub(strFdl, 1+self.sizHeader, self.sizHeader+tFDLHeader.usContentSize)
      tFDLContents = self.tStructureFdlContents:read(strFDLContents)
--      self.pl.pretty.dump(tFDLContents)

      local strFDLFooter = string.sub(strFdl, 1+self.sizHeader+tFDLHeader.usContentSize)
      local tFDLFooter = self.tStructureFdlFooter:read(strFDLFooter)
--      self.pl.pretty.dump(tFDLFooter)

      local ulCrc32 = self:__build_contents_crc(strFDLContents)
      if ulCrc32~=tFDLFooter.ulChecksum then
        tFDLContents = nil
      end
    end
  end

  return tFDLContents
end



function FDL:fdl2prettyPrint(tFdl)
  local template = self.template
  local tEnv = {
    data=tFdl,
    ipairs=_G.ipairs,
    string=_G.string,
    table=_G.table,

    escape=function(a)
      return string.gsub(a, '[^%g ]', function(s) return string.format('\\%02x', string.byte(s)) end)
    end,

    asciihexdump=function(a)
      local t={}
      for i=1,#a do
        local c = string.sub(a, i, i)
        if string.match(c, '[%g ]')==nil then
          table.insert(t, string.format('0x%02x', string.byte(c)))
        else
          table.insert(t, string.format(' "%s"', c))
        end
      end
      return table.concat(t, ', ')
    end,
    hexdump=function(a)
      local t={}
      for i=1,#a do
        table.insert(t, string.format('0x%02x', string.byte(a, i)))
      end
      return table.concat(t, ', ')
    end,
    macdump=function(a)
      local t={}
      for i=1,#a do
        table.insert(t, string.format('%02x', string.byte(a, i)))
      end
      return table.concat(t, ':')
    end
  }
  return template.substitute(self.strPrettyPrint, tEnv)
end



function FDL:fdl2bin(tFDLContents)
  -- Pack the structure to a string.
  local strFDLContents = self.tStructureFdlContents:write(tFDLContents)
  local ulCrc32 = self:__build_contents_crc(strFDLContents)

  local sizContents = string.len(strFDLContents)
  -- Create the headers.
  local tHeader = {
    abStartToken = 'ProductData>',
    usLabelSize = self.sizHeader + sizContents + self.sizFooter,
    usContentSize = sizContents
  }
  local tFooter = {
    aucEndLabel = '<ProductData',
    ulChecksum = ulCrc32
  }

  local strFDLHeader = self.tStructureFdlHeader:write(tHeader)
  local strFDLFooter = self.tStructureFdlFooter:write(tFooter)

  return strFDLHeader .. strFDLContents .. strFDLFooter
end


return FDL
