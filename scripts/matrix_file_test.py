# %%
import numpy as np
from FoxNetwork import *

networkRows = 2
networkCols = 2

resultNodeCoord = {'x' : 0, 'y' : 0}

totalMatrixSize = 4

foxNetworkStages = 2

coordBits = 1
multicastGroupBits = 1
doneFlagBits = 1
resultFlagBits = 1
matrixTypeBits = 1
matrixCoordBits = 8
matrixElementBits = 32

foxNetwork = FoxNetwork(networkRows=networkRows, networkCols=networkCols, resultNodeCoord=resultNodeCoord, totalMatrixSize=totalMatrixSize, \
                    foxNetworkStages=foxNetworkStages, multicastGroupBits=multicastGroupBits, doneFlagBits=doneFlagBits, resultFlagBits=resultFlagBits, \
                    matrixTypeBits=matrixTypeBits, matrixCoordBits=matrixCoordBits)

# %%
A = np.array([[1, 1, 2, 2], [1, 1, 2, 2], [3, 3, 4, 4], [3, 3, 4, 4]])
B = np.array([[1, 1, 2, 2], [1, 1, 2, 2], [3, 3, 4, 4], [3, 3, 4, 4]])

foxNetwork.set_matrices(A=A, B=B)

foxNetwork.create_matrix_init_files()

# %%
