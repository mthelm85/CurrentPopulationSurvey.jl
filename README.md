# CurrentPopulationSurvey

[![Build Status](https://travis-ci.com/mthelm85/CurrentPopulationSurvey.jl.svg?branch=master)](https://travis-ci.com/mthelm85/CurrentPopulationSurvey.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/mthelm85/CurrentPopulationSurvey.jl?svg=true)](https://ci.appveyor.com/project/mthelm85/CurrentPopulationSurvey-jl)
[![Codecov](https://codecov.io/gh/mthelm85/CurrentPopulationSurvey.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/mthelm85/CurrentPopulationSurvey.jl)

# About

CurrentPopulationSurvey.jl allows users to easily download & parse U.S. Census Bureau CPS microdata files for the 2007 - present time period (earlier years are coming in future releases).

# Resources

- About the CPS: https://www.census.gov/programs-surveys/cps/about.html
- Files and data dictionaries: https://www.census.gov/data/datasets/time-series/demo/cps/cps-basic.html

# Recommendations

I recommend that you familiarize yourself with the variables in the data dictionaries before calling ```cpsdata``` so that you can decide on a subset of the total available variables for parsing. One year's worth of data is roughly 5GB - 7GB so narrowing this down (by selecting only the variables that you need) will improve efficiency when working with the data.

This package supports the Tables.jl interface so you can easily convert to a tabular structure of your preference (e.g. `DataFrame`). If you are going to be working with many years of data, I recommend that you make use of [JuliaDB](https://juliadb.org/) and save the data as an ```IndexedTable``` if you intend to use it on an ongoing basis. The reason for this is that I find it's fast and also because JuliaDB makes it very easy to work with data that is too large to fit into memory.

# Useage

This package exports a single function ```cpsdata```:

```julia
cpsdata(year::Int, month::Int[, vars::Vector{String}])
```

Download/parse CPS microdata files for a given year & month, optionally retaining only the variables specified.
There are hundreds of variables so specifying only those that you need will significantly increase
efficiency when working with the data.

### Arguments
- `year::Int`: the year for which you want to obtain CPS data.
- `month::Int`: the month for which you want to obtain CPS data.
- `vars::Vector{String}`: an optional argument specifying the variables in the microdata file that you
would like to keep.

### Examples

```julia
data1901 = cpsdata(2019, 1, ["HRINTSTA", "PWORWGT"])
```

If you want to work with the data as a DataFrame:

```julia
using DataFrames

data1901 = DataFrame(cpsdata(2019, 1, ["HRINTSTA", "PWORWGT"]))
```