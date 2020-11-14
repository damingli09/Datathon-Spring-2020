#### Loading packages ####
library(data.table)
library(lubridate)
library(ggplot2)
library(stringr)

#### Plot add-ons ####

plot_theme <- theme_minimal(12) +    
  theme(axis.text.y = element_text(size = rel(1)),
        axis.ticks.y = element_blank(),
        panel.grid.major.x = element_blank(),
        panel.grid.major.y = element_line(size = 0.5),
        panel.grid.minor.x = element_blank())

caption_source <- labs(caption="Note: ")

mid_line <- geom_hline(yintercept=.5)

sample_plot <- ggplot(sample_DT) +
  geom_line(aes(x=x, y=y)) +
  scale_x_continuous(limits = c(1,100)) +
  scale_y_continuous(limits = c(1,100), labels=scales::percent_format(2)) +
  labs(title="Placeholder"
       ,x="Placeholder"
       ,y="Placeholder") +
  caption_source +
  plot_theme

#### Loading data ####

bike_rides <- fread('./East Coast Datathon Materials/nyc_bikeshare.csv')
bike_rides[,lapply(.SD,class)]

bike_rides[,stoptime:=NULL]
bike_rides[,startime2:=mdy_hms(starttime)]


bike_rides[,.(sub_rides=sum(usertype,na.rm=T),.N)][,.(sub_rides,N,prop=sub_rides/N)]
bike_rides[wday(startime2)<=6 & wday(startime2)>=2,.(sub_rides=sum(usertype,na.rm=T),.N)][,.(sub_rides,N,prop=sub_rides/N)]

bike_rides[,.N,by=.(wday(startime2),wday(startime2,label=T))]

wday(bike_rides[1,startime2])

bike_rides[,.N,by=gender]

bike_rides[,.N,by=is.na(birthyear)]  
bike_rides[is.na(gender)]

bike_rides[,.N,by=birthyear][order(birthyear)]


#### Rideshare data ####

nyc_rideshare <- fread('./East Coast Datathon Materials/nyc_rideshare.csv')
tlc_zones <- fread('./East Coast Datathon Materials/legends/tlc_zones.csv')


### Quick checks
nyc_rideshare[,lapply(.SD,class)]
nyc_rideshare[,.N]

nyc_rideshare[,lapply(.SD,function(x){sum(is.na(x))})]
# ~5% of rows missing pickup location --> drop them

nyc_rideshare[pickup_datetime =='',.N] # None missing
nyc_rideshare[dropoff_datetime =='',.N] # 4,811,388; ~30%

nyc_rideshare[,.N,by=shared_ride] # Assume NA means no

nyc_rideshare[is.na(pickup_location_id),.N]
nyc_rideshare[is.na(dropoff_location_id) | is.na(pickup_location_id),.N]

### Actual stuff

# Cleaning columns
nyc_rideshare[,dropoff_datetime := NULL]
nyc_rideshare[is.na(shared_ride),shared_ride := 0]
nyc_rideshare[,pickup_datetime := mdy_hms(pickup_datetime)]

# Filtering out stuff & creating timeseries output

nyc_rideshare <- nyc_rideshare[wday(pickup_datetime)<=6 & wday(pickup_datetime)>=2 & 
                ((hour(pickup_datetime)>=6 & hour(pickup_datetime) <=10) | (hour(pickup_datetime)>=15 & hour(pickup_datetime) <=19))]

nyc_rideshare_full_ts <- nyc_rideshare[,.(rides=.N),by=.(date=as_date(pickup_datetime))][order(date)]

write.csv(nyc_rideshare_full_ts,'nyc-rideshare-full-ts-clean.csv')

ggplot(nyc_rideshare_full_ts) +
  geom_line(aes(x=date,y=rides))

### Moving to geographic analysis
nyc_rideshare <- nyc_rideshare[year(pickup_datetime)==2017]

# Left with 1.3M
nyc_rideshare[is.na(pickup_location_id),.N] # 112K
nyc_rideshare[is.na(dropoff_location_id) | is.na(pickup_location_id),.N] # 570K

# Remove NA pickup location; then we'll estimate distance with what we have; and pair it with total count
nyc_rideshare <- nyc_rideshare[!is.na(pickup_location_id)]

# Down to 5.4M

# Pulling in NTA code
nyc_rideshare <- merge(nyc_rideshare, tlc_zones[,.(location_id,nta_code)], by.x = 'pickup_location_id', by.y = 'location_id', all.x = T, all.y=F)
colnames(nyc_rideshare)[6] <- 'pickup_nta'
nyc_rideshare <- merge(nyc_rideshare, tlc_zones[,.(location_id,nta_code)], by.x = 'dropoff_location_id', by.y = 'location_id', all.x = T, all.y=F)
colnames(nyc_rideshare)[7] <- 'dropoff_nta'


# output w/o distance

geo_rs_no_dist <- nyc_rideshare[,.(num_rideshare_rides=.N,prop_shared=sum(shared_ride)/.N), by=pickup_nta][!is.na(pickup_nta)]

# Calculating distances
distinct_from_to <- nyc_rideshare[!is.na(pickup_nta) & !is.na(dropoff_nta),.N,by=.(pickup_nta,dropoff_nta)]

# NTA code to location
NTA_codes <- fread('./East Coast Datathon Materials/legends/geographic.csv')
NTA_codes[,coord:=rep(c('lon','lat'),NTA_codes[,.N]/2)]

