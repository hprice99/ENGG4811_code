# %%
import sys
import yaml
import os

# %%
# Ensure that a command line argument is given (or the project is running in a Jupyter notebook)
try:
    ipy_str = str(type(get_ipython()))
    if 'zmqshell' in ipy_str or 'terminal' in ipy_str:
        # Running in Jupyter or iPython
        projectName = input("Enter project name: ")
except:
    # Running in terminal
    if len(sys.argv) < 2:
        projectName = input("Enter project name: ")
    elif len(sys.argv) > 2:
        raise Exception("Too many command line arguments given")
    else:
        projectName = sys.argv[1]

# Import YAML configuration for project
try:
    scriptLocation = os.path.realpath(__file__)
    scriptDirectory = os.path.dirname(scriptLocation)

    projectStream = open("{scriptDirectory}/{projectName}/ProjectConfig.yaml".format(scriptDirectory=scriptDirectory, projectName=projectName), 'r')
    projectConfig = yaml.safe_load(projectStream)
except:
    raise Exception("Project configuration could not be opened")

firmwareFolder = projectConfig['firmwareFolder']
hdlFolder = projectConfig['hdlFolder']

# %%
from FoxNetwork import *
from Firmware import *
from FoxConfig import *

config = FoxConfig(configFolder=projectName)
config.import_network_config()
config.import_firmware_config()

# %%
if config.foxFirmware is not None:
    foxFirmware = Firmware(name=config.foxFirmware, memSize=config.foxFirmwareMemSize)
    foxFirmware.write_assembly_file(firmwareFolder)
    foxFirmware.write_makefile_variables(firmwareFolder)
else:
    foxFirmware = None

if config.resultFirmware is not None:
    resultFirmware = Firmware(name=config.resultFirmware, memSize=config.resultFirmwareMemSize)
    resultFirmware.write_assembly_file(firmwareFolder)
    resultFirmware.write_makefile_variables(firmwareFolder)
else:
    resultFirmware = None

# %%
foxNetwork = FoxNetwork(networkRows=config.networkRows, \
                        networkCols=config.networkCols, \
                        resultNodeCoord=config.resultNodeCoord, \
                        romNodeCoord=config.romNodeCoord, \
                        totalMatrixSize=config.totalMatrixSize, \
                        foxNetworkStages=config.foxNetworkStages, \
                        multicastGroupBits=config.multicastGroupBits,\
                        multicastCoordBits=config.multicastCoordBits,\
                        doneFlagBits=config.doneFlagBits, \
                        resultFlagBits=config.resultFlagBits, \
                        matrixTypeBits=config.matrixTypeBits, \
                        matrixCoordBits=config.matrixCoordBits, \
                        foxFirmware=foxFirmware, \
                        resultFirmware=resultFirmware, \
                        A=A, \
                        B=B, \
                        useMatrixInitFile=config.useMatrixInitFile, \
                        multicastAvailable=config.multicastAvailable, \
                        useMulticast=config.useMulticast, \
                        multicastGroupNodes=config.multicastGroupNodes, \
                        multicastNetworkRows=config.multicastNetworkRows, \
                        multicastNetworkCols=config.multicastNetworkCols, \
                        multicastFifoDepth=config.multicastFifoDepth, \
                        foxNodeFifos=config.foxNodeFifos, \
                        resultNodeFifos=config.resultNodeFifos, \
                        resultUartFifoDepth=config.resultUartFifoDepth, \
                        hdlFolder=hdlFolder, \
                        firmwareFolder=firmwareFolder)

# %%
foxNetwork.create_matrix_init_files()

# %%
foxNetwork.write_packet_header_file()

# %%
foxNetwork.write_network_header_file()

# %%
foxNetwork.write_multicast_header_file()

# %%
foxNetwork.write_matrix_config_file()

# %%
foxNetwork.write_firmware_config_file()
