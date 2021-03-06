######################################################################
# Change dectection for BGB, using Sentinel-2 data from 2015, 2016 and 2017.
#
# (C) Dominique Weber, HAFL, BFH
######################################################################


# source custom function to build geotiff subsets
source("change_detection/change_detection_bitemporal.R")

# ouput directory for results (PDFs, spatial data)
out1 = "//mnt/cephfs/data/HAFL/WWI-Sentinel-2/Data/BGB_Change/2015_2016/"
out2 = "//mnt/cephfs/data/HAFL/WWI-Sentinel-2/Data/BGB_Change/2016_2017/"
out3 = "//mnt/cephfs/data/HAFL/WWI-Sentinel-2/Data/BGB_Change/2017_2018/"

# Sentinel-2 images
s2_2015 = "//mnt/cephfs/data/HAFL/WWI-Sentinel-2/Data/Sentinel-2/BGB/2015/S2A_OPER_MTD_SAFL1C_PDMC_20160408T105241_R108_V20150829T103705_20150829T103705.tif" # 29.08.2015
s2_2016 = "//mnt/cephfs/data/HAFL/WWI-Sentinel-2/Data/Sentinel-2/BGB/2016/S2A_OPER_MTD_SAFL1C_PDMC_20160824T215652_R108_V20160823T103022_20160823T103332.tif" # 23.08.2016
s2_2017 = "//mnt/cephfs/data/BFH/Geodata/World/Sentinel-2/S2MSI1C/GeoTIFF/T32TLT/2017/S2A_MSIL1C_20170719T103021_N0205_R108_T32TLT_20170719T103023.tif" # taking July image because no cloud-free August image 
s2_2018 = "//mnt/cephfs/data/BFH/Geodata/World/Sentinel-2/S2MSI1C/GeoTIFF/T32TLT/2018/S2A_MSIL1C_20180525T103021_N0206_R108_T32TLT_20180525T124252.tif"

# BGB forest mask
sp_mask = "//mnt/cephfs/data/HAFL/WWI-Sentinel-2/Data/BGB_Change/fbb_aoi_and_wiliwald.shp"

# Run change detection
change1 = change_detection_bitemporal(s2_2015, s2_2016, "NBR", sp_mask, 0.1, out1, c("2015", "2016"))
change2 = change_detection_bitemporal(s2_2016, s2_2017, "NBR", sp_mask, 0.1, out2, c("2016", "2017"))
change3 = change_detection_bitemporal(s2_2017, s2_2018, "NBR", sp_mask, 0.1, out3, c("2017", "2018"))

# multi-year shapefile
change1$year = rep(2016, nrow(change1@data))
change2$year = rep(2017, nrow(change2@data))
change3$year = rep(2018, nrow(change3@data))
changed_areas <- rbind(change1, change2, change3)

# positive change is assumed to be negative change in 2015 -> very simple approach
changed_areas$year[(changed_areas$year == 2016 & changed_areas$change == "positive")] = 2015

# remove positive change between 2016 and 2017, and between 2017 and 2018
changed_areas = changed_areas[!(changed_areas$year == 2017 & changed_areas$change == "positive"),]
changed_areas = changed_areas[!(changed_areas$year == 2018 & changed_areas$change == "positive"),]

# as factor
changed_areas$year = as.factor(changed_areas$year)

# plot
plotRGB(stack(s2_2015)[[4:2]], stretch="lin", ext=extent(readOGR(sp_mask)), axes=T, main="Veränderung 2015, 2016, 2017, 2018")
plot(changed_areas, col=c("yellow", "orange", "red", "black")[as.numeric(changed_areas$year)], border=NA, add=T)
legend("right", legend=c("2015", "2016", "2017", "2018"), col=c("yellow", "orange", "red", "black"), lwd=2.5, cex=0.7)

# Add VHM mean
vhm_raster =raster("//mnt/cephfs/data/HAFL/WWI-Sentinel-2/Data/BGB_Change/VHM_2m_max_wgs84.tif")
beginCluster()
vhm_mean = extract(vhm_raster, changed_areas, mean, na.rm=T)
endCluster()
changed_areas$VH_mean = as.numeric(vhm_mean)

# write shapefile
writeOGR(changed_areas, "//mnt/cephfs/data/HAFL/WWI-Sentinel-2/Data/BGB_Change/", "change_all",driver="ESRI Shapefile")
writeOGR(changed_areas[changed_areas$year=="2015",], "//mnt/cephfs/data/HAFL/WWI-Sentinel-2/Data/BGB_Change/", "change_2015",driver="ESRI Shapefile")
writeOGR(changed_areas[changed_areas$year=="2016",], "//mnt/cephfs/data/HAFL/WWI-Sentinel-2/Data/BGB_Change/", "change_2016",driver="ESRI Shapefile")
writeOGR(changed_areas[changed_areas$year=="2017",], "//mnt/cephfs/data/HAFL/WWI-Sentinel-2/Data/BGB_Change/", "change_2017",driver="ESRI Shapefile")
writeOGR(changed_areas[changed_areas$year=="2018",], "//mnt/cephfs/data/HAFL/WWI-Sentinel-2/Data/BGB_Change/", "change_2018",driver="ESRI Shapefile")

