# -*- coding: utf-8 -*-
# ----------------------------------------------------------------------- #
#   Copyright (C) 2017 by Christoph Thelen                                #
#   doc_bacardi@users.sourceforge.net                                     #
#                                                                         #
#   This program is free software; you can redistribute it and/or modify  #
#   it under the terms of the GNU General Public License as published by  #
#   the Free Software Foundation; either version 2 of the License, or     #
#   (at your option) any later version.                                   #
#                                                                         #
#   This program is distributed in the hope that it will be useful,       #
#   but WITHOUT ANY WARRANTY; without even the implied warranty of        #
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
#   GNU General Public License for more details.                          #
#                                                                         #
#   You should have received a copy of the GNU General Public License     #
#   along with this program; if not, write to the                         #
#   Free Software Foundation, Inc.,                                       #
#   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             #
# ----------------------------------------------------------------------- #

import argparse
import logging
import os
import platform
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile
import time
import zipfile

try:
    from urllib.request import urlopen
    from urllib.error import HTTPError
except ImportError:
    from urllib2 import urlopen, HTTPError


strDefaultJonchkiVersion = '0.0.6.1'


class ProgressOutput:
    # This is the minimum time between 2 flushes in seconds.
    m_tTimeMinimumFlushIntervall = 1.0
    m_tTimeLastFlushTime = 0

    # This is the size for one dot.
    m_sizDot = None

    # This is the total size of the file. 0 means the total size is unknown.
    m_sizTotal = 0

    # This is an internal state variable which records what has been printed
    # on a line yet.
    # 0 means it is a blank line
    # >0 is the number of dots printed.
    m_uiDotsPrintedInCurrentLine = 0
    m_uiDotsPerLine = 50
    # This is the download position at the start of the line in bytes.
    m_uiLinePositionStart = 0

    m_sizCurrent = None

    def __init__(self, sizTotal):
        # Set the size for one dot according to the total size.
        print('Size in bytes: %d' % sizTotal)
        if sizTotal == 0:
            # Unknown total size -> default to 2048.
            self.m_sizDot = 2048
        else:
            # Try to get a maximum of 20 lines at a maximum of 1MB dots.
            sizMaxLines = 20
            sizDot = sizTotal / self.m_uiDotsPerLine / sizMaxLines
            if sizDot > 1024 * 1024:
                sizDot = 1024 * 1024
            elif sizDot < 2048:
                sizDot = 2048
            self.m_sizDot = sizDot
        self.m_sizTotal = sizTotal
        self.m_tTimeLastFlushTime = time.time()
        self.m_uiDotsPrintedInCurrentLine = None
        self.m_sizCurrent = 0
        self.m_uiLinePositionStart = 0
        self.update(0)

    def update(self, sizData):
        # Print dots or header?
        fPrintDots = (sizData > 0) or (self.m_sizCurrent == 0)
        # Loop over all dots line by line.
        while fPrintDots is True:
            # Print a header if this is the start of the line.
            if self.m_uiDotsPrintedInCurrentLine is None:
                # Only print the percent information if the total size is
                # known.
                if self.m_sizTotal != 0:
                    # Get the new percentage.
                    uiPercent = 100.0 * self.m_sizCurrent / self.m_sizTotal
                    sys.stdout.write('% 3d%% ' % uiPercent)
                else:
                    sys.stdout.write('     ')
                self.m_uiDotsPrintedInCurrentLine = 0

            # Get the end position of the line in bytes.
            sizLineEnd = self.m_uiLinePositionStart
            sizLineEnd += int((self.m_uiDotsPerLine * self.m_sizDot) + 0.5)
            sizDownloaded = self.m_sizCurrent + sizData
            if sizLineEnd > sizDownloaded:
                sizLineEnd = sizDownloaded
            sizChunk = sizLineEnd - self.m_sizCurrent

            # Get the number of bytes in this line.
            sizDotBytes = sizLineEnd - self.m_uiLinePositionStart
            # Get the number of new dots in this line.
            sizDots = int((sizDotBytes / self.m_sizDot) + 0.5)
            sizDots -= self.m_uiDotsPrintedInCurrentLine
            # Print the new dots.
            sys.stdout.write('.' * sizDots)
            # Update the number of dots printed in this line.
            self.m_uiDotsPrintedInCurrentLine += sizDots

            # Print end of line if the maximum number of dots reached.
            if self.m_uiDotsPrintedInCurrentLine >= self.m_uiDotsPerLine:
                # Terminate the line.
                sys.stdout.write('\n')
                # A line feed is also a flush.
                self.m_tTimeLastFlushTime = time.time()
                # The next line has no dots yet.
                self.m_uiDotsPrintedInCurrentLine = None
                # Set the new line start position.
                self.m_uiLinePositionStart += (self.m_uiDotsPerLine *
                                               self.m_sizDot)

            self.m_sizCurrent += sizChunk
            sizData -= sizChunk
            # Print more?
            fPrintDots = (sizData > 0)

        # Flush the output stream.
        tLastFlush = time.time() - self.m_tTimeLastFlushTime
        if tLastFlush >= self.m_tTimeMinimumFlushIntervall:
            sys.stdout.flush()

    def finish(self):
        if self.m_uiDotsPrintedInCurrentLine is not None:
            # Terminate the line.
            sys.stdout.write('\n')


