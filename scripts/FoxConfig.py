# %%
import numpy as np
import math

# %%
# Matix configuration
matrixSize = 4

A = np.random.randint(5, size=(matrixSize, matrixSize))
B = np.random.randint(5, size=(matrixSize, matrixSize))

print(A @ B)

# Fox network configuration
networkRows = 2
networkCols = 2

resultNodeCoord = {'x' : 0, 'y' : 0}

totalMatrixSize = matrixSize

foxNetworkStages = 2

coordBits = math.ceil(math.log2(max(networkRows, networkCols)))
multicastGroupBits = 1
doneFlagBits = 1
resultFlagBits = 1
matrixTypeBits = 1
matrixCoordBits = 8
matrixElementBits = 32

# %%
# Firmware configuration
firmwareFolder = "fox_hoplite"

foxFirmware = "firmware_hoplite.hex"
foxFirmwareMemSize = 4096

resultFirmware = "firmware_hoplite_result.hex"
resultFirmwareMemSize = 8192
