############################## Change Analysis Regression #################### 
##
## Using functions to generate environmental change variables for cities.
## DATE CREATED: 05/16/2019
## DATE MODIFIED: 07/15/2019
## AUTHORS: Benoit Parmentier
## Version: 2
## PROJECT: Belspo
## ISSUE: 
## TO DO:
##
## COMMIT: testing
##

###Loading R library and packages                                                      
#library(gstat) #spatial interpolation and kriging methods
library(sp) # spatial/geographic objects and functions
library(rgdal) #GDAL/OGR binding for R with functionalities
library(spdep) #spatial analyses operations, functions etc.
library(gtools) # contains mixsort and other useful functions
library(maptools) # tools to manipulate spatial data
library(parallel) # parallel computation, part of base package no
library(rasterVis) # raster visualization operations
library(raster) # raster functionalities
library(forecast) #ARIMA forecasting
library(xts) #extension for time series object and analyses
library(zoo) # time series object and analysis
library(lubridate) # dates functionality
library(colorRamps) #contains matlab.like color palette
library(rgeos) #contains topological operations
library(sphet) #contains spreg, spatial regression modeling
library(BMS) #contains hex2bin and bin2hex, Bayesian methods
library(bitops) # function for bitwise operations
library(foreign) # import datasets from SAS, spss, stata and other sources
library(gdata) #read xls, dbf etc., not recently updated but useful
library(classInt) #methods to generate class limits
library(plyr) #data wrangling: various operations for splitting, combining data
library(readxl) #functionalities to read in excel type data
library(sf) # spatial ojbects simple feature model implementation OGC
#library(gstat)
#library(spacetime)

###### Functions used in this script and sourced from other files

create_dir_fun <- function(outDir,out_suffix=NULL){
  #if out_suffix is not null then append out_suffix string
  if(!is.null(out_suffix)){
    out_name <- paste("output_",out_suffix,sep="")
    outDir <- file.path(outDir,out_name)
  }
  #create if does not exists
  if(!file.exists(outDir)){
    dir.create(outDir)
  }
  return(outDir)
}

#Benoit setup
script_path <- "/media/dan/Data/trend_and_harmonic_regression/scripts"

harmonic_regression_functions <- "harmonic_regression_functions_06042019.R"
trend_methods_time_series_functions <- "trend_methods_time_series_functions_06102019.R"
source(file.path(script_path,harmonic_regression_functions))
source(file.path(script_path,trend_methods_time_series_functions))

############################################################################
#####  Parameters and argument set up ###########

#ARGS 1
in_dir <- "/media/dan/Data/trend_and_harmonic_regression/data"
#data in:/media/dan/processed/MOD13A1/latlong
#ARGS 2
out_dir <- "/media/dan/Data/trend_and_harmonic_regression/outputs"
#ARGS 3
infile_name_raster <- "Ouagadougou_MOD13A1_006_NDVI_2001_2016.tif"

#ARGS 4
#start_date <- "2004-01-01"
start_date <- "2012-11-01"  #new data starts in November 2012
#ARGS 5
end_date <- NULL
#ARGS 6
create_out_dir_param=TRUE #create a new ouput dir if TRUE
#ARGS 7
out_suffix <-"Ouagadougou_MOD13A1_006_NDVI" #output suffix for the files and ouptut folder #param 12
#ARGS 8
num_cores <- 3 # number of cores
#ARGS 9
file_format <- ".tif"
#ARGS 10
#range_window <- c("2012-01-01","2017-01-01")
#ARGS 11
out_prefix <- NULL

################# START SCRIPT ###############################

######### PART 0: Set up the output dir ################

options(scipen=999)

if(is.null(out_dir)){
  out_dir <- in_dir #output will be created in the input dir
  
}
#out_dir <- in_dir #output will be created in the input dir

out_suffix_s <- out_suffix #xcan modify name of output suffix
if(create_out_dir_param==TRUE){
  out_dir <- create_dir_fun(out_dir,out_suffix)
  setwd(out_dir)
}else{
  setwd(out_dir) #use previoulsy defined directory
}

#######################################
### PART I READ AND PREPARE DATA #######
  #set up the working directory
#Create output directory
  