long_mean_codes <- melt(NTA_codes, id.vars='coord', variable.name = 'NTA')[,.(mean_val=mean(value,na.rm=T)),by=.(coord,NTA)]

mean_cods <- dcast(long_mean_codes, NTA ~ coord)

distinct_from_to <- merge(distinct_from_to[,1:2], mean_cods, by.x='pickup_nta', by.y='NTA')
colnames(distinct_from_to)[3:4] <- c('pickup_lat','pickup_lon')

distinct_from_to <- merge(distinct_from_to, mean_cods, by.x='dropoff_nta', by.y='NTA')
colnames(distinct_from_to)[5:6] <- c('dropoff_lat','dropoff_lon')

distinct_from_to[,distance := ((dropoff_lat-pickup_lat)^2 + .766^2 * (dropoff_lat-pickup_lat)^2)^(1/2)*6378*2*pi/360]

from_to_distance <- distinct_from_to[,.(dropoff_nta,pickup_nta,distance)]

# Merging it together

nyc_rideshare_w_dist <- merge(nyc_rideshare,from_to_distance,by=c('dropoff_nta','pickup_nta'))

nyc_rideshare_w_dist[,.N]
nyc_rideshare_w_dist[distance==0,.N] # 10% of rides have 0 distance

# Combining

geo_rs_dist <- nyc_rideshare_w_dist[,.(num_rideshares_w_dist=.N,mean_dist=mean(distance),med_distance=median(distance)), by = .(pickup_nta)]


geo_rs_w_dist <- merge(geo_rs_no_dist, geo_rs_dist, by='pickup_nta', all.x=T)

fwrite(geo_rs_w_dist,'rideshare_geo_data.csv')


#### Yellow Taxis ####

nyc_yello <- fread('./East Coast Datathon Materials/nyc_yellow_taxi.csv')

nyc_yello[,dropoff_datetime:=NULL]
nyc_yello[,pickup_datetime:=mdy_hms(pickup_datetime)]

nyc_yello <- nyc_yello[year(pickup_datetime)==2017]

nyc_yello <- nyc_yello[wday(pickup_datetime)<=6 & wday(pickup_datetime)>=2 & 
                         ((hour(pickup_datetime)>=6 & hour(pickup_datetime) <=10) | (hour(pickup_datetime)>=15 & hour(pickup_datetime) <=19))]

nyc_yello[,pickup_longitude:=NULL]
nyc_yello[,pickup_latitude:=NULL]
nyc_yello[,dropoff_longitude:=NULL]
nyc_yello[,dropoff_latitude:=NULL]

nyc_yello[is.na(dropoff_location_id)]

nyc_yello <- merge(nyc_yello, tlc_zones[,.(location_id,nta_code)], by.x = 'pickup_location_id', by.y = 'location_id', all.x = T, all.y=F)
colnames(nyc_yello)[7] <- 'pickup_nta'
nyc_yello <- merge(nyc_yello, tlc_zones[,.(location_id,nta_code)], by.x = 'dropoff_location_id', by.y = 'location_id', all.x = T, all.y=F)
colnames(nyc_yello)[8] <- 'dropoff_nta'

# Creating output
geo_yellow <- nyc_yello[,.(yellow_num_rides=.N
                           ,yellow_med_pass=median(passenger_count,na.rm=T)
                           ,yellow_med_dist=median(trip_distance,na.rm=T)
                           ,yellow_avg_cost=mean(total_amount,na.rm=T)
                           ,yellow_med_cost=median(total_amount,na.rm=T))
                        ,by=pickup_nta]

fwrite(geo_yellow, 'yellow_geo_data.csv')

#### Green Taxis ####

nyc_green <- fread('./East Coast Datathon Materials/nyc_green_taxi.csv')

nyc_green[,dropoff_datetime:=NULL]
nyc_green[,pickup_datetime:=mdy_hms(pickup_datetime)]

nyc_green <- nyc_green[year(pickup_datetime)==2017]

nyc_green <- nyc_green[wday(pickup_datetime)<=6 & wday(pickup_datetime)>=2 & 
                         ((hour(pickup_datetime)>=6 & hour(pickup_datetime) <=10) | (hour(pickup_datetime)>=15 & hour(pickup_datetime) <=19))]

nyc_green[,pickup_longitude:=NULL]
nyc_green[,pickup_latitude:=NULL]
nyc_green[,dropoff_longitude:=NULL]
nyc_green[,dropoff_latitude:=NULL]

nyc_green[is.na(dropoff_location_id)]

nyc_green <- merge(nyc_green, tlc_zones[,.(location_id,nta_code)], by.x = 'pickup_location_id', by.y = 'location_id', all.x = T, all.y=F)
colnames(nyc_green)[8] <- 'pickup_nta'
nyc_green <- merge(nyc_green, tlc_zones[,.(location_id,nta_code)], by.x = 'dropoff_location_id', by.y = 'location_id', all.x = T, all.y=F)
colnames(nyc_green)[9] <- 'dropoff_nta'

# Creating output
geo_green <- nyc_green[,.(green_num_rides=.N
                           ,green_med_pass=median(passenger_count,na.rm=T)
                           ,green_med_dist=median(trip_distance,na.rm=T)
                           ,green_avg_cost=mean(total_amount,na.rm=T)
                           ,green_med_cost=median(total_amount,na.rm=T))
                        ,by=pickup_nta]

fwrite(geo_green, 'green_geo_data.csv')