class PlatformDetect:
    def __init__(self):
        self.strHostCpuArchitecture = None
        self.strHostDistributionId = None
        self.strHostDistributionVersion = None
        self.strStandardArchiveFormat = None

    def __windows_get_cpu_architecture_env(self):
        strCpuArchitecture = None
        strEnvProcessorArchitecture = None
        strEnvProcessorArchiteW6432 = None
        if 'PROCESSOR_ARCHITECTURE' in os.environ:
            strEnvProcessorArchitecture = os.environ[
                'PROCESSOR_ARCHITECTURE'
            ].lower()
        if 'PROCESSOR_ARCHITEW6432' in os.environ:
            strEnvProcessorArchiteW6432 = os.environ[
                'PROCESSOR_ARCHITEW6432'
            ].lower()
        # See here for details: https://blogs.msdn.microsoft.com/david.wang/
        # 2006/03/27/howto-detect-process-bitness/
        if((strEnvProcessorArchitecture == 'amd64') or
           (strEnvProcessorArchiteW6432 == 'amd64')):
            strCpuArchitecture = 'x86_64'
        elif((strEnvProcessorArchitecture == 'x86') and
             (strEnvProcessorArchiteW6432 is None)):
            strCpuArchitecture = 'x86'
        else:
            print('Failed to detect the CPU architecture on Windows with the '
                  'ENV variables.')
            print('PROCESSOR_ARCHITECTURE = %s' %
                  (str(strEnvProcessorArchitecture)))
            print('PROCESSOR_ARCHITEW6432 = %s' %
                  (str(strEnvProcessorArchiteW6432)))

        return strCpuArchitecture

    def __linux_get_os_architecture_getconf(self):
        strCpuArchitecture = None

        # Try to parse the output of the 'getconf LONG_BIT' command.
        strOutput = subprocess.check_output(['getconf', 'LONG_BIT'])
        strOutputStrip = strOutput.strip()
        if strOutputStrip == '32':
            strCpuArchitecture = 'x86'
        elif strOutputStrip == '64':
            strCpuArchitecture = 'x86_64'

        return strCpuArchitecture

    def __linux_get_cpu_architecture_lscpu(self):
        strCpuArchitecture = None
        astrReplacements = {
            'i386': 'x86',
            'i486': 'x86',
            'i586': 'x86',
            'i686': 'x86'
        }

        # Try to parse the output of the 'lscpu' command.
        strOutput = subprocess.check_output(['lscpu']).decode(
            "utf-8",
            "replace"
        )
        tMatch = re.search(r'Architecture: *(\S+)', strOutput)
        if tMatch is None:
            raise Exception('Failed to get the CPU architecture with "lscpu".')

        strCpuArchitecture = tMatch.group(1)
        # Replace the CPU architectures found in the list.
        if strCpuArchitecture in astrReplacements:
            strCpuArchitecture = astrReplacements[strCpuArchitecture]

        return strCpuArchitecture

    def __linux_detect_distribution_etc_lsb_release(self):
        strDistributionId = None
        strDistributionVersion = None

        # Try to open /etc/lsb-release.
        tFile = open('/etc/lsb-release', 'rt')
        if tFile is None:
            raise Exception('Failed to detect the Linux distribution with '
                            '/etc/lsb-release.')
        for strLine in tFile:
            tMatch = re.match(r'DISTRIB_ID=(.+)', strLine)
            if tMatch is not None:
                strDistributionId = tMatch.group(1).lower()
            tMatch = re.match(r'DISTRIB_RELEASE=(.+)', strLine)
            if tMatch is not None:
                strDistributionVersion = tMatch.group(1)
        tFile.close()

        # Return both components or none.
        if (strDistributionId is None) or (strDistributionVersion is None):
            strDistributionId = None
            strDistributionVersion = None

        return strDistributionId, strDistributionVersion

    def detect(self):
        strSystem = platform.system()
        if strSystem == 'Windows':
            # This is windows.

            # Detect the CPU architecture.
            self.strHostCpuArchitecture =\
                self.__windows_get_cpu_architecture_env()

            # Set the distribution version and ID.
            self.strHostDistributionId = 'windows'
            self.strHostDistributionVersion = ''

            # Windows uses ZIP as standard archive format.
            self.strStandardArchiveFormat = 'zip'
        elif strSystem == 'Linux':
            # This is a Linux.

            # Detect the CPU architecture.
            # Prefer the OS architecture over the CPU architecture to honour a
            # 32bit OS on a 64bit CPU. This happens with a 32bit Docker
            # container on a 64bit host.
            strCpuArch = self.__linux_get_os_architecture_getconf()
            if strCpuArch is None:
                strCpuArch = self.__linux_get_cpu_architecture_lscpu()
            self.strHostCpuArchitecture = strCpuArch

            # Detect the distribution.
            self.strHostDistributionId, self.strHostDistributionVersion =\
                self.__linux_detect_distribution_etc_lsb_release()

            # Linux uses TAR GZIP as standard archive format.
            self.strStandardArchiveFormat = 'tar.gz'
        else:
            raise Exception('Unknown platform: "%s"' % (strSystem))