infile_name_raster <- file.path(in_dir,infile_name_raster)
#
#data_df <- read.table(infile_name,header=T,sep=",",stringsAsFactors = F)
r <- brick(infile_name_raster)
names(r)
#if not true, we have missing layers, this should be spotted using the time series names(dates)/
#Date should be added as descriptions in the tif!!
nlayers(r)==16*23

plot(r,y=1)
NAvalue(r)
plot(r,y=14,colNA="black")

if(is.null(out_prefix)){
  out_prefix <- basename(sub(file_format,"",infile_name_raster))
}

############################
#### PART II: Generate amplitudes and phases by year and overall

#####################
#### Generate Amplitude 0 (annual mean in this context)

harmonic_val <- NULL
var_name <- "A0" #mean value from Harmonic Fourier
#raster_name <- NULL
raster_name <- paste0(out_prefix,"_amplitude_year",file_format)
file_format <- file_format
multiband <- FALSE
window_val <- 23


#test <- harmonic_reg_raster(y,var_name,
#                            n=window_val,
#                            harmonic_val=NULL)

#debug(calcHarmonicRaster)

list_r_amplitude <- calcHarmonicRaster(r,
                                         harmonic_val=harmonic_val,
                                         var_name=var_name,
                                         window_val=window_val,
                                         file_format=file_format,
                                         multiband=multiband,
                                         num_cores=num_cores,
                                         raster_name=raster_name,
                                         out_dir=out_dir)

###################
#### Generate Amplitudes A1 and A2 (seaonality and bi-annual signal)

harmonic_val <- NULL
var_name <- "A"
#raster_name <- NULL
raster_name <- paste0(out_prefix,"_amplitude_year",file_format)
#file_format <- ".tif" #set above
multiband <- FALSE
window_val <- 23

#debug(calcHarmonicRaster)

list_r_amplitude <- calcHarmonicRaster(r,
                   harmonic_val=harmonic_val,
                   var_name=var_name,
                   window_val=window_val,
                   file_format=file_format,
                   multiband=multiband,
                   num_cores=num_cores,
                   raster_name=raster_name,
                   out_dir=out_dir)

####################
#### Generate Phase 1 and phase 2 (seaonality and bi-annual signal)

harmonic_val <- NULL
var_name <- "phase" #wiill be included in name
#raster_name <- NULL
#raster_name <- "Ouagadougou_NDVI_MOD13A1_year.tif"
raster_name <- paste0(out_prefix,"_year",file_format)

file_format <- ".tif"
multiband <- FALSE
window_val <- 23

#debug(calcHarmonicRaster)

list_r_phase <- calcHarmonicRaster(r,
                             harmonic_val=harmonic_val,
                             var_name=var_name,
                             window_val=window_val,
                             file_format=file_format,
                             multiband=multiband,
                             num_cores=num_cores,
                             raster_name=raster_name,
                             out_dir=out_dir)


r_phase <- stack(list_r_phase)
plot(r_phase)
plot(r_phase,y=1)


############################
#### PART III : Generate amplitudes and phases by year and overall

##########################
#### Generate Overall amplitude A1 and A2 (seaonality and bi-annual signal)

list_r_amplitude
harmonic_val <- NULL
var_name <- "A" #will be included in name
raster_name <- paste0(out_prefix,"_amplitude_overall",file_format)

file_format <- ".tif"
multiband <- FALSE
window_val <- NULL #use overall time series

#debug(calcHarmonicRaster)

r_overall_amplitude <- calcHarmonicRaster(r,
                                         harmonic_val=harmonic_val,
                                         var_name=var_name,
                                         window_val=window_val,
                                         file_format=file_format,
                                         multiband=multiband,
                                         num_cores=num_cores,
                                         raster_name=raster_name,
                                         out_dir=out_dir)


######################
#### Generate Overall phase A1 and A2 (seaonality and bi-annual signal)

#end:
harmonic_val <- NULL
var_name <- "phase" #will be included in name
#raster_name <- NULL
#raster_name <- "Ouagadougou_NDVI_MOD13A1_overall_2001_2016.tif"
raster_name <- paste0(out_prefix,"_overall",file_format)

file_format <- ".tif"
multiband <- FALSE
window_val <- NULL #use overall time series

