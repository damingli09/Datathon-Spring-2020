# -*- coding: utf-8 -*-
"""
Created on Sat Feb  8 01:02:21 2020

@author: michael
"""

import numpy as np
import matplotlib.pyplot as plt

data = np.loadtxt("geographic.csv", dtype= object, delimiter=',')
longs = (data[1::2]).astype(float)
lats = (data[2::2]).astype(float)
nta_codes = data[0]
mean_longs = np.mean(longs, axis=0)
mean_lats = np.mean(lats, axis=0)
def get_nta(longitude, latitude):
    indx_min = np.argmin(0.76**2. * (longitude-mean_longs)**2. + (latitude - mean_lats)**2.)
    return nta_codes[indx_min]

def get_dist(initial_long, initial_lat, final_long, final_lat):
    return (0.766*0.766*(initial_long-final_long)**2. + (initial_lat - final_lat)**2.)**(0.5) * 6378 * 2*np.pi/360.