#
# Download the URL 'strUrl' to the file tFile.
#
# Returns 'True' on success, 'False' on error.
#
def download_to_file(strUrl, tFile):
    bResult = False
    fOutput = None
    sizDownloaded = 0

    try:
        aSocket = urlopen(strUrl)
        aInfo = aSocket.info()
        try:
            sizTotal = int(aInfo['content-length'])
        except KeyError:
            sizTotal = 0
        tProgress = ProgressOutput(sizTotal)

        while 1:
            strChunk = aSocket.read(2048)
            sizChunk = len(strChunk)
            if sizChunk == 0:
                break
            tFile.write(strChunk)
            sizDownloaded += sizChunk
            tProgress.update(sizChunk)

        tProgress.finish()
        bResult = True
    except HTTPError as e:
        print('Failed to download %s: %d' % (strUrl, e.code))

    if fOutput:
        fOutput.close()

    return bResult


def __check_jonchki_version(
    strID,
    strLua,
    strPath,
    strTool,
    strVersion,
    strCmdFile
):
    fFound = False
    strCmd = None
    if os.path.isdir(strPath) is not True:
        logging.info('The %s path does not exist.' % strID)
    else:
        logging.debug('The %s path exists.' % strID)

        if os.path.isfile(strTool) is not True:
            logging.info('The %s tool does not point to a file.' % strID)
        else:
            try:
                astrCmd = []
                if strLua is not None:
                    astrCmd.append(strLua)
                astrCmd.append(strTool)
                astrCmd.append('--version')
                strOutput = subprocess.check_output(
                    astrCmd,
                    shell=False
                ).decode("utf-8", "replace").strip()
                logging.debug('The %s tool reported the version string "%s".' %
                              (strID, strOutput))
            except subprocess.CalledProcessError:
                logging.debug('Failed to get the version from the %s tool.' %
                              strID)
                strOutput = ''
            tMatch = re.match(r'jonchki V(\d+.\d+.\d+.\d+)', strOutput)
            if tMatch is None:
                logging.debug('Failed to extract the version '
                              'from the %s output.' % strID)
            else:
                strFoundVersion = tMatch.group(1)
                logging.debug('The %s tool reported version %s.' % (
                    strID, strFoundVersion))
                if strVersion != strFoundVersion:
                    logging.debug(
                        'The reported version "%s" does not match the '
                        'requested version "%s".' % (
                            strFoundVersion,
                            strVersion
                        )
                    )
                else:
                    fFound = True
                    logging.info('%s v%s is installed.' % (strID, strVersion))

                    # Write the jonchki command to the CMD file.
                    if strLua is None:
                        strCmd = strTool
                    else:
                        strCmd = '%s %s' % (strLua, strTool)

                    if strCmdFile is not None:
                        tFile = open(strCmdFile, 'w')
                        tFile.write('%s\n' % strCmd)
                        tFile.close()

        if fFound is not True:
            logging.info('The path "%s" does not contain a useable %s '
                         'version.' % (strPath, strID))
            logging.info('Remove the path recursively.')

            # Recursively delete the jonchki folder.
            shutil.rmtree(strPath)

    return fFound, strCmd


