import numpy as np 
import pandas as pd 
import matplotlib.pyplot as plt
from sklearn.preprocessing import StandardScaler
from sklearn.decomposition import PCA
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LogisticRegression

def zScoreData(df, features):
    '''
    z-score features of DataFrame df using sklearn's StandardScaler
    Input: (Full) DataFrame df, List of feature names features
    Output: Numpy array X with each column z-Scored
    '''
    X = df.loc[:, features].values
    X = StandardScaler().fit_transform(X)
    return X

def fitPCA(X, nPC = 2):
    '''
    Create and fit a PCA model to X defined above
    Input: Numpy array X with dimension (n,p); int nPC number of PCs
    Output: Fitted PCA model; Principal components (projections of X in low-d space)
    '''
    pca = PCA(n_components=nPC)
    principalComponents = pca.fit_transform(X)
    return pca, principalComponents

def varExplained(model):
    '''
    Input: Fitted sklearn PCA model 
    Output: Percentage of variance explained by each of the selected components.
    '''
    plt.plot(np.cumsum(pca.explained_variance_ratio_))
    plt.xlabel('number of components')
    plt.ylabel('cumulative explained variance')
    return model.explained_variance_ratio_

def principalVectors(model):
    '''
    Input: Fitted sklearn PCA model 
    Ouput: Principal axes (orthonormal vectors) in feature space, with shape (n_components, n_features)
    '''
    return model.components_

def loadings(model):
    '''
    Loadings are the covariances/correlations between the original variables and the unit-scaled components.
    Input: Fitted sklearn PCA model 
    Output: Loadings matrix of shape: (n_features, n_components)
    '''
    return model.components_.T * np.sqrt(model.explained_variance_)

def newDf(df, principalComponents, targetVar):
    '''
    Transforming original df (features, target) into new df (PCs, target)
    Input: original df; principalComponents obtained through method fitPCA; target variable name targetVar
    '''
    principalDf = pd.DataFrame(data = principalComponents
             , columns = ['PC1', 'PC2'])  # this depends on how many PCs are included
    finalDf = pd.concat([principalDf, df[[targetVar]]], axis = 1)
    return finalDf

def visualization(df, targetVar):
    '''
    Visualization of each category in the low-d space
    Input: DataFrame obtained through method newDf
    Output: Figure
    '''
    fig = plt.figure(figsize = (8,8))
    ax = fig.add_subplot(1,1,1) 
    ax.set_xlabel('Principal Component 1', fontsize = 20)
    ax.set_ylabel('Principal Component 2', fontsize = 20)
    targets = ['cat1', 'cat2', 'cat3'] # value of each category in the target variable
    colors = ['r', 'g', 'b']
    for target, color in zip(targets,colors):
        indicesToKeep = df[targetVar] == target # indices of that category
        ax.scatter(df.loc[indicesToKeep, 'PC1']
                , df.loc[indicesToKeep, 'PC2']
                , c = color
                , s = 50)
    ax.legend(targets)
    ax.grid()


######### Using PCA in a machine learning model

# train test split
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=17)

# Standardize data. Fit on training set only. Apply transform to both the training set and the test set.
scaler = StandardScaler()
scaler.fit(X_train)
X_train = scaler.transform(X_train)
X_test = scaler.transform(X_test)

# Create a PCA model that captures 95% of variance
pca = PCA(.95)
# Fit on training set only
pca.fit(X_train)
print(pca.n_components_) # print number of PCs
# Apply transform to both the training set and the test set.
X_train = pca.transform(X_train)
X_test = pca.transform(X_test)

########## Apply to a Logistic Regression model
LR = LogisticRegression(class_weight= None, solver = 'lbfgs')

LR.fit(X_train, y_train)
yhat = LR.predict(X_test)

print(LR.score(X_test, y_test)) 