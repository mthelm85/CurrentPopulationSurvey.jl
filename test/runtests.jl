using CurrentPopulationSurvey
using DataDeps
using DataFrames
using Test

@testset "CurrentPopulationSurvey.jl" begin
    df = prepdata(2019, ["HRINTSTA"])
    @test isdir(@datadep_str "CPS 2019")
    @test typeof(df) == DataFrames.DataFrame
    @test in(:hrintsta, names(df))

    prepdata(2019, ["HRINTSTA"], indexedtable=true, dir="/home/travis/build/mthelm85/CurrentPopulationSurvey.jl/test/data")
    @test isfile("/home/travis/build/mthelm85/CurrentPopulationSurvey.jl/test/data/CPS 2019")
end

rm("test/data/", recursive=true)
