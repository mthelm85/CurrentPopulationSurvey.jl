# CurrentPopulationSurvey

[![Build Status](https://travis-ci.com/mthelm85/CurrentPopulationSurvey.jl.svg?branch=master)](https://travis-ci.com/mthelm85/CurrentPopulationSurvey.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/mthelm85/CurrentPopulationSurvey.jl?svg=true)](https://ci.appveyor.com/project/mthelm85/CurrentPopulationSurvey-jl)
[![Codecov](https://codecov.io/gh/mthelm85/CurrentPopulationSurvey.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/mthelm85/CurrentPopulationSurvey.jl)

# About

CurrentPopulationSurvey.jl allows users to easily download & parse U.S. Census Bureau CPS microdata files for the 2013 - present time period (earlier years are coming in future releases).

# Resources

- About the CPS: https://www.census.gov/programs-surveys/cps/about.html
- Files and data dictionaries: https://thedataweb.rm.census.gov/ftp/cps_ftp.html

# Recommendations

For the 2013 - present time period there are four different data dictionaries. I recommend that you familiarize yourself with the variables in the data dictionaries before calling ```prepdata``` so that you can decide on a subset of the total available variables for parsing. One year's worth of data is roughly 5GB - 7GB so narrowing this down (by selecting only the variables that you need) will improve efficiency when working with the data.

You have the option to parse the data and return a ```DataFrame``` or to save the parsed data as an ```IndexedTable```. I recommend that you save the data as an ```IndexedTable``` if you intend to use it on an ongoing basis. ```IndexedTables``` provide the backend to [JuliaDB](https://juliadb.org/) which is how I prefer to work with this data. I prefer to work with this data with JuliaDB because I find that it's fast and it makes it very easy to work with data that is too large to fit into memory. That being said, an ```IndexedTable``` can be fed directly into the [Queryverse](https://www.queryverse.org/) as well. What's particularly nice about this option is that you can then very easily save the data in a variety of different formats.

# Useage

This package exports a single function ```prepdata``` with two methods:

## Method 1 (with `vars` argument):

    prepdata(year::Int, vars::Vector{String}; indexedtable::Bool=false, dir::String=pwd())

Download/parse CPS microdata files for a given year retaining only the variables specified.
There are hundreds of variables so specifying only those that you need will significantly increase
efficiency when working with the data.

### Arguments
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

### Examples

If you just want to return a DataFrame:

```
df19 = prepdata(2019, ["HRINTSTA", "PWORWGT"])
```

If you want to write the parsed data to an `IndexedTable`:
```
prepdata(2019, ["HRINTSTA", "PWORWGT"]; indexedtable=true, dir="C:/Users/user/Julia/cps-test/data")
```

## Method 2 (without `vars` argument):

    prepdata(year::Int; indexedtable::Bool=false, dir::String=pwd())

Download/parse CPS microdata files for a given year and retain *all* variables.

### Arguments
- `year::Int`: the year for which you want to obtain CPS data. CPS data files are monthly
so each year consists of 12 files.
- `indexedtable::Bool=false`: specify whether or not you would like to save the parsed data
as an `IndexedTable`. This allows you to parse the data just once and then save it to disk for
ongoing use. If false, will return a `DataFrame`.
- `dir::String=pwd()`: specify an *absolute* directory path to where you would like to store
the `IndexedTable`. The file name will be generated automatically so you should not include
it in the path.

### Examples

If you just want to return a DataFrame:

```
df19 = prepdata(2019)
```

If you want to write the parsed data to an `IndexedTable`:
```
prepdata(2019; indexedtable = true, dir = "C:/Users/user/Julia/cps-test/data")
```