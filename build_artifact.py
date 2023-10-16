#! /usr/bin/python3

from jonchki import cli_args
from jonchki import jonchkihere

import os
import subprocess
import sys


tPlatform = cli_args.parse()
print('Building for %s' % tPlatform['platform_id'])


# --------------------------------------------------------------------------
# -
# - Configuration
# -

# Get the project folder. This is the folder of this script.
strCfg_projectFolder = os.path.dirname(os.path.realpath(__file__))

# This is the Jonchki version to use.
strCfg_jonchkiVersion = '0.0.11.1'
# Look in this folder for Jonchki archives before downloading them.
strCfg_jonchkiLocalArchives = os.path.join(
    strCfg_projectFolder,
    'jonchki',
    'local_archives'
)
# The target folder for the jonchki installation. A subfolder named
# "jonchki-VERSION" will be created there. "VERSION" will be replaced with
# the version number from strCfg_jonchkiVersion.
strCfg_jonchkiInstallationFolder = os.path.join(
    strCfg_projectFolder,
    'targets'
)

strCfg_jonchkiSystemConfiguration = os.path.join(
    strCfg_projectFolder,
    'jonchki',
    'jonchkisys.cfg'
)
strCfg_jonchkiProjectConfiguration = os.path.join(
    strCfg_projectFolder,
    'jonchki',
    'jonchkicfg.xml'
)
strCfg_jonchkiFinalizer = os.path.join(
    strCfg_projectFolder,
    'finalizer.lua'
)
strCfg_jonchkiDependencyLog = os.path.join(
    strCfg_projectFolder,
    'dependency-log.xml'
)

# -
# --------------------------------------------------------------------------

# Install jonchki.
strJonchki = jonchkihere.install(
    strCfg_jonchkiVersion,
    strCfg_jonchkiInstallationFolder,
    LOCAL_ARCHIVES=strCfg_jonchkiLocalArchives
)
sys.stdout.flush()
sys.stderr.flush()

# Create the command line options for the selected platform.
astrJonchkiPlatform = cli_args.to_jonchki_args(tPlatform)

# Get the working folder for the test variant.
strWorkingFolder = os.path.join(
    strCfg_projectFolder,
    'targets',
    tPlatform['platform_id']
)


  # Create the working folder if it does not exist yet.
if os.path.exists(strWorkingFolder) is not True:
    os.makedirs(strWorkingFolder)

astrArguments = [strJonchki]
astrArguments.append('install-dependencies')
astrArguments.extend(['-v', 'debug'])
astrArguments.extend(['--project-root', strCfg_projectFolder])
astrArguments.extend([
    '--logfile',
    os.path.join(strWorkingFolder, 'jonchki.log')
])
astrArguments.extend(['--syscfg', strCfg_jonchkiSystemConfiguration])
astrArguments.extend(['--prjcfg', strCfg_jonchkiProjectConfiguration])
astrArguments.extend([
    '--dependency-log',
    os.path.join(
        strCfg_projectFolder,
        'dependency-log.xml'
    )
])
astrArguments.extend([
    '--prepare',
    os.path.join(
        strCfg_projectFolder,
        'prepare.lua'
    )
])
astrArguments.extend(astrJonchkiPlatform)
astrArguments.append('fdltool.xml')
subprocess.check_call(astrArguments, cwd=strWorkingFolder)
