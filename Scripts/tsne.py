import numpy as np 
import pandas as pd 
import matplotlib.pyplot as plt
from sklearn.preprocessing import StandardScaler
from sklearn.decomposition import PCA
from sklearn.manifold import TSNE

def zScoreData(df, features):
    '''
    z-score features of DataFrame df using sklearn's StandardScaler
    Input: (Full) DataFrame df, List of feature names features
    Output: Numpy array X with each column z-Scored
    '''
    X = df.loc[:, features].values
    X = StandardScaler().fit_transform(X)
    return X

def fitPCA(X, nPC = 5):
    '''
    Create and fit a PCA model to X defined above
    In practice, you may want to apply PCA before t-SNE
    Input: Numpy array X with dimension (n,p); int nPC number of PCs
    Output: Fitted PCA model; Principal components (projections of X in low-d space)
    '''
    pca = PCA(n_components=nPC)
    #pca = PCA(0.95)
    principalComponents = pca.fit_transform(X)
    return pca, principalComponents

def newDf(df, principalComponents):
    '''
    Transforming original df (features, target) into new df (PCs, target)
    Input: original df; principalComponents obtained through method fitPCA; target variable name targetVar
    '''
    principalDf = pd.DataFrame(data = principalComponents) 
    tsne = TSNE(n_components=2, verbose=1, perplexity=40, n_iter=300)
    tsne_results = tsne.fit_transform(principalDf)
    finalDf = pd.DataFrame(data = tsne_results, columns = ['TSNE1', 'TSNE2']) 
    return finalDf

def visualization(df, targetVar):
    '''
    Visualization of each category in the low-d space
    Input: DataFrame obtained through method newDf
    Output: Figure
    '''
    fig = plt.figure(figsize = (8,8))
    ax = fig.add_subplot(1,1,1) 
    ax.set_xlabel('t-SNE 2d 1', fontsize = 20)
    ax.set_ylabel('t-SNE 2d 2', fontsize = 20)
    targets = ['cat1', 'cat2', 'cat3'] # value of each category in the target variable
    colors = ['r', 'g', 'b']
    for target, color in zip(targets,colors):
        indicesToKeep = df[targetVar] == target # indices of that category
        ax.scatter(df.loc[indicesToKeep, 'TSNE1']
                , df.loc[indicesToKeep, 'TSNE2']
                , c = color
                , s = 50)
    ax.legend(targets)
    ax.grid()