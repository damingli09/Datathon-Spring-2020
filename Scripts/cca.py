import numpy as np 
from sklearn.preprocessing import StandardScaler
from sklearn.cross_decomposition import CCA

def zScoreData(df, features):
    '''
    z-score features of DataFrame df using sklearn's StandardScaler
    Input: (Full) DataFrame df, List of feature names features
    Output: Numpy array X with each column z-Scored
    '''
    X = df.loc[:, features].values
    X = StandardScaler().fit_transform(X)
    return X

# check correlations between each variable pair beforehand
df.corr()

X = [[0., 0., 1.], [1.,0.,0.], [2.,2.,2.], [3.,5.,4.]]
Y = [[0.1, -0.2], [0.9, 1.1], [6.2, 5.9], [11.9, 12.3]]
cca = CCA(n_components=2)
cca.fit(X, Y)
X_c, Y_c = cca.transform(X, Y)

# print correlation between canonical variables
print(np.corrcoef(X_c[:,0].T, Y_c[:,0].T)[0,1])
print(np.corrcoef(X_c[:,1].T, Y_c[:,1].T)[0,1])

'''
The canonical correlation usually exceeds 
any of the individual correlations between 
a variable of the first set and a variable of the second set.
'''

# print canonical vectors
print(cca.x_weights_)
print(cca.y_weights_)