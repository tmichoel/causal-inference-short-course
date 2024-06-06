using DrWatson
@quickactivate "causal-inference-short-course"

using DataFrames
using Arrow
using CSV
using Gadfly
using Compose
using BioFindr
using Printf

# Load data
dt = DataFrame(Arrow.Table(datadir("processed","findr-data-geuvadis", "dt.arrow")));
dgt = DataFrame(Arrow.Table(datadir("processed","findr-data-geuvadis", "dgt.arrow")))
dpt = DataFrame(SNP_ID = names(dgt), GENE_ID=names(dt)[1:ncol(dgt)]);

# Load the list of TFs, downloaded from https://humantfs.ccbr.utoronto.ca/allTFs.php")))
tf = DataFrame(CSV.File(datadir("processed","findr-data-geuvadis", "TF_names_v_1.01.txt"), header=false))
rename!(tf, [:"Column1" => :GeneName])

# how many are in dt?
length(intersect(tf.GeneName, names(dt)))

# how many have eqtls?
length(intersect(tf.GeneName, names(dt)[1:ncol(dgt)]))

# print TF names in dt to a file
oname = datadir("processed","findr-data-geuvadis", "TF_names.txt")
open(oname, "w") do io
    for i in intersect(tf.GeneName, names(dt))
        println(io, i)
    end
end

# find TFs with eQTLs
TF_eqtls = intersect(tf.GeneName, names(dt)[1:ncol(dgt)])

# select only the TFs with eQTLs from dpt
dpt_TF = dpt[findall(x -> x in TF_eqtls, dpt.GENE_ID), :]

dP = findr(dt, dgt, dpt_TF; FDR=0.2)

gdf = groupby(dP, :Source);

cdf = sort!(combine(gdf, nrow),:nrow, rev=true)

f = open("gene_sets.gmt", "w+")
for k in eachindex(gdf)
    if nrow(gdf[k]) >= 30 && nrow(gdf[k]) < 1000
        s = @sprintf "%s_targets\tTarget_list\t%s\n" gdf[k].Source[1] join(gdf[k].Target, "\t")
        write(f,s)
    end
end
close(f)