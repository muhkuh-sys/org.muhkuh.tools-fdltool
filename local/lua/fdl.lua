local class = require 'pl.class'
local FDL = class()

function FDL:_init(tLog)
  self.tLog = tLog

  local vstruct = require "vstruct"
  self.dkjson = require 'dkjson'
  self.pl = require'pl.import_into'()
  self.template = require 'pl.template'
  self.mhash = require 'mhash'

  self.sizBinaryFdlMaxInBytes = 1024

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
    usManufacturerID:              $(fdl['tBasicDeviceData.usManufacturerID'])
    usDeviceClassificationNumber:  $(fdl['tBasicDeviceData.usDeviceClassificationNumber'])
    ulDeviceNumber:                $(fdl['tBasicDeviceData.ulDeviceNumber'])
    ulSerialNumber:                $(fdl['tBasicDeviceData.ulSerialNumber'])
    ucHardwareCompatibilityNumber: $(fdl['tBasicDeviceData.ucHardwareCompatibilityNumber'])
    ucHardwareRevisionNumber:      $(fdl['tBasicDeviceData.ucHardwareRevisionNumber'])
    usProductionDate:              $(fdl['tBasicDeviceData.usProductionDate'])
    ucReserved1:                   $(fdl['tBasicDeviceData.ucReserved1'])
    ucReserved2:                   $(fdl['tBasicDeviceData.ucReserved2'])
    aucReservedFields:             $(fdl['tBasicDeviceData.aucReservedFields'])

  atMacCOM[1]
    aucMAC:      $(fdl['atMacCOM[1].aucMAC'])
    aucReserved: $(fdl['atMacCOM[1].aucReserved'])
  atMacCOM[2]
    aucMAC:      $(fdl['atMacCOM[2].aucMAC'])
    aucReserved: $(fdl['atMacCOM[2].aucReserved'])
  atMacCOM[3]
    aucMAC:      $(fdl['atMacCOM[3].aucMAC'])
    aucReserved: $(fdl['atMacCOM[3].aucReserved'])
  atMacCOM[4]
    aucMAC:      $(fdl['atMacCOM[4].aucMAC'])
    aucReserved: $(fdl['atMacCOM[4].aucReserved'])

  atMacAPP[1]
    aucMAC:      $(fdl['atMacAPP[1].aucMAC'])
    aucReserved: $(fdl['atMacAPP[1].aucReserved'])
  atMacAPP[2]
    aucMAC:      $(fdl['atMacAPP[2].aucMAC'])
    aucReserved: $(fdl['atMacAPP[2].aucReserved'])
  atMacAPP[3]
    aucMAC:      $(fdl['atMacAPP[3].aucMAC'])
    aucReserved: $(fdl['atMacAPP[3].aucReserved'])
  atMacAPP[4]
    aucMAC:      $(fdl['atMacAPP[4].aucMAC'])
    aucReserved: $(fdl['atMacAPP[4].aucReserved'])

  tProductIdentification
    usUSBVendorID:     $(fdl['tProductIdentification.usUSBVendorID'])
    usUSBProductID:    $(fdl['tProductIdentification.usUSBProductID'])
    aucUSBVendorName:  $(fdl['tProductIdentification.aucUSBVendorName'])
    aucUSBProductName: $(fdl['tProductIdentification.aucUSBProductName'])
    aucReservedFields: $(fdl['tProductIdentification.aucReservedFields'])

  tOEMIdentification
    ulOEMDataOptionFlags:     $(fdl['tOEMIdentification.ulOEMDataOptionFlags'])
    aucOEMSerialNumber:       $(fdl['tOEMIdentification.aucOEMSerialNumber'])
    aucOEMOrderNumber:        $(fdl['tOEMIdentification.aucOEMOrderNumber'])
    aucOEMHardwareRevision:   $(fdl['tOEMIdentification.aucOEMHardwareRevision'])
    aucOEMProductionDateTime: $(fdl['tOEMIdentification.aucOEMProductionDateTime'])
    aucOEMReservedFields:     $(fdl['tOEMIdentification.aucOEMReservedFields'])
    aucOEMSpecificData:       $(fdl['tOEMIdentification.aucOEMSpecificData'])

  tFlashLayout
    atArea[1]
      ulAreaContentType:     $(fdl['tFlashLayout.atArea[1].ulAreaContentType'])
      ulAreaStartAddress:    $(fdl['tFlashLayout.atArea[1].ulAreaStartAddress'])
      ulAreaSize:            $(fdl['tFlashLayout.atArea[1].ulAreaSize'])
      ulChipNumber:          $(fdl['tFlashLayout.atArea[1].ulChipNumber'])
      aucAreaName:           $(fdl['tFlashLayout.atArea[1].aucAreaName'])
      ucAreaAccessType:      $(fdl['tFlashLayout.atArea[1].ucAreaAccessType'])
      aucReserved:           $(fdl['tFlashLayout.atArea[1].aucReserved'])
    atArea[2]
      ulAreaContentType:     $(fdl['tFlashLayout.atArea[2].ulAreaContentType'])
      ulAreaStartAddress:    $(fdl['tFlashLayout.atArea[2].ulAreaStartAddress'])
      ulAreaSize:            $(fdl['tFlashLayout.atArea[2].ulAreaSize'])
      ulChipNumber:          $(fdl['tFlashLayout.atArea[2].ulChipNumber'])
      aucAreaName:           $(fdl['tFlashLayout.atArea[2].aucAreaName'])
      ucAreaAccessType:      $(fdl['tFlashLayout.atArea[2].ucAreaAccessType'])
      aucReserved:           $(fdl['tFlashLayout.atArea[2].aucReserved'])
    atArea[3]
      ulAreaContentType:     $(fdl['tFlashLayout.atArea[3].ulAreaContentType'])
      ulAreaStartAddress:    $(fdl['tFlashLayout.atArea[3].ulAreaStartAddress'])
      ulAreaSize:            $(fdl['tFlashLayout.atArea[3].ulAreaSize'])
      ulChipNumber:          $(fdl['tFlashLayout.atArea[3].ulChipNumber'])
      aucAreaName:           $(fdl['tFlashLayout.atArea[3].aucAreaName'])
      ucAreaAccessType:      $(fdl['tFlashLayout.atArea[3].ucAreaAccessType'])
      aucReserved:           $(fdl['tFlashLayout.atArea[3].aucReserved'])
    atArea[4]
      ulAreaContentType:     $(fdl['tFlashLayout.atArea[4].ulAreaContentType'])
      ulAreaStartAddress:    $(fdl['tFlashLayout.atArea[4].ulAreaStartAddress'])
      ulAreaSize:            $(fdl['tFlashLayout.atArea[4].ulAreaSize'])
      ulChipNumber:          $(fdl['tFlashLayout.atArea[4].ulChipNumber'])
      aucAreaName:           $(fdl['tFlashLayout.atArea[4].aucAreaName'])
      ucAreaAccessType:      $(fdl['tFlashLayout.atArea[4].ucAreaAccessType'])
      aucReserved:           $(fdl['tFlashLayout.atArea[4].aucReserved'])
    atArea[5]
      ulAreaContentType:     $(fdl['tFlashLayout.atArea[5].ulAreaContentType'])
      ulAreaStartAddress:    $(fdl['tFlashLayout.atArea[5].ulAreaStartAddress'])
      ulAreaSize:            $(fdl['tFlashLayout.atArea[5].ulAreaSize'])
      ulChipNumber:          $(fdl['tFlashLayout.atArea[5].ulChipNumber'])
      aucAreaName:           $(fdl['tFlashLayout.atArea[5].aucAreaName'])
      ucAreaAccessType:      $(fdl['tFlashLayout.atArea[5].ucAreaAccessType'])
      aucReserved:           $(fdl['tFlashLayout.atArea[5].aucReserved'])
    atArea[6]
      ulAreaContentType:     $(fdl['tFlashLayout.atArea[6].ulAreaContentType'])
      ulAreaStartAddress:    $(fdl['tFlashLayout.atArea[6].ulAreaStartAddress'])
      ulAreaSize:            $(fdl['tFlashLayout.atArea[6].ulAreaSize'])
      ulChipNumber:          $(fdl['tFlashLayout.atArea[6].ulChipNumber'])
      aucAreaName:           $(fdl['tFlashLayout.atArea[6].aucAreaName'])
      ucAreaAccessType:      $(fdl['tFlashLayout.atArea[6].ucAreaAccessType'])
      aucReserved:           $(fdl['tFlashLayout.atArea[6].aucReserved'])
    atArea[7]
      ulAreaContentType:     $(fdl['tFlashLayout.atArea[7].ulAreaContentType'])
      ulAreaStartAddress:    $(fdl['tFlashLayout.atArea[7].ulAreaStartAddress'])
      ulAreaSize:            $(fdl['tFlashLayout.atArea[7].ulAreaSize'])
      ulChipNumber:          $(fdl['tFlashLayout.atArea[7].ulChipNumber'])
      aucAreaName:           $(fdl['tFlashLayout.atArea[7].aucAreaName'])
      ucAreaAccessType:      $(fdl['tFlashLayout.atArea[7].ucAreaAccessType'])
      aucReserved:           $(fdl['tFlashLayout.atArea[7].aucReserved'])
    atArea[8]
      ulAreaContentType:     $(fdl['tFlashLayout.atArea[8].ulAreaContentType'])
      ulAreaStartAddress:    $(fdl['tFlashLayout.atArea[8].ulAreaStartAddress'])
      ulAreaSize:            $(fdl['tFlashLayout.atArea[8].ulAreaSize'])
      ulChipNumber:          $(fdl['tFlashLayout.atArea[8].ulChipNumber'])
      aucAreaName:           $(fdl['tFlashLayout.atArea[8].aucAreaName'])
      ucAreaAccessType:      $(fdl['tFlashLayout.atArea[8].ucAreaAccessType'])
      aucReserved:           $(fdl['tFlashLayout.atArea[8].aucReserved'])
    atArea[9]
      ulAreaContentType:     $(fdl['tFlashLayout.atArea[9].ulAreaContentType'])
      ulAreaStartAddress:    $(fdl['tFlashLayout.atArea[9].ulAreaStartAddress'])
      ulAreaSize:            $(fdl['tFlashLayout.atArea[9].ulAreaSize'])
      ulChipNumber:          $(fdl['tFlashLayout.atArea[9].ulChipNumber'])
      aucAreaName:           $(fdl['tFlashLayout.atArea[9].aucAreaName'])
      ucAreaAccessType:      $(fdl['tFlashLayout.atArea[9].ucAreaAccessType'])
      aucReserved:           $(fdl['tFlashLayout.atArea[9].aucReserved'])
    atArea[10]
      ulAreaContentType:     $(fdl['tFlashLayout.atArea[10].ulAreaContentType'])
      ulAreaStartAddress:    $(fdl['tFlashLayout.atArea[10].ulAreaStartAddress'])
      ulAreaSize:            $(fdl['tFlashLayout.atArea[10].ulAreaSize'])
      ulChipNumber:          $(fdl['tFlashLayout.atArea[10].ulChipNumber'])
      aucAreaName:           $(fdl['tFlashLayout.atArea[10].aucAreaName'])
      ucAreaAccessType:      $(fdl['tFlashLayout.atArea[10].ucAreaAccessType'])
      aucReserved:           $(fdl['tFlashLayout.atArea[10].aucReserved'])

    atChip[1]
      ulChipNumber:          $(fdl['tFlashLayout.atChip[1].ulChipNumber'])
      aucFlashDriverName:    $(fdl['tFlashLayout.atChip[1].aucFlashDriverName'])
      ulBlockSize:           $(fdl['tFlashLayout.atChip[1].ulBlockSize'])
      ulFlashSize:           $(fdl['tFlashLayout.atChip[1].ulFlashSize'])
      ulMaxEraseWriteCycles: $(fdl['tFlashLayout.atChip[1].ulMaxEraseWriteCycles'])
    atChip[2]
      ulChipNumber:          $(fdl['tFlashLayout.atChip[2].ulChipNumber'])
      aucFlashDriverName:    $(fdl['tFlashLayout.atChip[2].aucFlashDriverName'])
      ulBlockSize:           $(fdl['tFlashLayout.atChip[2].ulBlockSize'])
      ulFlashSize:           $(fdl['tFlashLayout.atChip[2].ulFlashSize'])
      ulMaxEraseWriteCycles: $(fdl['tFlashLayout.atChip[2].ulMaxEraseWriteCycles'])
    atChip[3]
      ulChipNumber:          $(fdl['tFlashLayout.atChip[3].ulChipNumber'])
      aucFlashDriverName:    $(fdl['tFlashLayout.atChip[3].aucFlashDriverName'])
      ulBlockSize:           $(fdl['tFlashLayout.atChip[3].ulBlockSize'])
      ulFlashSize:           $(fdl['tFlashLayout.atChip[3].ulFlashSize'])
      ulMaxEraseWriteCycles: $(fdl['tFlashLayout.atChip[3].ulMaxEraseWriteCycles'])
    atChip[4]
      ulChipNumber:          $(fdl['tFlashLayout.atChip[4].ulChipNumber'])
      aucFlashDriverName:    $(fdl['tFlashLayout.atChip[4].aucFlashDriverName'])
      ulBlockSize:           $(fdl['tFlashLayout.atChip[4].ulBlockSize'])
      ulFlashSize:           $(fdl['tFlashLayout.atChip[4].ulFlashSize'])
      ulMaxEraseWriteCycles: $(fdl['tFlashLayout.atChip[4].ulMaxEraseWriteCycles'])
  ]]

  self.atPrettyPrintFormat = {
    ['tBasicDeviceData.usManufacturerID'] =              self.__format_decimal,
    ['tBasicDeviceData.usDeviceClassificationNumber'] =  self.__format_decimal,
    ['tBasicDeviceData.ulDeviceNumber'] =                self.__format_decimal,
    ['tBasicDeviceData.ulSerialNumber'] =                self.__format_decimal,
    ['tBasicDeviceData.ucHardwareCompatibilityNumber'] = self.__format_decimal,
    ['tBasicDeviceData.ucHardwareRevisionNumber'] =      self.__format_decimal,
    ['tBasicDeviceData.usProductionDate'] =              self.__format_hex16,
    ['tBasicDeviceData.ucReserved1'] =                   self.__format_hex08,
    ['tBasicDeviceData.ucReserved2'] =                   self.__format_hex08,
    ['tBasicDeviceData.aucReservedFields'] =             self.__format_hexdump,

    ['atMacCOM[1].aucMAC'] =       self.__format_macdump,
    ['atMacCOM[1].aucReserved'] =  self.__format_hexdump,
    ['atMacCOM[2].aucMAC'] =       self.__format_macdump,
    ['atMacCOM[2].aucReserved'] =  self.__format_hexdump,
    ['atMacCOM[3].aucMAC'] =       self.__format_macdump,
    ['atMacCOM[3].aucReserved'] =  self.__format_hexdump,
    ['atMacCOM[4].aucMAC'] =       self.__format_macdump,
    ['atMacCOM[4].aucReserved'] =  self.__format_hexdump,
    ['atMacCOM[5].aucMAC'] =       self.__format_macdump,
    ['atMacCOM[5].aucReserved'] =  self.__format_hexdump,
    ['atMacCOM[6].aucMAC'] =       self.__format_macdump,
    ['atMacCOM[6].aucReserved'] =  self.__format_hexdump,
    ['atMacCOM[7].aucMAC'] =       self.__format_macdump,
    ['atMacCOM[7].aucReserved'] =  self.__format_hexdump,
    ['atMacCOM[8].aucMAC'] =       self.__format_macdump,
    ['atMacCOM[8].aucReserved'] =  self.__format_hexdump,

    ['atMacAPP[1].aucMAC'] =       self.__format_macdump,
    ['atMacAPP[1].aucReserved'] =  self.__format_hexdump,
    ['atMacAPP[2].aucMAC'] =       self.__format_macdump,
    ['atMacAPP[2].aucReserved'] =  self.__format_hexdump,
    ['atMacAPP[3].aucMAC'] =       self.__format_macdump,
    ['atMacAPP[3].aucReserved'] =  self.__format_hexdump,
    ['atMacAPP[4].aucMAC'] =       self.__format_macdump,
    ['atMacAPP[4].aucReserved'] =  self.__format_hexdump,

    ['tProductIdentification.usUSBVendorID'] =     self.__format_hex16,
    ['tProductIdentification.usUSBProductID'] =    self.__format_hex16,
    ['tProductIdentification.aucUSBVendorName'] =  self.__format_asciihexdump,
    ['tProductIdentification.aucUSBProductName'] = self.__format_asciihexdump,
    ['tProductIdentification.aucReservedFields'] = self.__format_hexdump,

    ['tOEMIdentification.ulOEMDataOptionFlags'] =     self.__format_hex32,
    ['tOEMIdentification.aucOEMSerialNumber'] =       self.__format_asciihexdump,
    ['tOEMIdentification.aucOEMOrderNumber'] =        self.__format_asciihexdump,
    ['tOEMIdentification.aucOEMHardwareRevision'] =   self.__format_asciihexdump,
    ['tOEMIdentification.aucOEMProductionDateTime'] = self.__format_asciihexdump,
    ['tOEMIdentification.aucOEMReservedFields'] =     self.__format_hexdump,
    ['tOEMIdentification.aucOEMSpecificData'] =       self.__format_asciihexdump,

    ['tFlashLayout.atArea[1].ulAreaContentType'] =    self.__format_hex32,
    ['tFlashLayout.atArea[1].ulAreaStartAddress'] =   self.__format_hex32,
    ['tFlashLayout.atArea[1].ulAreaSize'] =           self.__format_hex32,
    ['tFlashLayout.atArea[1].ulChipNumber'] =         self.__format_hex32,
    ['tFlashLayout.atArea[1].aucAreaName'] =          self.__format_escape,
    ['tFlashLayout.atArea[1].ucAreaAccessType'] =     self.__format_hex08,
    ['tFlashLayout.atArea[1].aucReserved'] =          self.__format_hexdump,
    ['tFlashLayout.atArea[2].ulAreaContentType'] =    self.__format_hex32,
    ['tFlashLayout.atArea[2].ulAreaStartAddress'] =   self.__format_hex32,
    ['tFlashLayout.atArea[2].ulAreaSize'] =           self.__format_hex32,
    ['tFlashLayout.atArea[2].ulChipNumber'] =         self.__format_hex32,
    ['tFlashLayout.atArea[2].aucAreaName'] =          self.__format_escape,
    ['tFlashLayout.atArea[2].ucAreaAccessType'] =     self.__format_hex08,
    ['tFlashLayout.atArea[2].aucReserved'] =          self.__format_hexdump,
    ['tFlashLayout.atArea[3].ulAreaContentType'] =    self.__format_hex32,
    ['tFlashLayout.atArea[3].ulAreaStartAddress'] =   self.__format_hex32,
    ['tFlashLayout.atArea[3].ulAreaSize'] =           self.__format_hex32,
    ['tFlashLayout.atArea[3].ulChipNumber'] =         self.__format_hex32,
    ['tFlashLayout.atArea[3].aucAreaName'] =          self.__format_escape,
    ['tFlashLayout.atArea[3].ucAreaAccessType'] =     self.__format_hex08,
    ['tFlashLayout.atArea[3].aucReserved'] =          self.__format_hexdump,
    ['tFlashLayout.atArea[4].ulAreaContentType'] =    self.__format_hex32,
    ['tFlashLayout.atArea[4].ulAreaStartAddress'] =   self.__format_hex32,
    ['tFlashLayout.atArea[4].ulAreaSize'] =           self.__format_hex32,
    ['tFlashLayout.atArea[4].ulChipNumber'] =         self.__format_hex32,
    ['tFlashLayout.atArea[4].aucAreaName'] =          self.__format_escape,
    ['tFlashLayout.atArea[4].ucAreaAccessType'] =     self.__format_hex08,
    ['tFlashLayout.atArea[4].aucReserved'] =          self.__format_hexdump,
    ['tFlashLayout.atArea[5].ulAreaContentType'] =    self.__format_hex32,
    ['tFlashLayout.atArea[5].ulAreaStartAddress'] =   self.__format_hex32,
    ['tFlashLayout.atArea[5].ulAreaSize'] =           self.__format_hex32,
    ['tFlashLayout.atArea[5].ulChipNumber'] =         self.__format_hex32,
    ['tFlashLayout.atArea[5].aucAreaName'] =          self.__format_escape,
    ['tFlashLayout.atArea[5].ucAreaAccessType'] =     self.__format_hex08,
    ['tFlashLayout.atArea[5].aucReserved'] =          self.__format_hexdump,
    ['tFlashLayout.atArea[6].ulAreaContentType'] =    self.__format_hex32,
    ['tFlashLayout.atArea[6].ulAreaStartAddress'] =   self.__format_hex32,
    ['tFlashLayout.atArea[6].ulAreaSize'] =           self.__format_hex32,
    ['tFlashLayout.atArea[6].ulChipNumber'] =         self.__format_hex32,
    ['tFlashLayout.atArea[6].aucAreaName'] =          self.__format_escape,
    ['tFlashLayout.atArea[6].ucAreaAccessType'] =     self.__format_hex08,
    ['tFlashLayout.atArea[6].aucReserved'] =          self.__format_hexdump,
    ['tFlashLayout.atArea[7].ulAreaContentType'] =    self.__format_hex32,
    ['tFlashLayout.atArea[7].ulAreaStartAddress'] =   self.__format_hex32,
    ['tFlashLayout.atArea[7].ulAreaSize'] =           self.__format_hex32,
    ['tFlashLayout.atArea[7].ulChipNumber'] =         self.__format_hex32,
    ['tFlashLayout.atArea[7].aucAreaName'] =          self.__format_escape,
    ['tFlashLayout.atArea[7].ucAreaAccessType'] =     self.__format_hex08,
    ['tFlashLayout.atArea[7].aucReserved'] =          self.__format_hexdump,
    ['tFlashLayout.atArea[8].ulAreaContentType'] =    self.__format_hex32,
    ['tFlashLayout.atArea[8].ulAreaStartAddress'] =   self.__format_hex32,
    ['tFlashLayout.atArea[8].ulAreaSize'] =           self.__format_hex32,
    ['tFlashLayout.atArea[8].ulChipNumber'] =         self.__format_hex32,
    ['tFlashLayout.atArea[8].aucAreaName'] =          self.__format_escape,
    ['tFlashLayout.atArea[8].ucAreaAccessType'] =     self.__format_hex08,
    ['tFlashLayout.atArea[8].aucReserved'] =          self.__format_hexdump,
    ['tFlashLayout.atArea[9].ulAreaContentType'] =    self.__format_hex32,
    ['tFlashLayout.atArea[9].ulAreaStartAddress'] =   self.__format_hex32,
    ['tFlashLayout.atArea[9].ulAreaSize'] =           self.__format_hex32,
    ['tFlashLayout.atArea[9].ulChipNumber'] =         self.__format_hex32,
    ['tFlashLayout.atArea[9].aucAreaName'] =          self.__format_escape,
    ['tFlashLayout.atArea[9].ucAreaAccessType'] =     self.__format_hex08,
    ['tFlashLayout.atArea[9].aucReserved'] =          self.__format_hexdump,
    ['tFlashLayout.atArea[10].ulAreaContentType'] =    self.__format_hex32,
    ['tFlashLayout.atArea[10].ulAreaStartAddress'] =   self.__format_hex32,
    ['tFlashLayout.atArea[10].ulAreaSize'] =           self.__format_hex32,
    ['tFlashLayout.atArea[10].ulChipNumber'] =         self.__format_hex32,
    ['tFlashLayout.atArea[10].aucAreaName'] =          self.__format_escape,
    ['tFlashLayout.atArea[10].ucAreaAccessType'] =     self.__format_hex08,
    ['tFlashLayout.atArea[10].aucReserved'] =          self.__format_hexdump,

    ['tFlashLayout.atChip[1].ulChipNumber'] =          self.__format_hex32,
    ['tFlashLayout.atChip[1].aucFlashDriverName'] =    self.__format_escape,
    ['tFlashLayout.atChip[1].ulBlockSize'] =           self.__format_hex32,
    ['tFlashLayout.atChip[1].ulFlashSize'] =           self.__format_hex32,
    ['tFlashLayout.atChip[1].ulMaxEraseWriteCycles'] = self.__format_decimal,
    ['tFlashLayout.atChip[2].ulChipNumber'] =          self.__format_hex32,
    ['tFlashLayout.atChip[2].aucFlashDriverName'] =    self.__format_escape,
    ['tFlashLayout.atChip[2].ulBlockSize'] =           self.__format_hex32,
    ['tFlashLayout.atChip[2].ulFlashSize'] =           self.__format_hex32,
    ['tFlashLayout.atChip[2].ulMaxEraseWriteCycles'] = self.__format_decimal,
    ['tFlashLayout.atChip[3].ulChipNumber'] =          self.__format_hex32,
    ['tFlashLayout.atChip[3].aucFlashDriverName'] =    self.__format_escape,
    ['tFlashLayout.atChip[3].ulBlockSize'] =           self.__format_hex32,
    ['tFlashLayout.atChip[3].ulFlashSize'] =           self.__format_hex32,
    ['tFlashLayout.atChip[3].ulMaxEraseWriteCycles'] = self.__format_decimal,
    ['tFlashLayout.atChip[4].ulChipNumber'] =          self.__format_hex32,
    ['tFlashLayout.atChip[4].aucFlashDriverName'] =    self.__format_escape,
    ['tFlashLayout.atChip[4].ulBlockSize'] =           self.__format_hex32,
    ['tFlashLayout.atChip[4].ulFlashSize'] =           self.__format_hex32,
    ['tFlashLayout.atChip[4].ulMaxEraseWriteCycles'] = self.__format_decimal
  }
