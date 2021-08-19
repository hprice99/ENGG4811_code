# %%
from FoxNetwork import *
from Firmware import *
from FoxConfig import *

# %%
# TODO Write script to take memory sizes from command line arguments
foxFirmware = Firmware(binaryName=foxFirmware, memSize=foxFirmwareMemSize)
resultFirmware = Firmware(binaryName=resultFirmware, memSize=resultFirmwareMemSize)

foxFirmware.write_assembly_file(firmwareFolder)
resultFirmware.write_assembly_file(firmwareFolder)

# %%
foxNetwork = FoxNetwork(networkRows=networkRows, networkCols=networkCols, \
            resultNodeCoord=resultNodeCoord, totalMatrixSize=totalMatrixSize, \
            foxNetworkStages=foxNetworkStages, \
            multicastGroupBits=multicastGroupBits,\
            doneFlagBits=doneFlagBits, resultFlagBits=resultFlagBits, \
            matrixTypeBits=matrixTypeBits, matrixCoordBits=matrixCoordBits, \
            foxFirmware=foxFirmware, resultFirmware=resultFirmware, A=A, B=B)

# %%
foxNetwork.create_matrix_init_files()

# %%
foxNetwork.write_header_file()

# %%
foxNetwork.write_matrix_config_file()

# %%
foxNetwork.write_firmware_config_file()
