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

# This is the complete path to the testbench folder. The installation will be
# written there.
strCfg_workingFolder = os.path.join(
    strCfg_projectFolder,
    'targets',
    tPlatform['platform_id']
)

# Where is the jonchkihere tool?
strCfg_jonchkiHerePath = os.path.join(
    strCfg_projectFolder,
    'jonchki'
)
# This is the Jonchki version to use.
strCfg_jonchkiVersion = '0.0.6.1'
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

strCfg_jonchkiLog = os.path.join(
    strCfg_workingFolder,
    'jonchki.log'
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
strCfg_jonchkiPrepare = os.path.join(
    strCfg_projectFolder,
    'prepare.lua'
)
strCfg_jonchkiFinalizer = os.path.join(
    strCfg_projectFolder,
    'finalizer.lua'
)
strCfg_jonchkiDependencyLog = os.path.join(
    strCfg_projectFolder,
    'dependency-log.xml'
)
# This is the artifact configuration file.
# NOTE: this file will be created by the Jonchki prepare script.
strCfg_artifactConfiguration = 'fdltool.xml'

# -
# --------------------------------------------------------------------------

# Create the working folder if it does not exist yet.
if os.path.exists(strCfg_workingFolder) is not True:
    os.makedirs(strCfg_workingFolder)

if os.path.exists(strCfg_artifactConfiguration) is not True:
    raise Exception(
        'The artifact configuration "%s" does not exist.' %
        strCfg_artifactConfiguration
    )

# Install jonchki.
strJonchki = jonchkihere.install(
    strCfg_jonchkiVersion,
    strCfg_jonchkiInstallationFolder,
    LOCAL_ARCHIVES=strCfg_jonchkiLocalArchives
)

# Create the command line options for the selected platform.
astrJonchkiPlatform = cli_args.to_jonchki_args(tPlatform)

# Run jonchki.
sys.stdout.flush()
sys.stderr.flush()
astrArguments = [strJonchki]
astrArguments.append('install-dependencies')
astrArguments.extend(['-v', 'debug'])
astrArguments.extend(['--logfile', strCfg_jonchkiLog])
astrArguments.extend(['--syscfg', strCfg_jonchkiSystemConfiguration])
astrArguments.extend(['--prjcfg', strCfg_jonchkiProjectConfiguration])
astrArguments.extend(['--finalizer', strCfg_jonchkiFinalizer])
astrArguments.extend(['--dependency-log', strCfg_jonchkiDependencyLog])
astrArguments.extend(['--prepare', strCfg_jonchkiPrepare])
astrArguments.extend(astrJonchkiPlatform)
astrArguments.append(strCfg_artifactConfiguration)
sys.exit(subprocess.call(astrArguments, cwd=strCfg_workingFolder))