end



function FDL.__format_decimal(a)
  return string.format('%d', a)
end



function FDL.__format_hex08(a)
  return string.format('0x%02x', a)
end



function FDL.__format_hex16(a)
  return string.format('0x%04x', a)
end



function FDL.__format_hex32(a)
  return string.format('0x%08x', a)
end



function FDL.__format_hexdump(a)
  local t={}
  for i=1,#a do
    table.insert(t, string.format('0x%02x', string.byte(a, i)))
  end
  return '[ ' .. table.concat(t, ', ') .. ' ]'
end



function FDL.__format_macdump(a)
  local t={}
  for i=1,#a do
    table.insert(t, string.format('%02x', string.byte(a, i)))
  end
  return table.concat(t, ':')
end



function FDL.__format_escape(a)
  return '"' .. string.gsub(a, '[^%g ]', function(s) return string.format('\\%02x', string.byte(s)) end) .. '"'
end



function FDL.__format_asciihexdump(a)
  local t={}
  for i=1,#a do
    local c = string.sub(a, i, i)
    if string.match(c, '[%g ]')==nil then
      table.insert(t, string.format('0x%02x', string.byte(c)))
    else
      table.insert(t, string.format(' "%s"', c))
    end
  end
  return '[ ' .. table.concat(t, ', ') .. ' ]'
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
  local tLog = self.tLog
  local tFDLContents

  -- A minimal FDL must be at least header, 1 data byte and the footer.
  if string.len(strFdl)>(self.sizHeader+self.sizFooter) then
    -- Extract the header data.
    local tFDLHeader = self.tStructureFdlHeader:read(strFdl)