def __extract_archive(tFile, strArchiveFormat, strOutputFolder):
    if strArchiveFormat == 'tar.gz':
        tArchive = tarfile.open(fileobj=tFile, mode='r')
        while 1:
            tInfo = tArchive.next()
            if tInfo is None:
                break
            strDstPath = os.path.join(strOutputFolder, tInfo.name)
            strRel = os.path.relpath(strDstPath, strOutputFolder)
            if strRel[0:2] == '..':
                raise Exception('Invalid archive member: "%s".' % (tInfo.name))
            tArchive.extract(tInfo, path=strOutputFolder)
        tArchive.close()

    elif strArchiveFormat == 'zip':
        tArchive = zipfile.ZipFile(tFile, 'r')
        atInfos = tArchive.infolist()
        for tInfo in atInfos:
            strDstPath = os.path.join(strOutputFolder, tInfo.filename)
            strRel = os.path.relpath(strDstPath, strOutputFolder)
            if strRel[0:2] == '..':
                raise Exception('Invalid archive member: "%s".' %
                                (tInfo.filename))
        tArchive.extractall(strOutputFolder)

    else:
        raise Exception('Unknown archive format: "%s".' % strArchiveFormat)


def install(strCfg_JonchkiVersion, strCfg_OutputFolder, **kwargs):
    strCfg_LocalArchivesFolder = None
    strCfg_LuaInterpreter = 'lua5.1'
    tCfg_LogLevel = logging.DEBUG

    # Parse the kwargs.
    for strKey, tValue in iter(kwargs.items()):
        if strKey == 'LOCAL_ARCHIVES':
            strCfg_LocalArchivesFolder = tValue
        elif strKey == 'LOG_LEVEL':
            tCfg_LogLevel = tValue
        elif strKey == 'LUA_INTERPRETER':
            strCfg_LuaInterpreter = tValue

    logging.basicConfig(level=tCfg_LogLevel)

    if(
        ('JONCHKI_VERSION_OVERWRITE' in os.environ) and
        (len(os.environ['JONCHKI_VERSION_OVERWRITE']) > 0)
    ):
        strCfg_JonchkiVersion = os.environ['JONCHKI_VERSION_OVERWRITE']
        logging.info(
            'Overwriting the jonchki version with the environment variable '
            '"JONCHKI_VERSION_OVERWRITE" to "%s".' % strCfg_JonchkiVersion
        )

    logging.info('Install jonchki v%s to %s.' %
                 (strCfg_JonchkiVersion, strCfg_OutputFolder))

    tPlatform = PlatformDetect()
    tPlatform.detect()
    logging.info('Host CPU architecture: %s' %
                 tPlatform.strHostCpuArchitecture)
    logging.info('Host distribution ID: %s' %
                 tPlatform.strHostDistributionId)
    logging.info('Host distribution version: %s' %
                 tPlatform.strHostDistributionVersion)
    logging.info('Standard archive format: %s' %
                 tPlatform.strStandardArchiveFormat)

    strJonchkiCmdFile = os.path.join(
        strCfg_OutputFolder,
        '.jonchki.cmd'
    )
    # Create the expected tool path.
    fFoundJonchki = False
    fFoundJonchkiLight = False
    strJonchkiPath = os.path.join(
        strCfg_OutputFolder,
        'jonchki-%s' % (strCfg_JonchkiVersion)
    )

    if tPlatform.strHostDistributionId == 'windows':
        strJonchkiTool = os.path.join(
            strJonchkiPath,
            'jonchki.bat'
        )
    else:
        strJonchkiTool = os.path.join(
            strJonchkiPath,
            'jonchki'
        )

    strJonchkiLightPath = os.path.join(
        strCfg_OutputFolder,
        'jonchki-light-%s' % (strCfg_JonchkiVersion)
    )
    strJonchkiLightTool = os.path.join(
        strJonchkiLightPath,
        'jonchki.lua'
    )
    logging.debug('Jonchki path: %s' % strJonchkiPath)
    logging.debug('Jonchki tool: %s' % strJonchkiTool)
    logging.debug('Jonchki-light path: %s' % strJonchkiLightPath)
    logging.debug('Jonchki-light tool: %s' % strJonchkiLightTool)

    fFoundJonchki, strJonchkiCmd = __check_jonchki_version(
        'jonchki',
        None,
        strJonchkiPath,
        strJonchkiTool,
        strCfg_JonchkiVersion,
        strJonchkiCmdFile
    )
    if fFoundJonchki is not True:
        fFoundJonchkiLight, strJonchkiCmd = __check_jonchki_version(
            'jonchki-light',
            strCfg_LuaInterpreter,
            strJonchkiLightPath,
            strJonchkiLightTool,
            strCfg_JonchkiVersion,
            strJonchkiCmdFile
        )

    if (fFoundJonchki is not True) and (fFoundJonchkiLight is not True):
        logging.info('The tool is not yet installed in the requested version.')

        astrReplace = {
            'HOST_CPU_ARCHITECTURE': tPlatform.strHostCpuArchitecture,
            'HOST_DISTRIBUTION_ID': tPlatform.strHostDistributionId,
            'HOST_DISTRIBUTION_VERSION': tPlatform.strHostDistributionVersion,
            'JONCHKI_VERSION': strCfg_JonchkiVersion,
            'ARCHIVE_EXTENSION': tPlatform.strStandardArchiveFormat
        }
        strLocalFileTemplate = (
            'jonchki-{JONCHKI_VERSION}-{HOST_DISTRIBUTION_ID}'
            '{HOST_DISTRIBUTION_VERSION}_{HOST_CPU_ARCHITECTURE}.'
            '{ARCHIVE_EXTENSION}'
        )
        strLightLocalFileTemplate = 'jonchki-light-{JONCHKI_VERSION}.zip'
        if(
            ('JONCHKI_URL_OVERWRITE' in os.environ) and
            (len(os.environ['JONCHKI_URL_OVERWRITE']) > 0)
        ):
            strUrlTemplate = os.environ['JONCHKI_URL_OVERWRITE']
            logging.info(
                'Overwriting the jonchki URL template with the environment '
                'variable "JONCHKI_URL_OVERWRITE" to "%s".' % strUrlTemplate
            )
        else:
            strUrlTemplate = (
                'https://github.com/muhkuh-sys/org.muhkuh.lua-jonchki/'
                'releases/download/v{JONCHKI_VERSION}/jonchki-'
                '{JONCHKI_VERSION}-'
                '{HOST_DISTRIBUTION_ID}{HOST_DISTRIBUTION_VERSION}_'
                '{HOST_CPU_ARCHITECTURE}.{ARCHIVE_EXTENSION}'
            )
        if(
            ('JONCHKI_LIGHT_URL_OVERWRITE' in os.environ) and
            (len(os.environ['JONCHKI_LIGHT_URL_OVERWRITE']) > 0)
        ):
            strLightUrlTemplate = os.environ['JONCHKI_LIGHT_URL_OVERWRITE']
            logging.info(
                'Overwriting the jonchki-light URL template with the '
                'environment variable "JONCHKI_LIGHT_URL_OVERWRITE" to "%s".' %
                strLightUrlTemplate
            )
        else:
            strLightUrlTemplate = (
                'https://github.com/muhkuh-sys/org.muhkuh.lua-jonchki/'
                'releases/download/v{JONCHKI_VERSION}/jonchki-light-'
                '{JONCHKI_VERSION}.zip'
            )
        strLocalFile = strLocalFileTemplate.format(**astrReplace)
        strUrl = strUrlTemplate.format(**astrReplace)
        strLightLocalFile = strLightLocalFileTemplate.format(**astrReplace)
        strLightUrl = strLightUrlTemplate.format(**astrReplace)

        # Does the local file already exist?
        tFile = None
        strArchiveFormat = None
        if strCfg_LocalArchivesFolder is not None:
            # Search the full version first, then the light version.
            strAbsFile = os.path.join(strCfg_LocalArchivesFolder, strLocalFile)
            if os.path.exists(strAbsFile) is True:
                logging.info('Found the requested version in the local files '
                             'folder.')
                tFile = open(strAbsFile, 'rb')
                fFoundJonchki = True
                strArchiveFormat = tPlatform.strStandardArchiveFormat
            else:
                strAbsFile = os.path.join(
                    strCfg_LocalArchivesFolder,
                    strLightLocalFile
                )
                if os.path.exists(strAbsFile) is True:
                    logging.info('Found the requested light version in the '
                                 'local files folder.')
                    tFile = open(strAbsFile, 'rb')
                    fFoundJonchkiLight = True
                    strArchiveFormat = 'zip'

        if tFile is None:
            # Download the archive to a temporary file.
            logging.info('Trying to download "%s".' % strUrl)
            tFile = tempfile.TemporaryFile()
            tResult = download_to_file(strUrl, tFile)
            if tResult is True:
                tFile.seek(0, 0)
                fFoundJonchki = True
                strArchiveFormat = tPlatform.strStandardArchiveFormat
            else:
                # Close the old temporary file.
                tFile.close()

                logging.info('Trying to download "%s".' % strLightUrl)
                tFile = tempfile.TemporaryFile()
                tResult = download_to_file(strLightUrl, tFile)
                if tResult is True:
                    tFile.seek(0, 0)
                    fFoundJonchkiLight = True
                    strArchiveFormat = 'zip'
                else:
                    tFile.close()
                    raise Exception('Failed to download the full and the '
                                    'light version.')

        # Extract the archive contents to the destination folder.
        __extract_archive(tFile, strArchiveFormat, strCfg_OutputFolder)
        tFile.close()

        # Is the extracted version valid?
        if fFoundJonchki is True:
            fFoundJonchki, strJonchkiCmd = __check_jonchki_version(
                'jonchki',
                None,
                strJonchkiPath,
                strJonchkiTool,
                strCfg_JonchkiVersion,
                strJonchkiCmdFile
            )
        elif fFoundJonchkiLight is True:
            fFoundJonchkiLight, strJonchkiCmd = __check_jonchki_version(
                'jonchki-light',
                strCfg_LuaInterpreter,
                strJonchkiLightPath,
                strJonchkiLightTool,
                strCfg_JonchkiVersion,
                strJonchkiCmdFile
            )

    return strJonchkiCmd


