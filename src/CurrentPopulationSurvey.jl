module CurrentPopulationSurvey

using CSV
using DataFrames
using DataDeps
using Glob
using JuliaDB

export prepdata

project_path(parts...) = normpath(joinpath(@__DIR__, "..", parts...))

const dictmap = Dict(
    2019 => project_path("data/data_dict201701.csv"),
    2018 => project_path("data/data_dict201701.csv"),
    2017 => project_path("data/data_dict201701.csv"),
    2016 => project_path("data/data_dict201501.csv"),
    2015 => project_path("data/data_dict201501.csv"),
    2014 => project_path("data/data_dict201401.csv"),
    2013 => project_path("data/data_dict201301.csv"),
)

function geturls(year::Int64)
    urls = DataFrame(CSV.File(project_path("data/download_links.csv")))
    return urls[urls.year .== year, :url]
end

function registerdep(year::Int64)
    try
        isdir(@datadep_str "CPS $year")
        return @info "This data lives here: $(@datadep_str "CPS $year")"
    catch e
        register(DataDep(
            "CPS $year",
            "CPS monthly microdata files for $year",
            geturls(year),
            post_fetch_method = unpack
        ))
    end
end

function prepdata(year::Int64, vars::Vector{String}; juliadb::Bool = false, dir::String = pwd())
    registerdep(year)
    df = DataFrame()
    varlist = filter(row ->
        in(uppercase(row[:varname]),
        uppercase.(vars)),
        DataFrame(CSV.File(dictmap[year]))
    )
    for varname in varlist.varname
        df[!, Symbol(varname)] = Int64[]
    end
    files = collect(glob("*", @datadep_str "CPS $year"))
    numfiles = length(files)
    i = 1
    for file in files
        open(file) do f
            for line in eachline(f)
                push!(df,
                    [parse(Int64, line[row.start:row.end]) for row in eachrow(varlist)]
                )
            end
        end
        @info "Processed file $i of $numfiles"
        i += 1
    end
    if !juliadb
        return df
    else
        @info "Writing JuliaDB table..."
        if isfile(joinpath(dir, "CPS $year"))
            return @info "JuliaDB table lives here: $(joinpath(dir, "CPS $year"))"
        else
            tbl = table(df)
            if isdir(dir)
                save(tbl, joinpath(dir, "CPS $year"))
            else
                mkdir(dir)
                save(tbl, joinpath(dir, "CPS $year"))
            end
            @info "Saved JuliaDB table to $dir/CPS $year"
        end
    end
end

end
