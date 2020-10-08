module CurrentPopulationSurvey

using DataDeps
using DelimitedFiles
using Tables

export cpsdata

project_path(parts...) = normpath(joinpath(@__DIR__, "..", parts...))

# Register a data dependency for a given year/month
function registerdep(year::Int, month::Int, lookup::AbstractArray)
    try
        isdir(@datadep_str "CPS $year$month")
        return @info "Unparsed CPS $year$month data is here: $(@datadep_str "CPS $year$month")"
    catch e
        register(DataDep(
            "CPS $year$month",
            "CPS monthly microdata for $year$month",
            lookup[(lookup[:,1] .== year) .& (lookup[:,2] .== month), 3][1], # Get the URL of the .zip files for a given year/month
            Any,
            post_fetch_method = unpack
        ))
    end
end

# Parse the .dat files for a given year/month, optionally keeping only the variables specified in vars
function createtable(year::Int, month::Int, vars::Vector{String}, lookup::AbstractArray)
    dictnum = lookup[(lookup[:,1] .== year) .& (lookup[:,2] .== month), 4][1] # Get the dict no. for a given year/month
    dict = readdlm("data/data_dict$dictnum.csv", ',', skipstart=1) 
    varlist = dict[findall(in(lowercase.(vars)), dict[:, 1]), :]
    tbl = AbstractArray{Int}[]
    path = @datadep_str "CPS $year$month"
    file = readdir(path, join=true)[1]
    open(file) do f
        for line in eachline(f)
            push!(tbl,
                [parse(Int, line[row[2]:row[3]]) for row in eachrow(varlist)]
            )
        end
    end
    return Tables.table(permutedims(reshape(hcat(tbl...), (length(tbl[1]), length(tbl)))), header=Symbol.(vars))
end

function createtable(year::Int, month::Int, data::AbstractArray)
    dictnum = data[(data[:,1] .== year) .& (data[:,2] .== month), 4][1] # Get the dict no. for a given year/month
    dict = readdlm("data/data_dict$dictnum.csv", ',', skipstart=1) 
    tbl = AbstractArray{Int}[]
    path = @datadep_str "CPS $year$month"
    file = readdir(path, join=true)[1]
    open(file) do f
        for line in eachline(f)
            push!(tbl,
                [parse(Int, line[row[2]:row[3]]) for row in eachrow(dict)]
            )
        end
    end
    return Tables.table(permutedims(reshape(hcat(tbl...), (length(tbl[1]), length(tbl)))), header=Symbol.(vars))
end

"""
    cpsdata(year::Int, month::Int[, vars::Vector{String}])

Download/parse CPS microdata files for a given year & month, optionally retaining only the variables specified.
There are hundreds of variables so specifying only those that you need will significantly increase
efficiency when working with the data. Returns a table which can be easily converted into any data type
supported by the Tables.jl interface.

# Arguments
- `year::Int`: the year for which you want to obtain CPS data.
- `year::Int`: the month for which you want to obtain CPS data.
- `vars::Vector{String}`: an optional argument specifying the variables in the microdata file that you
would like to keep.

# Examples

```
data1901 = cpsdata(2019, 1, ["HRINTSTA", "PWORWGT"])
```

If you want to work with the data as a DataFrame:

```
using DataFrames

data1901 = DataFrame(cpsdata(2019, 1, ["HRINTSTA", "PWORWGT"]))
```
"""
function cpsdata(year::Int, month::Int, vars::Vector{String})
    lookup = readdlm("data/links_dicts.csv", ',', skipstart=1)
    registerdep(year, month, lookup)
    return createtable(year, month, vars, lookup)
end

function cpsdata(year::Int, month::Int)
    lookup = readdlm("data/links_dicts.csv", ',', skipstart=1)
    registerdep(year, month, lookup)
    return createtable(year, month, lookup)
end

end