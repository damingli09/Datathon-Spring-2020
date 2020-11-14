import numpy as np
import matplotlib.pyplot as plt

data = np.loadtxt("neighborhood_coords.csv",dtype=object, delimiter=',')
def get_nta(longitude, latitude):

    nta_codes = data[0]
    
    longs = (data[1::2]).astype(float)
    lats = (data[2::2]).astype(float)
    
    mean_longs = np.mean(longs, axis=0)
    mean_lats = np.mean(lats, axis=0)

    indx_min = np.argmin((longitude-mean_longs)**2. + (latitude - mean_lats)**2.)
    return nta_codes[indx_min]

bikes = np.genfromtxt("bike_lanes_raw.csv",delimiter=',').T
dist = (bikes[3]-bikes[1])**2. +  0.7660*(bikes[4]-bikes[2])**2.
bikes = (bikes.T)[np.where(dist < 0.1)].T
dist = (bikes[3]-bikes[1])**2. +  0.7660*(bikes[4]-bikes[2])**2.

nta_list, length_list, grade_list = [], [], []
for lane in bikes.T:

    nta = get_nta(lane[1], lane[2])
    seg_dist = ((lane[3]-lane[1])**2. + \
                0.7660*(lane[4]-lane[2])**2.)**(0.5) * 6378 * 2*np.pi/360.
    nta_list.append(nta)
    length_list.append(seg_dist)
    grade_list.append(lane[5])
    print nta, seg_dist
               
nta_list = np.asarray(nta_list)
length_list = np.asarray(length_list)
grade_list = np.asarray(grade_list)
all_nta_codes = np.loadtxt("neighborhood_coords.csv",dtype=object, delimiter=',')[0]
all_lengths = np.zeros(len(all_nta_codes))
first_lengths = np.zeros(len(all_nta_codes))
count = np.zeros(len(all_nta_codes))
for i in range(len(all_nta_codes)):
    all_lengths[i] = np.sum(length_list[nta_list == all_nta_codes[i]])
    first_lengths[i] =  np.sum(length_list[np.logical_and(nta_list == all_nta_codes[i], grade_list==1.0)])
    count[i] = len(length_list[nta_list == all_nta_codes[i]])
    print i, lengths[i], first_lengths[i]
    
out_data = np.asarray([range(195),all_nta_codes, count, first_lengths, all_lengths])
np.savetxt('bike_lanes_cleaned.csv', out_data, delimiter=',', fmt='%s')