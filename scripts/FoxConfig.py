# %%
import yaml
from MatrixConfig import *
import os

class FoxConfig:
    def __init__(self, *, configFolder):
        self.configFolder = configFolder
        
        scriptLocation = os.path.realpath(__file__)
        self.scriptDirectory = os.path.dirname(scriptLocation)
        
    # Fox network configuration
    def import_network_config(self):
        foxNetworkStream = open("{scriptDirectory}/{configFolder}/FoxConfig.yaml".format(scriptDirectory=self.scriptDirectory, configFolder=self.configFolder), 'r')
        foxConfig = yaml.safe_load(foxNetworkStream)

        self.networkRows = foxConfig['networkRows']
        self.networkCols = foxConfig['networkCols']

        self.resultNodeCoord = foxConfig['resultNodeCoord']
        self.romNodeCoord = foxConfig['romNodeCoord']

        self.totalMatrixSize = matrixSize

        self.foxNetworkStages = foxConfig['foxNetworkStages']

        self.coordBits = math.ceil(math.log2(max(self.networkRows, self.networkCols)))
        self.multicastGroupBits = foxConfig['packetFormat']['multicastGroupBits']
        self.multicastCoordBits = foxConfig['packetFormat']['multicastCoordBits']
        self.doneFlagBits = foxConfig['packetFormat']['doneFlagBits']
        self.resultFlagBits = foxConfig['packetFormat']['resultFlagBits']
        self.matrixTypeBits = foxConfig['packetFormat']['matrixTypeBits']
        self.matrixCoordBits = foxConfig['packetFormat']['matrixCoordBits']
        self.matrixElementBits = foxConfig['packetFormat']['matrixElementBits']

        self.useMatrixInitFile = foxConfig['useMatrixInitFile']

        self.useMulticast = foxConfig['useMulticast']

        if self.useMulticast == True:
            self.multicastGroupNodes = foxConfig['multicastConfig']['multicastGroupNodes']
            self.multicastNetworkRows = foxConfig['multicastConfig']['multicastNetworkRows']
            self.multicastNetworkCols = foxConfig['multicastConfig']['multicastNetworkCols']
        else:
            self.multicastGroupNodes = 0
            self.multicastNetworkRows = 0
            self.multicastNetworkCols = 0

    # Firmware configuration
    def import_firmware_config(self):
        firmwareStream = open("{scriptDirectory}/{configFolder}/FirmwareConfig.yaml".format(scriptDirectory=self.scriptDirectory, configFolder=self.configFolder), 'r')
        firmwareConfig = yaml.safe_load(firmwareStream)

        self.foxFirmware = firmwareConfig['foxFirmware']['name']
        self.foxFirmwareMemSize = firmwareConfig['foxFirmware']['memory_size']

        self.resultFirmware = firmwareConfig['resultFirmware']['name']
        self.resultFirmwareMemSize = firmwareConfig['resultFirmware']['memory_size']
