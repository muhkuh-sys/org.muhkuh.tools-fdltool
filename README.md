FDL Tool
======

The FDL is a Hilscher structure which stores some mixture of device and firmware specific data. See here for more details and some GUI Tools: https://kb.hilscher.com/display/NETX/FDL+-+Flash+Device+Label

If you are looking for...

* a command line tool
* a cross-platform tool
* something lightweight
* a way to patch an FDL
* an easy dump tool
* a way to convert an FDL from/to JSON

... you have come to the right place.

Before we start: **please note that this is no official Hilscher tool**. It comes from the deepest depths of the developer dungeons. There is no support, no guarantees. Still here? Ok, now we are ready.

The FDL tool is written in LUA. It is tested with LUA5.4, but it should also work with 5.1 . It depends on these modules:

* lua-log ( https://github.com/moteus/lua-log )
* argparse ( https://github.com/mpeterv/argparse )
* penlight ( https://github.com/lunarmodules/Penlight )
* vstruct ( https://github.com/ToxicFrog/vstruct )
* dkjson ( http://dkolf.de/src/dkjson-lua.fsl/home )
* mhash for LUA ( https://github.com/muhkuh-sys/org.muhkuh.lua-mhash )

Head over to the [releases](https://github.com/muhkuh-sys/org.muhkuh.tools-fdltool/releases) for ready-to-use bundles. There are builds for Windows 32 and 64 Bit, and some Ubuntu versions.

# Quickstart

Download the [release](https://github.com/muhkuh-sys/org.muhkuh.tools-fdltool/releases/latest) for your platform, and extract the archive somewhere.

Open a shell, command prompt or power shell in the newly created folder. It should look similar to this:

```
brynhild@hidin:~/fdltool-0.0.2$ ls -l
total 508
drwxrwxr-x 2 brynhild brynhild   4096 Nov 12 23:28 demo
drwxrwxr-x 2 brynhild brynhild   4096 Nov 12 23:26 doc
-rw-r--r-- 1 brynhild brynhild   9530 Nov 12 23:26 fdltool.lua
-rw-r--r-- 1 brynhild brynhild   4466 Nov 12 23:26 fdl_to_wfp_template.lua
drwxrwxr-x 6 brynhild brynhild   4096 Nov 12 23:28 lua
-rwxr-xr-x 1 brynhild brynhild  27832 Nov 12 23:26 lua5.4
-rw-r--r-- 1 brynhild brynhild 422632 Nov 12 23:26 lua5.4.so
drwxrwxr-x 3 brynhild brynhild   4096 Nov 12 23:28 lua_plugins
-rwxr-xr-x 1 brynhild brynhild  27832 Nov 12 23:26 wlua5.4
```

The ```demo``` folder provides some example files to start with.

All examples below are for linux. For Windows replace ```./lua5.4``` with ```lua5.4.exe```. If I remember correctly power shell wants a ```.\lua5.4.exe```.

## Show the help
Run the LUA5.4 interpreter with the fdltool.lua script and ```--help```: ```./lua5.4 fdltool.lua --help```

Example:
```
brynhild@hidin:~/fdltool-0.0.2$ ./lua5.4 fdltool.lua --help
Usage: fdltool ([--color] | [--no-color]) [--version]
       [-p <PATCH_FILE>] [--input-type <IN_TYPE>]
       [--output-type <OUT_TYPE>] [-v <LEVEL>] [-s <SKIP>] [-p <SIZE>]
       [--padding-byte <BYTE>] [-l <FILE>] [-h] <IN_FILE> [<OUT_FILE>]

Decode, patch and convert FDLs.

Arguments:
   input                 Read the input data from IN_FILE.
   output                Write the output data to OUT_FILE.

Options:
   --version             Show the version and exit.
        -p <PATCH_FILE>, Patch the input data with values from the JSON file PATCH_FILE.
   --patch <PATCH_FILE>
   --input-type <IN_TYPE>
                         Do not guess the type of the input file but set it to IN_TYPE. Possible values for IN_TYPE are BIN, JSON.
   --output-type <OUT_TYPE>
                         Do not guess the type of the output file but set it to OUT_TYPE. Possible values for OUT_TYPE are BIN, JSON, TXT.
          -v <LEVEL>,    Set the verbosity level to LEVEL. Possible values for LEVEL are debug, info, warning, error, fatal. (default: warning)
   --verbose <LEVEL>
             -s <SKIP>,  Skip the first SKIP bytes when reading a binary input. The default is to skip no bytes.
   --skip-input <SKIP>
      -p <SIZE>,         Pad binary output to a minimum size of SIZE. The default is 0 which adds no padding.
   --pad <SIZE>
   --padding-byte <BYTE> Use BYTE for padding. The default is 0xff .
          -l <FILE>,     Write all output to FILE.
   --logfile <FILE>
   --color               Use colors to beautify the console output. This is the default on Linux.
   --no-color            Do not use colors for the console output. This is the default on Windows.
   -h, --help            Show this help message and exit.

```

## Decode an FDL to STDOUT

Run the LUA5.4 interpreter with the fdltool.lua script and a FDL file as parameter to decode it to STDOUT: ```./lua5.4 fdltool.lua input.fdl```

Example:
```
brynhild@hidin:~/fdltool-0.0.2$ ./lua5.4 fdltool.lua demo/FDL_NXHX90-JTAG_7833000r3_UseCaseC.fdl
  tBasicDeviceData
    usManufacturerID:              1
    usDeviceClassificationNumber:  69
    ulDeviceNumber:                7833000
    ulSerialNumber:                20000
    ucHardwareCompatibilityNumber: 0
    ucHardwareRevisionNumber:      3
    usProductionDate:              0x112b
    ucReserved1:                   0x00
    ucReserved2:                   0x00
    aucReservedFields:             [ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ]

  atMacCOM[1]
    aucMAC:      02:00:00:1e:99:00
    aucReserved: [ 0x00, 0x00 ]
  atMacCOM[2]
    aucMAC:      02:00:00:1e:99:01
    aucReserved: [ 0x00, 0x00 ]
  atMacCOM[3]
    aucMAC:      02:00:00:1e:99:02
    aucReserved: [ 0x00, 0x00 ]
  atMacCOM[4]
    aucMAC:      02:00:00:1e:99:03
    aucReserved: [ 0x00, 0x00 ]
...
```

Please note that this works as long as the FDL file has a suffix different from ".json" and ".txt". See "File type detection" for details.

## Decode an FDL to a file

Just add the output file as another parameter: ```./lua5.4 fdltool.lua input.fdl output.txt```

Example:
```
brynhild@hidin:~/fdltool-0.0.2$ ./lua5.4 fdltool.lua demo/FDL_NXHX90-JTAG_7833000r3_UseCaseC.fdl FDL_NXHX90-JTAG_7833000r3_UseCaseC.txt
brynhild@hidin:~/fdltool-0.0.2$ cat FDL_NXHX90-JTAG_7833000r3_UseCaseC.txt
  tBasicDeviceData
    usManufacturerID:              1
    usDeviceClassificationNumber:  69
    ulDeviceNumber:                7833000
    ulSerialNumber:                20000
...
```

Please note that this works as long as the FDL file has a suffix different from ".json" and ".txt". The output file must have a ".txt" suffix. See "File type detection" for details.

## Convert an FDL to JSON

Simply specify a ".json" file instead of the ".txt": ```./lua5.4 fdltool.lua input.fdl output.json```

Example:
```
brynhild@hidin:~/fdltool-0.0.2$ ./lua5.4 fdltool.lua demo/FDL_NXHX90-JTAG_7833000r3_UseCaseC.fdl FDL_NXHX90-JTAG_7833000r3_UseCaseC.json
brynhild@hidin:~/fdltool-0.0.2$ cat FDL_NXHX90-JTAG_7833000r3_UseCaseC.json
{
  "tProductIdentification":{
    "usUSBProductID":0,
    "aucUSBVendorName":"\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000",
    "usUSBVendorID":0,
    "aucReservedFields":"\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000",
    "aucUSBProductName":"\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000"
...
```

Please note that the order of the JSON entries differs for each run of the tool. This is not nice, this is a bug.

Please note that this works as long as the FDL file has a suffix different from ".json" and ".txt". The output file must have a ".json" suffix. See "File type detection" for details.

## Patch an FDL

Patches are specified as JSON files. The data must be a subset of a complete FDL in JSON form. A good start is to convert an FDL to JSON, modify the required parts and remove the rest. See ```demo/patch_*.json``` for some examples.
```./lua5.4 fdltool.lua --patch patch.json input.fdl patched_output.fdl```

Example:
```
brynhild@hidin:~/fdltool-0.0.2$ cat demo/patch_mac_and_oem.json
{
  "tOEMIdentification":{
    "aucOEMOrderNumber":"1234.567",
    "aucOEMSerialNumber":"23456"
  },
  "atMacCOM":{
    { "aucMAC":"01:23:45:67:89:ab" },
    { "aucMAC":"45:67:89:ab:cd:ef" },
    { "aucMAC":"ef:cd:ab:89:67:45" },
    { "aucMAC":"ab:89:67:45:23:01" }
  }
}
brynhild@hidin:~/fdltool-0.0.2$ ./lua5.4 fdltool.lua --patch demo/patch_mac_and_oem.json demo/FDL_NXHX90-JTAG_7833000r3_UseCaseC.fdl patched.fdl
brynhild@hidin:~/fdltool-0.0.2$ ./lua5.4 fdltool.lua patched.fdl patched.txt
brynhild@hidin:~/fdltool-0.0.2$ diff -uNr FDL_NXHX90-JTAG_7833000r3_UseCaseC.txt patched.txt
--- FDL_NXHX90-JTAG_7833000r3_UseCaseC.txt	2020-11-12 23:36:01.391919727 +0100
+++ patched.txt	2020-11-12 23:46:35.611491985 +0100
@@ -11,16 +11,16 @@
     aucReservedFields:             [ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ]
 
   atMacCOM[1]
-    aucMAC:      02:00:00:1e:99:00
+    aucMAC:      01:23:45:67:89:ab
     aucReserved: [ 0x00, 0x00 ]
   atMacCOM[2]
-    aucMAC:      02:00:00:1e:99:01
+    aucMAC:      45:67:89:ab:cd:ef
     aucReserved: [ 0x00, 0x00 ]
   atMacCOM[3]
-    aucMAC:      02:00:00:1e:99:02
+    aucMAC:      ef:cd:ab:89:67:45
     aucReserved: [ 0x00, 0x00 ]
   atMacCOM[4]
-    aucMAC:      02:00:00:1e:99:03
+    aucMAC:      ab:89:67:45:23:01
     aucReserved: [ 0x00, 0x00 ]
 
   atMacAPP[1]
@@ -45,8 +45,8 @@
 
   tOEMIdentification
     ulOEMDataOptionFlags:     0x00000000
-    aucOEMSerialNumber:       [ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ]
-    aucOEMOrderNumber:        [ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ]
+    aucOEMSerialNumber:       [  "2",  "3",  "4",  "5",  "6", 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ]
+    aucOEMOrderNumber:        [  "1",  "2",  "3",  "4",  ".",  "5",  "6",  "7", 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ]
     aucOEMHardwareRevision:   [ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ]
     aucOEMProductionDateTime: [ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ]
     aucOEMReservedFields:     [ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ]
...
```

### MAC encoding

Please note that a MAC address in JSON input can be specified in 2 ways. This is valid for patch files and complete FDL definitions in JSON.

The first solution uses a normal string, which is quite quikry. It must be 6 characters long and each character defines one byte of the MAC with its ASCII value. Example: the string "123456" would translate to the MAC 31:32:33:34:35:36 .
This solution is only reommended if you have some tool spitting out a JSON with a properly escaped string for the MAC. It is definitely not recommended for handcrafted JSONs.

The second solution is shown in above example. It is a human readable MAC in the form ```xx:xx:xx:xx:xx:xx``` .

## File type detection

The FDL tool tries to detect the type of files based on their suffix. ".json" files are JSON, ".txt" files are text and all others are assumed to be binary. This should do for most of the situations. For the special stuff you can force the input and output type with the ```--input-type``` and ```--output-type``` options. See the help message for the possible values.

## Padding of binary output

Sometimes an FDL does not live alone in it's flash sector. There might be other contents appended, like a taglist. In this case it is very handy to have the FDL padded to a defined size.

Padding can be activated with the ```-p```/```--pad``` option. The following example pads the FDL to a size of 1024 bytes.

```
brynhild@hidin:~/fdltool-0.0.2$ % ./lua5.4 fdltool.lua --patch demo/patch_mac_and_oem.json --pad 0x0400 demo/FDL_NXHX90-JTAG_7833000r3_UseCaseC.fdl patched.fdl
brynhild@hidin:~/fdltool-0.0.2$  % ls -l patched.fdl
-rw-rw-r-- 1 brynhild brynhild   1024 Jan 11 22:16 patched.fdl

```

Padding is done with 0xff by default. This is a good choice for all flash storages as erased sectors are filled with this pattern. Padding with 0xff just resembles unused space.
However you can change the padding byte with the option ```--padding-byte```.

# And what now?

* Replace those binary FDLs in your repositories with JSON.
* Use one FDL as a template in your production process and patch dynamic data like serial number and MAC addresses.
* Integrate this into Midnight Commander to display all ".fdl" files.