if __name__ == '__main__':
    tParser = argparse.ArgumentParser(
        description='Install a jonchki version to a local folder.'
    )
    tParser.add_argument(
        'strOutputFolder',
        metavar='OUTPUT_FOLDER',
        help='Install the jonchki tool to the folder OUTPUT_FOLDER.'
    )
    tParser.add_argument(
        '-j', '--jonchki-version',
        dest='strJonchkiVersion',
        default=strDefaultJonchkiVersion,
        metavar='VERSION',
        help='Install version VERSION of the jonchki tool. '
             '(default is %s)' % strDefaultJonchkiVersion
    )
    tParser.add_argument(
        '-l', '--local-archives',
        dest='strLocalArchivesFolder',
        default=None,
        metavar='PATH',
        help='Look in PATH for the jonchki archives before downloading them.'
    )
    tParser.add_argument(
        '-i', '--lua-interpreter',
        dest='strLuaInterpreter',
        default='lua5.1',
        metavar='PATH',
        help='Use the LUA interpreter in PATH to run the jonchki-light tool.'
    )

    atArgs = tParser.parse_args()

    strCfg_OutputFolder = atArgs.strOutputFolder
    strCfg_JonchkiVersion = atArgs.strJonchkiVersion
    strCfg_LocalArchivesFolder = atArgs.strLocalArchivesFolder
    strCfg_LuaInterpreter = atArgs.strLuaInterpreter

    install(
        strCfg_JonchkiVersion,
        strCfg_OutputFolder,
        LOCAL_ARCHIVES=strCfg_LocalArchivesFolder,
        LUA_INTERPRETER=strCfg_LuaInterpreter
    )