--    self.pl.pretty.dump(tFDLHeader)

    if tFDLHeader.abStartToken~='ProductData>' then
      -- Missing start token.
      tLog.error('Missing start token.')

    elseif tFDLHeader.usLabelSize~=(tFDLHeader.usContentSize+self.sizHeader+self.sizFooter) then
      -- Label and header size do not match.
      tLog.error('The complete label size is not the size of the header+contents+footer: %d is not %d+%d+%d', tFDLHeader.usLabelSize, tFDLHeader.usContentSize, self.sizHeader, self.sizFooter)

    elseif string.len(strFdl)<tFDLHeader.usLabelSize then
      -- The FDL is smaller than the header requests.
      tLog.error('The FDL is smaller than the header requests.')

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



function FDL:__parseMacs(atMac)
  if atMac~=nil then
    for uiCnt, tMac in ipairs(atMac) do
      local aucMAC = tMac.aucMAC
      -- Is this a human readable MAC?
      local m1, m2, m3, m4, m5, m6 = string.match(aucMAC, '^(%x%x):(%x%x):(%x%x):(%x%x):(%x%x):(%x%x)$')
      if m1~=nil then
        aucMAC = string.char(tonumber(m1, 16), tonumber(m2, 16), tonumber(m3, 16), tonumber(m4, 16), tonumber(m5, 16), tonumber(m6, 16))
        atMac[uiCnt].aucMAC = aucMAC
      end
    end
  end
