# %%
from FoxNetwork import *
from Firmware import *
from FoxConfig import *

# %%
# TODO Write script to take memory sizes from command line arguments
foxFirmware = Firmware(name=foxFirmware, memSize=foxFirmwareMemSize)
resultFirmware = Firmware(name=resultFirmware, memSize=resultFirmwareMemSize)

foxFirmware.write_assembly_file(firmwareFolder)
resultFirmware.write_assembly_file(firmwareFolder)

# %%
foxFirmware.write_makefile_variables(firmwareFolder)
resultFirmware.write_makefile_variables(firmwareFolder)

# %%
foxNetwork = FoxNetwork(networkRows=networkRows, networkCols=networkCols, \
            resultNodeCoord=resultNodeCoord, totalMatrixSize=totalMatrixSize, \
            foxNetworkStages=foxNetworkStages, \
            multicastGroupBits=multicastGroupBits,\
            doneFlagBits=doneFlagBits, resultFlagBits=resultFlagBits, \
            matrixTypeBits=matrixTypeBits, matrixCoordBits=matrixCoordBits, \
            foxFirmware=foxFirmware, resultFirmware=resultFirmware, A=A, B=B, \
            useMatrixInitFile=useMatrixInitFile)

# %%
foxNetwork.create_matrix_init_files()

# %%
foxNetwork.write_header_file()

# %%
foxNetwork.write_matrix_config_file()

# %%
foxNetwork.write_firmware_config_file()
