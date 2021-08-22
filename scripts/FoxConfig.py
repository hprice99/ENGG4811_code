# %%
import yaml
from MatrixConfig import *

# %%
# Fox network configuration
foxNetworkStream = open("FoxConfig.yaml", 'r')
foxConfig = yaml.safe_load(foxNetworkStream)

networkRows = foxConfig['networkRows']
networkCols = foxConfig['networkCols']

resultNodeCoord = foxConfig['resultNodeCoord']

totalMatrixSize = matrixSize

foxNetworkStages = foxConfig['foxNetworkStages']

coordBits = math.ceil(math.log2(max(networkRows, networkCols)))
multicastGroupBits = foxConfig['packetFormat']['multicastGroupBits']
doneFlagBits = foxConfig['packetFormat']['doneFlagBits']
resultFlagBits = foxConfig['packetFormat']['resultFlagBits']
matrixTypeBits = foxConfig['packetFormat']['matrixTypeBits']
matrixCoordBits = foxConfig['packetFormat']['matrixCoordBits']
matrixElementBits = foxConfig['packetFormat']['matrixElementBits']

useMatrixInitFile = foxConfig['useMatrixInitFile']

# %%
# Firmware configuration
firmwareStream = open("FirmwareConfig.yaml", 'r')
firmwareConfig = yaml.safe_load(firmwareStream)

firmwareFolder = firmwareConfig['firmwareFolder']

foxFirmware = firmwareConfig['foxFirmware']['name']
foxFirmwareMemSize = firmwareConfig['foxFirmware']['memory_size']

resultFirmware = firmwareConfig['resultFirmware']['name']
resultFirmwareMemSize = firmwareConfig['resultFirmware']['memory_size']
