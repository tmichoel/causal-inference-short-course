using DrWatson
@quickactivate "causal-inference-short-course"

using DataFrames
using Arrow
using CSV
using Gadfly
using Compose
using BioFindr
using Printf
using Statistics
using MultivariateStats

# Load data
dt = DataFrame(Arrow.Table(datadir("processed","findr-data-geuvadis", "dt.arrow")));
dgt = DataFrame(Arrow.Table(datadir("processed","findr-data-geuvadis", "dgt.arrow")))
dpt = DataFrame(SNP_ID = names(dgt), GENE_ID=names(dt)[1:ncol(dgt)]);

# Load the list of TFs, downloaded from https://humantfs.ccbr.utoronto.ca/allTFs.php")))
TFs = DataFrame(CSV.File(datadir("processed","findr-data-geuvadis", "TF_names_v_1.01.txt"), header=false))
rename!(TFs, [:"Column1" => :GeneName])

# how many are in dt?
length(intersect(TFs.GeneName, names(dt)))

# how many have eqtls?
length(intersect(TFs.GeneName, names(dt)[1:ncol(dgt)]))

# print TF names in dt to a file
oname = datadir("processed","findr-data-geuvadis", "TF_names.txt")
open(oname, "w") do io
    for i in intersect(TFs.GeneName, names(dt))
        println(io, i)
    end
end

# find TFs with eQTLs
TF_eqtls = intersect(TFs.GeneName, names(dt)[1:ncol(dgt)])

# select only the TFs with eQTLs from dpt
dpt_TF = dpt[findall(x -> x in TF_eqtls, dpt.GENE_ID), :]

dP = findr(dt, dgt, dpt_TF; FDR=0.2)

gdf = groupby(dP, :Source);

cdf = unstack(sort!(combine(gdf, nrow),:nrow, rev=true), :Source, :nrow)

fup = open("gene_sets_up.gmt", "w+")
fdown = open("gene_sets_down.gmt", "w+")
for k in eachindex(gdf)
    if nrow(gdf[k]) >= 30 && nrow(gdf[k]) < 1000
        # get target list
        tgts = gdf[k].Target
        # compute correlation between TF and targets
        cc = [cor(dt[:,gdf[k].Source[1]], dt[:,x]) for x in findall(x -> x in tgts, names(dt))]
        # print the targets with positive correlation to the up file
        sup = @sprintf "%s_targets_up\tTarget_list\t%s\n" gdf[k].Source[1] join(tgts[cc.>=0], "\t")
        write(fup,sup)
        # print the targets with negative correlation to the down file
        sdown = @sprintf "%s_targets_down\tTarget_list\t%s\n" gdf[k].Source[1] join(tgts[cc.<0], "\t")
        write(fdown,sdown)
    end
end
close(fup)
close(fdown)

# compute supernormalize data
Yt = BioFindr.supernormalize(dt)

# compute the first three principal components of the expression data Yt
M = fit(PCA, Yt; maxoutdim=3)

# for each target set, compute the first principal component of the target set and correlate it with the first three principal components of the full matrix
for k in eachindex(gdf)
    if nrow(gdf[k]) >= 10  && nrow(gdf[k]) < 1000
        # get target list
        tgts = gdf[k].Target
        # compute the first principal component of the target set
        Yt_tgt = Yt[:,findall(x -> x in tgts, names(dt))]
        M_tgt = fit(PCA, Yt_tgt; maxoutdim=1)
        # compute the correlations
        cc = cor(projection(M_tgt), projection( M))
        println(gdf[k].Source[1], "\t", length(tgts), "\t", cc)
    end
end