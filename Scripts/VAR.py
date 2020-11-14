import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import statsmodels.api as sm
import statsmodels
import pandas as pd
adf = statsmodels.tsa.stattools.adfuller
from statsmodels.tsa.api import VAR
from statsmodels.tsa.stattools import grangercausalitytests as granger
 
 
 
df = pd.read_csv('ts_clean.csv')
cols = df.columns.values
 #date	subway	weekday	uber	yellow	green	bikes	subscriber_frac	duration
 
exog = df[['temp', 'wind', 'rain', 'snow']]

df = df[['subway', 'uber', 'taxi', 'bikes']]
 
df['subway'] = np.log10(df['subway'])
df['uber'] = np.log10(df['uber'])
df['taxi'] = np.log10(df['taxi'])
df['bikes'] = np.log10(df['bikes'])

df_shift = (df - df.shift(5)).dropna()

for i in ['subway', 'uber', 'taxi', 'bikes']:
    print adf(df_shift[i])[1]
model = VAR(df, exog=exog)
results = model.fit(maxlags=2, ic='aic')
results.summary()
irf = results.irf(5)
irf.plot_cum_effects()
#plt.tight_layout()
#plt.savefig("OPEN.png")
#irf.plot_cum_effects(impulse='MIG', orth=False)

for i in ['subway', 'uber', 'taxi', 'bikes']:
    weekly = df['subway']