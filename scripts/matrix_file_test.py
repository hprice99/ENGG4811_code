# %%
import numpy as np
import math
from FoxNetwork import *

networkRows = 2
networkCols = 2

resultNodeCoord = {'x' : 0, 'y' : 0}

totalMatrixSize = 4

foxNetworkStages = 2

coordBits = math.ceil(math.log2(max(networkRows, networkCols)))
multicastGroupBits = 1
doneFlagBits = 1
resultFlagBits = 1
matrixTypeBits = 1
matrixCoordBits = 8
matrixElementBits = 32

foxNetwork = FoxNetwork(networkRows=networkRows, networkCols=networkCols, \
            resultNodeCoord=resultNodeCoord, totalMatrixSize=totalMatrixSize, \
            foxNetworkStages=foxNetworkStages, \
            multicastGroupBits=multicastGroupBits,\
            doneFlagBits=doneFlagBits, resultFlagBits=resultFlagBits, \
            matrixTypeBits=matrixTypeBits, matrixCoordBits=matrixCoordBits)

# %%
A = np.array([[1, 2, 2, 3], [3, 4, 4, 5], [5, 6, 6, 7], [7, 8, 8, 9]])
B = np.array([[4, 4, 6, 6], [4, 4, 6, 6], [8, 8, 10, 10], [8, 8, 10, 10]])

foxNetwork.set_matrices(A=A, B=B)

foxNetwork.create_matrix_init_files()

# %%
foxNetwork.write_header_file()

# %%
foxNetwork.write_matrix_config_file()
