using DrWatson
@quickactivate "causal-inference-short-course"

using DataFrames
using Arrow
using CSV

# read cusanovich-pgen-2014 csv data
df = DataFrame(CSV.File(datadir("raw","cusanovich-pgen-2014", "TableS3.txt")))

# read the findr output dP from the results folder
dP = DataFrame(CSV.File(datadir("results","findr-data-geuvadis", "dP.csv")))

# get the list of TFs
TFs = unique(dP.Source)

# split names(df) at the first underscore
TF_validated = [split(x, "_")[1] for x in names(df)]

# find the locations of the intersection of the TFs and TF validated in the validated TFs
intersect(TFs, TF_validated)

# find the locations of the intersection of the TFs and TF validated in the validated TFs
idx = findall(x -> x in TFs, TF_validated)
names(df)[idx]