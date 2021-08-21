# %%
import yaml
from MatrixConfig import *

# %%
# Fox network configuration
stream = open("FoxConfig.yaml", 'r')
configDict = yaml.safe_load(stream)

networkRows = configDict['networkRows']
networkCols = configDict['networkCols']

resultNodeCoord = configDict['resultNodeCoord']

totalMatrixSize = matrixSize

foxNetworkStages = configDict['foxNetworkStages']

coordBits = math.ceil(math.log2(max(networkRows, networkCols)))
multicastGroupBits = configDict['packetFormat']['multicastGroupBits']
doneFlagBits = configDict['packetFormat']['doneFlagBits']
resultFlagBits = configDict['packetFormat']['resultFlagBits']
matrixTypeBits = configDict['packetFormat']['matrixTypeBits']
matrixCoordBits = configDict['packetFormat']['matrixCoordBits']
matrixElementBits = configDict['packetFormat']['matrixElementBits']

# %%
# Firmware configuration
firmwareFolder = "fox_hoplite"

foxFirmware = "firmware_hoplite"
foxFirmwareMemSize = 4096

resultFirmware = "firmware_hoplite_result"
resultFirmwareMemSize = 8192