end



function FDL:__processSpecialFields(tFdl)
  -- Accept a human-readable encoding for MACs.
  self:__parseMacs(tFdl.atMacCOM)
  self:__parseMacs(tFdl.atMacAPP)
end



function FDL:json2fdl(strJson)
  local tLog = self.tLog
  local tResult

  -- Decode the JSON data.
  local tFdl, strError = self.dkjson.decode(strJson)
  if tFdl==nil then
    tLog.error('Failed to decode the JSON data: %s', tostring(strError))

  else
    -- Process special fields like the MAC adress.
    self:__processSpecialFields(tFdl)

    -- Encode the FDL to binary.
    local strFdl = self:fdl2bin(tFdl)
    -- Decode the binary to an FDL structure again.
    tResult = self:bin2fdl(strFdl)
  end

  return tResult
end



function FDL:fdl2json(tFdl)
  return self.dkjson.encode(tFdl, { indent = true })
end



function FDL:fdl2prettyPrint(tFdl)
  local tPrettyFormatted = {}
  self:__generate_pretty_formatted({}, tFdl, tPrettyFormatted)

  local template = self.template
  local tEnv = {
    fdl=tPrettyFormatted
  }
  return template.substitute(self.strPrettyPrint, tEnv)
end



function FDL:__generate_pretty_formatted(tPath, atMainTable, atPrettyPrint)
  local atPrettyPrintFormat = self.atPrettyPrintFormat

  -- Iterate over all elements of the main table.
  for tKey, tValue in pairs(atMainTable) do
    local strKey
    if #tPath==0 then
      strKey = tostring(tKey)
    else
      strKey = '.' .. tostring(tKey)
    end
    -- Use numbers as index.
    local ulKey = tonumber(tKey)
    if ulKey~=nil and atMainTable[ulKey] then
      tKey = ulKey
      strKey = string.format('[%d]', ulKey)
    end
    local strElementPath = table.concat(tPath) .. strKey
    -- Is the value a table?
    if type(tValue)=='table' then
      table.insert(tPath, strKey)
      self:__generate_pretty_formatted(tPath, tValue, atPrettyPrint)
      table.remove(tPath)
    else
      local fnFormat = atPrettyPrintFormat[strElementPath]
      local strValue = tostring(tValue)
      if fnFormat~=nil then
        strValue = fnFormat(strValue)
      end
      atPrettyPrint[strElementPath] = strValue
    end
  end