r_overall_phase <- calcHarmonicRaster(r,
                                      harmonic_val=harmonic_val,
                                      var_name=var_name,
                                      window_val=window_val,
                                      file_format=file_format,
                                      multiband=multiband,
                                      num_cores=num_cores,
                                      raster_name=raster_name,
                                      out_dir=out_dir)

############################
#### PART IV: Get overall trend

##############################
###### Now get the trend from stack (OLS and Theil Sen, as well as Kendall)

raster_name <- paste0(out_prefix,"_overall_trends_ts",file_format)
#raster_name <- "Ouagadougou_NDVI_MOD13A1_trend_ts.tif"
file_format <- ".tif"
method <- "theil_sen"
var_name <- "slope"

r_overall_theilsen_NDVI <- calcTrendRaster(r,
                method=method,
                var_name=var_name,
                file_format=file_format,
                multiband=F,
                num_cores=1,
                raster_name=raster_name,
                out_dir=out_dir)
#50 warnings.

raster_name <- paste0(out_prefix,"_overall_trends_ols",file_format)
#raster_name <- "Ouagadougou_NDVI_MOD13A1_trend_ols.tif"
file_format <- ".tif"
method <- "ols"
var_name <- "slope"

r_overall_ols_NDVI <- calcTrendRaster(r,
                                      method=method,
                                      var_name=var_name,
                                      file_format=file_format,
                                      multiband=F,
                                      num_cores=1,
                                      raster_name=raster_name,
                                      out_dir=out_dir)


################### PART V: Generate trend from phase and amplitude parameters
### Now trend by STA parameters:

#lf_amp0_wt <- mixedsort(list.files(pattern="Ouagadougou_NDVI_MOD13A1_amplitude_year_.*.A0_1.*.tif"))
#lf_amp0_wt2 <- mixedsort(list.files(pattern="Ouagadougou_NDVI_MOD13A1_amplitude_year_.*.A0_2.*.tif"))
#rr2 <- stack(lf_amp0_wt2)
#rr1 <- stack(lf_amp0_wt)
lf_amp0_w <- mixedsort(list.files(pattern=paste0(out_prefix,"_amplitude_year_.*.A0_1.*.tif")))
lf_amp1_w <- mixedsort(list.files(pattern=paste0(out_prefix,"_amplitude_year_.*._A_1.tif")))
lf_amp2_w <- mixedsort(list.files(pattern=paste0(out_prefix,"_amplitude_year_.*._A_2.tif")))
lf_phase1_w <- mixedsort(list.files(pattern=paste0(out_prefix,".*._phase_1.tif")))
lf_phase2_w <- mixedsort(list.files(pattern=paste0(out_prefix,".*._phase_2.tif")))

list_params <- list(lf_amp0_w,lf_amp1_w,lf_amp2_w,lf_phase1_w,lf_phase2_w)
names(list_params) <- c("A0","A1","A2","phase1","phase2")

no_param <- length(list_params)

for(i in 1:no_param){
  
  param_name <- names(list_params[i])

  raster_name <- paste0(out_prefix,"_trend_ts_",param_name,file_format)
  file_format <- ".tif"
  method <- "theil_sen"
  var_name <- "slope"
  
  #undebug(calcTrendRaster)
  r <- stack(list_params[[i]])
  

  r__theilsen_NDVI <- calcTrendRaster(r,
                                             method=method,
                                             var_name=var_name,
                                             file_format=file_format,
                                             multiband=F,
                                             num_cores=1,
                                             raster_name=raster_name,
                                             out_dir=out_dir)
  
  r_ts <- raster(r__theilsen_NDVI)
  plot(r_ts,zlim=c(-0.1,0.1))
  
  raster_name <- paste0(out_prefix,"_trend_ols_",param_name,file_format)
  
  file_format <- ".tif"
  method <- "ols"
  var_name <- "slope"
  
  r_overall_ols_NDVI <- calcTrendRaster(r,
                                        method=method,
                                        var_name=var_name,
                                        file_format=file_format,
                                        multiband=F,
                                        num_cores=1,
                                        raster_name=raster_name,
                                        out_dir=out_dir)
  
}
  

################################### End of script #######################################

    