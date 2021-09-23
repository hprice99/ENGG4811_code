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

        self.foxNetworkStages = foxConfig['foxNetworkStages']

        self.totalMatrixSize = matrixSize
        totalMatrixElements = self.totalMatrixSize ** 2

        foxMatrixSize = int(self.totalMatrixSize / self.foxNetworkStages)
        foxMatrixElements = foxMatrixSize ** 2

        self.coordBits = math.ceil(math.log2(max(self.networkRows, self.networkCols)))
        self.multicastGroupBits = foxConfig['packetFormat']['multicastGroupBits']
        self.multicastCoordBits = foxConfig['packetFormat']['multicastCoordBits']
        self.doneFlagBits = foxConfig['packetFormat']['doneFlagBits']
        self.resultFlagBits = foxConfig['packetFormat']['resultFlagBits']
        self.matrixTypeBits = foxConfig['packetFormat']['matrixTypeBits']
        self.matrixCoordBits = foxConfig['packetFormat']['matrixCoordBits']
        self.matrixElementBits = foxConfig['packetFormat']['matrixElementBits']

        self.useMatrixInitFile = foxConfig['useMatrixInitFile']

        if 'multicastAvailable' in foxConfig:
            self.multicastAvailable = foxConfig['multicastAvailable']
        else:
            self.multicastAvailable = False

        if self.multicastAvailable == True:
            self.useMulticast = foxConfig['useMulticast']
        else:
            self.useMulticast = False

        if self.useMulticast == True:
            self.multicastGroupNodes = foxConfig['multicastConfig']['multicastGroupNodes']
            self.multicastNetworkRows = foxConfig['multicastConfig']['multicastNetworkRows']
            self.multicastNetworkCols = foxConfig['multicastConfig']['multicastNetworkCols']

            if 'multicastFifoDepth' in foxConfig['multicastConfig']:
                self.multicastFifoDepth = foxConfig['multicastConfig']['multicastFifoDepth']
            else:
                self.multicastFifoDepth = foxMatrixSize
        else:
            self.multicastGroupNodes = 0
            self.multicastNetworkRows = 0
            self.multicastNetworkCols = 0
            self.multicastFifoDepth = 0
            
        # FIFO configuration
        self.foxNodeFifos = {'peToNetwork': 2 * foxMatrixElements,
                                'networkToPe' : 2 * foxMatrixElements}

        if 'foxNodeFifos' in foxConfig:
            if 'peToNetwork' in foxConfig['foxNodeFifos']:
                self.foxNodeFifos['peToNetwork'] = foxConfig['foxNodeFifos']['peToNetwork']
            
            if 'networkToPe' in foxConfig['foxNodeFifos']:
                self.foxNodeFifos['networkToPe'] = foxConfig['foxNodeFifos']['networkToPe']

        self.resultNodeFifos = {'peToNetwork': 2 * totalMatrixElements,
                                'networkToPe' : 2 * totalMatrixElements}

        if 'resultNodeFifos' in foxConfig:
            if 'peToNetwork' in foxConfig['resultNodeFifos']:
                self.resultNodeFifos['peToNetwork'] = foxConfig['resultNodeFifos']['peToNetwork']
            
            if 'networkToPe' in foxConfig['resultNodeFifos']:
                self.resultNodeFifos['networkToPe'] = foxConfig['resultNodeFifos']['networkToPe']

        self.resultUartFifoDepth = foxConfig['resultUartFifoDepth']

    # Firmware configuration
    def import_firmware_config(self):
        firmwareStream = open("{scriptDirectory}/{configFolder}/FirmwareConfig.yaml".format(scriptDirectory=self.scriptDirectory, configFolder=self.configFolder), 'r')
        firmwareConfig = yaml.safe_load(firmwareStream)

        self.foxFirmware = firmwareConfig['foxFirmware']['name']
        self.foxFirmwareMemSize = firmwareConfig['foxFirmware']['memory_size']

        self.resultFirmware = firmwareConfig['resultFirmware']['name']
        self.resultFirmwareMemSize = firmwareConfig['resultFirmware']['memory_size']