end



function FDL:__merge_tables(tPath, atMainTable, atPatchTable, atPrettyFormatted)
  local tLog = self.tLog
  local atPrettyPrintFormat = self.atPrettyPrintFormat
  local tResult = true

  -- Iterate over all elements of the patch table.
  for tPatchKey, tPatchValue in pairs(atPatchTable) do
    local strPatchKey
    if #tPath==0 then
      strPatchKey = tostring(tPatchKey)
    else
      strPatchKey = '.' .. tostring(tPatchKey)
    end
    -- Use numbers as index.
    local ulPatchKey = tonumber(tPatchKey)
    if ulPatchKey~=nil and atMainTable[ulPatchKey] then
      tPatchKey = ulPatchKey
      strPatchKey = string.format('[%d]', ulPatchKey)
    end
    -- The value must exist in the main table and the type must be the same.
    local tMainValue = atMainTable[tPatchKey]
    local strTypeMainValue = type(tMainValue)
    local strTypePatchValue = type(tPatchValue)
    local strElementPath = table.concat(tPath) .. strPatchKey
    if tMainValue==nil then
      tLog.error('The patch contains the non-existing element "%s".', strElementPath)
      tResult = nil
      break
    elseif strTypeMainValue~=strTypePatchValue then
      tLog.error('The type of the patch value is %s, which differs from the type of the data value %s.', strTypePatchValue, strTypeMainValue)
      tResult = nil
      break
    else
      -- Is the value a table?
      if strTypeMainValue=='table' then
        table.insert(tPath, strPatchKey)
        tResult = self:__merge_tables(tPath, tMainValue, tPatchValue)
        table.remove(tPath)
        if tResult~=true then
          break
        end
      else
        local fnFormat = atPrettyPrintFormat[strElementPath]
        local strValueFrom = tostring(tMainValue)
        local strValueTo = tostring(tPatchValue)
        if fnFormat~=nil then
          strValueFrom = fnFormat(strValueFrom)
          strValueTo = fnFormat(strValueTo)
        end
        tLog.info('Patching "%s" from %s to %s.', strElementPath, strValueFrom, strValueTo)
        atMainTable[tPatchKey] = tPatchValue
      end
    end
  end

  return tResult
end



function FDL:patchFdl(tFdl, tPatches)
  -- Process special fields like the MAC adress.
  self:__processSpecialFields(tPatches)

  return self:__merge_tables({}, tFdl, tPatches)
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
