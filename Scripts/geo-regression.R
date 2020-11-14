library(data.table)

demo_geo <- fread('./geo_regression/demographics_geo_data.csv')
bs_geo <- fread('./geo_regression/bikeshare_geo_data.csv')
green_geo <- fread('./geo_regression/green_geo_data.csv')
yellow_geo <- fread('./geo_regression/yellow_geo_data.csv')
rs_geo <- fread('./geo_regression/rideshare_geo_data.csv')
MTA_blanes_geo <- fread('./geo_regression/NTA_merge.csv')

comb_NTA <- merge(demo_geo,bs_geo,by.x='nta_code', by.y='nta_code', all.x=T)
comb_NTA <- merge(comb_NTA,green_geo,by.x='nta_code', by.y='pickup_nta', all.x=T)
comb_NTA <- merge(comb_NTA,yellow_geo,by.x='nta_code', by.y='pickup_nta', all.x=T)
comb_NTA <- merge(comb_NTA,rs_geo,by.x='nta_code', by.y='pickup_nta', all.x=T)
comb_NTA <- merge(comb_NTA,MTA_blanes_geo,by.x='nta_code', by.y='NTACode', all.x=T)

simple_NTA <- comb_NTA[!is.na(bs_number_rides)]
simple_NTA <-  simple_NTA[!is.na(yellow_num_rides)]
simple_NTA[, rides_per_pop := bs_number_rides/population]
simple_NTA[, rides_per_station := bs_number_rides/bs_number_startstation]
simple_NTA[, protected_prop := lane_protected/lane_total]
log(simple_NTA$yellow_med_dist)

dim(comb_NTA)
+ log(median_income)+ log(yellow_med_dist)


reduced_features_NTA <- simple_NTA[, .(rides_per_pop
                                       ,rides_prop=bs_number_rides/(rs_num_rides+subway_entries+yellow_num_rides+ifelse(is.na(green_num_rides),0,green_num_rides))
                                       ,bs_number_startstation
                                       ,median_age
                                       ,median_income
                                       ,lane_protected
                                       ,lane_total
                                       ,tot_other_transport=rs_num_rides+subway_entries+yellow_num_rides+ifelse(is.na(green_num_rides),0,green_num_rides)
                                       ,rs_prop_shared
                                       ,taxi_dist=(yellow_med_dist)
                                       ,taxi_cost=(yellow_med_cost))]

reduced_features_NTA[is.na(median_income),median_income:=mean(reduced_features_NTA$median_income,na.rm=T)] 
reduced_features_NTA[,high_vol := as.integer(rides_per_pop>mean(reduced_features_NTA$rides_per_pop))]

simple_reg <- lm(rides_per_pop ~ log(median_age)  + log(yellow_num_rides) +
                   log(yellow_med_cost)  + log(rs_num_rides) + rs_prop_shared +
                   lane_total + protected_prop + bs_number_startstation +
                   sqrt(subway_entries) + log(rs_num_rides), simple_NTA)


another_reg <- lm(rides_per_pop ~ -1 +
                    bs_number_startstation +
                    log(median_age) +
                    log(median_income)
                    # lane_protected/lane_total +
                    # lane_total
                    # log(tot_other_transport)
                    # rs_prop_shared +
                    # taxi_dist
                    # taxi_cost
                    , reduced_features_NTA)

summary(another_reg)

rides_prop_reg <- lm(rides_prop ~ 
                    bs_number_startstation +
                    # log(median_age) +
                    # log(median_income) +
                    # lane_protected +
                    lane_total +
                    log(tot_other_transport) +
                    rs_prop_shared +
                    taxi_dist +
                    taxi_cost
                  , reduced_features_NTA)

summary(rides_prop_reg)

rides_per_pop_logistic <- glm(high_vol ~ 
                       # bs_number_startstation +
                       # log(median_age) +
                       log(median_income) +
                       lane_protected +
                       lane_total +
                       log(tot_other_transport) +
                       # rs_prop_shared +
                       taxi_dist +
                       taxi_cost
                     , reduced_features_NTA
                     ,family=binomial('logit'))

summary(rides_per_pop_logistic)

