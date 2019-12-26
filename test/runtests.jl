using CurrentPopulationSurvey
using DataDeps
using DataFrames
using Test

@testset "CurrentPopulationSurvey.jl" begin
    @testset "method 1, indexedtable=false" begin
        df = prepdata(2019, ["HRINTSTA"])
        @test isdir(@datadep_str "CPS 2019")
        @test typeof(df) == DataFrames.DataFrame
        @test in(:HRINTSTA, names(df))
    end

    @testset "method 2, indexedtable=false" begin
        df_all = prepdata(2019)
        @test in(:HRHHID, names(df_all))
    end

    @testset "method 1, indexedtable=true" begin
        prepdata(2019, ["HRINTSTA"], indexedtable=true, dir=joinpath(pwd(), "test", "data"))
        @test isfile(joinpath(pwd(), "test", "data", "CPS 2019"))
    end
end
