module CurrentPopulationSurvey

using CSV
using DataFrames
using DataDeps
using Glob
using JuliaDB

export prepdata

project_path(parts...) = normpath(joinpath(@__DIR__, "..", parts...))

# Maps the correct data dictionary to each year's data files
const dictmap = Dict(
    2019 => project_path("data/data_dict201701.csv"),
    2018 => project_path("data/data_dict201701.csv"),
    2017 => project_path("data/data_dict201701.csv"),
    2016 => project_path("data/data_dict201501.csv"),
    2015 => project_path("data/data_dict201501.csv"),
    2014 => project_path("data/data_dict201401.csv"),
    2013 => project_path("data/data_dict201301.csv"),
)

# Get the URLs of the .zip files for a given year
function geturls(year::Int)
    urls = DataFrame(CSV.File(project_path("data/download_links.csv")))
    return urls[urls.year .== year, :url]
end

# Register a data dependency for a given year's CPS data
function registerdep(year::Int)
    try
        isdir(@datadep_str "CPS $year")
        return @info "Unparsed CPS $year data is here: $(@datadep_str "CPS $year")"
    catch e
        register(DataDep(
            "CPS $year",
            "CPS monthly microdata files for $year",
            geturls(year),
            Any,
            post_fetch_method = unpack
        ))
    end
end

# Parse the .dat files for a given year, keeping only the variables specified in vars
function createdf(year::Int, vars::Vector{String})
    df = DataFrame()
    varlist = filter(row ->
        in(row[:varname],
        lowercase.(vars)),
        DataFrame(CSV.File(dictmap[year]))
    )
    for varname in varlist.varname
        df[!, Symbol(uppercase(varname))] = Int[]
    end
    files = collect(glob("*", @datadep_str "CPS $year"))
    numfiles = length(files)
    i = 1
    @info "Processing $numfiles files..."
    for file in files
        open(file) do f
            for line in eachline(f)
                push!(df,
                    [parse(Int, line[row.start:row.end]) for row in eachrow(varlist)]
                )
            end
        end
        @info "Processed file $i of $numfiles"
        i += 1
    end
    return df
end

# Parse the .dat files for a given year, keeping all variables in the file
function createdf(year::Int)
    df = DataFrame()
    varlist = DataFrame(CSV.File(dictmap[year]))
    for varname in varlist.varname
        df[!, Symbol(uppercase(varname))] = Int[]
    end
    files = collect(glob("*", @datadep_str "CPS $year"))
    numfiles = length(files)
    i = 1
    @info "Processing $numfiles files..."
    for file in files
        open(file) do f
            for line in eachline(f)
                push!(df,
                    [parse(Int, line[row.start:row.end]) for row in eachrow(varlist)]
                )
            end
        end
        @info "Processed file $i of $numfiles"
        i += 1
    end
    return df
end

"""
    prepdata(year::Int, vars::Vector{String}; indexedtable::Bool=false, dir::String=pwd())

Download/parse CPS microdata files for a given year retaining only the variables specified.
There are hundreds of variables so specifying only those that you need will significantly increase
efficiency when working with the data.

# Arguments
- `year::Int`: the year for which you want to obtain CPS data. CPS data files are monthly
so each year consists of 12 files.
- `vars::Vector{String}`: a vector specifying the variables in the microdata files that you
would like to keep.
- `indexedtable::Bool=false`: specify whether or not you would like to save the parsed data
as an `IndexedTable`. This allows you to parse the data just once and then save it to disk for
ongoing use. If false, will return a `DataFrame`.
- `dir::String=pwd()`: specify an *absolute* directory path to where you would like to store
the `IndexedTable`. The file name will be generated automatically so you should not include
it in the path.

# Examples

If you just want to return a DataFrame:

```
df19 = prepdata(2019, ["HRINTSTA", "PWORWGT"])
```

If you want to write the parsed data to an `IndexedTable`:
```
prepdata(2019, ["HRINTSTA", "PWORWGT"]; indexedtable=true, dir="C:/Users/user/Julia/cps-test/data")
```
"""
function prepdata(year::Int, vars::Vector{String}; indexedtable::Bool = false, dir::String = pwd())
    registerdep(year)
    df = createdf(year, vars)
    return indexedtable ? savetable(df, year, dir) : df
end

"""
    prepdata(year::Int; indexedtable::Bool=false, dir::String=pwd())

Download/parse CPS microdata files for a given year and retain *all* variables.

# Arguments
- `year::Int`: the year for which you want to obtain CPS data. CPS data files are monthly
so each year consists of 12 files.
- `indexedtable::Bool=false`: specify whether or not you would like to save the parsed data
as an `IndexedTable`. This allows you to parse the data just once and then save it to disk for
ongoing use. If false, will return a `DataFrame`.
- `dir::String=pwd()`: specify an *absolute* directory path to where you would like to store
the `IndexedTable`. The file name will be generated automatically so you should not include
it in the path.

# Examples

If you just want to return a DataFrame:

```
df19 = prepdata(2019)
```

If you want to write the parsed data to an `IndexedTable`:
```
prepdata(2019; indexedtable=true, dir="C:/Users/user/Julia/cps-test/data")
```
"""
function prepdata(year::Int; indexedtable::Bool = false, dir::String = pwd())
    registerdep(year)
    df = createdf(year)
    return indexedtable ? savetable(df, year, dir) : df
end

function savetable(df::DataFrame, year::Int, dir::String = pwd())
    @info "Writing IndexedTable..."
    if isfile(joinpath(dir, "CPS $year"))
        return @info "CPS $year IndexedTable lives here: $(joinpath(dir, "CPS $year"))"
    else
        tbl = table(df)
        if isdir(dir)
            save(tbl, joinpath(dir, "CPS $year"))
        else
            mkpath(dir)
            save(tbl, joinpath(dir, "CPS $year"))
        end
        @info "Saved CPS $year IndexedTable to $dir/CPS $year"
    end
end

end
