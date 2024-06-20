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
using Distributions
using Graphs

# Load data
dt = DataFrame(Arrow.Table(datadir("processed","findr-data-geuvadis", "dt.arrow")));
dgt = DataFrame(Arrow.Table(datadir("processed","findr-data-geuvadis", "dgt.arrow")))
dpt = DataFrame(SNP_ID = names(dgt), GENE_ID=names(dt)[1:ncol(dgt)]);

dm = DataFrame(Arrow.Table(datadir("processed","findr-data-geuvadis", "dm.arrow")));
dgm = DataFrame(Arrow.Table(datadir("processed","findr-data-geuvadis", "dgm.arrow")));
dpm = DataFrame(SNP_ID = names(dgm), miRNA_ID=names(dm)[1:ncol(dgm)]);

# Load the list of TFs, downloaded from https://humantfs.ccbr.utoronto.ca/allTFs.php")))
TFs = DataFrame(CSV.File(datadir("processed","findr-data-geuvadis", "TF_names_v_1.01.txt"), header=false))
rename!(TFs, :"Column1" => :GENE_ID)

# how many are in dt?
length(intersect(TFs.GeneName, names(dt)))

# how many have eqtls?
length(intersect(TFs.GeneName, names(dt)[1:ncol(dgt)]))




dP_TF_mRNA = findr(dt, dgt, dpt; namesX=TFs.GENE_ID, FDR=0.2)

gdf = groupby(dP_TF_mRNA, :Source);

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

# define "phenotypes" as the first three principal components of the expression data
phenotypes = projection(M)

# make the second phenotype discrete
phenotypes[:,2] = phenotypes[:,2] .> median(phenotypes[:,2])

# store the phenotypes in a dataframe
dph = DataFrame(phenotypes, [:Ph1, :Ph2, :Ph3])

# write the phenotypes to a file
CSV.write(datadir("processed","findr-data-geuvadis", "PC_phenotypes.csv"), dph)

# for each target set, compute the first principal component of the target set and correlate it with the first three principal components of the full matrix
for k in eachindex(gdf)
    if nrow(gdf[k]) >= 10  && nrow(gdf[k]) < 1000
        # get target list
        tgts = gdf[k].Target
        # compute the first principal component of the target set
        Yt_tgt = Yt[:,findall(x -> x in tgts, names(dt))]
        M_tgt = fit(PCA, Yt_tgt; maxoutdim=1)
        # compute the correlations
        cc = cor(projection(M_tgt), phenotypes)
        println(gdf[k].Source[1], "\t", length(tgts), "\t", cc)
    end
end

dP_miRNA_miRNA = findr(dm, dgm, dpm; FDR=0.2)
dP_TF_miRNA = findr(dm, dt, dgt, dpt; namesX=TFs.GENE_ID, FDR=0.2)
dP_miRNA_mRNA = findr(dt, dm, dgm, dpm; FDR=0.2)

# merge the dP dataframes and revers sort by Probability
dP = sort!(vcat(dP_TF_mRNA, dP_miRNA_miRNA, dP_TF_miRNA, dP_miRNA_mRNA), :Probability, rev=true)

# define regulators as the unique elements of dP.Source
regulators = unique(dP.Source)

# define a new dataframe keeping only rows where Target is in regulators
dP_reg = filter(row -> row.Target in regulators, dP)

# create DAG from dP
G = dagfindr!(dP);
G_reg = dagfindr!(dP_reg);

# filter out rows that are noi inDAG in dP_reg
filter!(row -> row.inDAG_greedy_edges==true, dP_reg)

# write dP and dP_reg to files in csv format
CSV.write(datadir("results","findr-data-geuvadis", "dP.csv"), dP)
CSV.write(datadir("results","findr-data-geuvadis", "dP_reg.csv"), dP_reg)