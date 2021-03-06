############################################################
# Create BAP composite based on NDVI max summer values
# -> Most vegetated pixel composite -> but has some limitations
# snow and water pixels as well as some other artefacts.  
#
# by Dominique Weber, HAFL, BFH
############################################################
library(raster)
library(rgdal)

start_time <- Sys.time()

source("/home/wbd3/sentinel2-whff/vegetation_indices/calc_vegetation_indices.R")
source("/home/wbd3/sentinel2-whff/composites/calc_pixel_composites.R")

# wd
setwd("//mnt/cephfs/data/HAFL/WWI-Sentinel-2/Data/Surselva_Geb/")

# global params
band_names = c("B01", "B02", "B03", "B04", "B05", "B06", "B07", "B08", "B8A", "B09", "B10","B11", "B12")
dates_filter = c("20170716","20170805","20170815", "20170825", "20170830")
sp = readOGR("Kanton_GR_wgs84.shp")

# 2017 T32TMS
images_path = "//mnt/cephfs/data/BFH/Geodata/World/Sentinel-2/S2MSI1C/GeoTIFF/T32TMS/2017/"
ndvi_max_2017_t32tms = calc_pixel_composites(images_path, band_names, dates_filter, "2017_t32tms", calc_ndvi, max, extent(sp))
writeRaster(ndvi_max_2017_t32tms, "ndvi_max_2017_t32tms.tif")

print(Sys.time() - start_time)

######################################
# calc NDVI max bap composite

# filter .tif files and dates
fileNames = list.files(images_path)
fileNames = fileNames[grep("tif$", fileNames)]
fileNames = fileNames[grepl(paste(dates_filter, collapse="|"), fileNames)]
fileNames = paste(images_path, fileNames, sep="")

# prepare mask and full stack
mask_stk = stack()
full_stk = stack()
pdf("rgb_plots.pdf")
for(i in 1:length(fileNames)){
  # load stack
  stk_tmp = stack(fileNames[i])
  stk_tmp = crop(stk_tmp, extent(sp))
  names(stk_tmp) = band_names
  plotRGB(stk_tmp[[c("B11","B08","B04")]], stretch="lin")
  # calc ndvi
  tmp_ndvi = calc_ndvi(stk_tmp)
  # add mask layer
  mask_stk = addLayer(mask_stk, (tmp_ndvi == ndvi_max_2017_t32tms))
  # add to full stack
  full_stk = addLayer(full_stk, stk_tmp)
}
dev.off()

# mask ndvi max pixels
nLayers = 13
masked_stk = stack()
for(i in 1:nlayers(mask_stk)){
  ind_tmp = seq(to=i*nLayers, length.out=nLayers)
  masked_stk = addLayer(masked_stk, mask(full_stk[[ind_tmp]], mask_stk[[i]], maskvalue=0))
}

# build composite
stk_composite = masked_stk[[1:nLayers]]
names(stk_composite) = band_names
for(i in 1:nlayers(stk_composite)){
  seq_tmp = seq(i, to=nlayers(masked_stk), by=nlayers(stk_composite))
  stk_tmp = masked_stk[[seq_tmp]]
  stk_composite[[i]] = calc(stk_tmp, max)
}

# proper naming
names(stk_composite) = band_names

# plot composite
pdf("composite.pdf")
plotRGB(stk_composite[[c("B04","B03","B02")]], stretch="lin")
plotRGB(stk_composite[[c("B11","B08","B04")]], stretch="lin")
dev.off()

writeRaster(stk_composite, "summer_2017_composite.tif")

print(Sys.time() - start_time)
