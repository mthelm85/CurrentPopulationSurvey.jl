using CurrentPopulationSurvey
using DataDeps
using DataFrames
using Test

df = prepdata(2019, ["HRINTSTA"])
tbl = prepdata(2019, ["HRINTSTA"], indexedtable=true, dir=joinpath(pwd(), "test", "data"))

@testset "CurrentPopulationSurvey.jl" begin
    @test isdir(@datadep_str "CPS 2019")
    @test typeof(df) == DataFrames.DataFrame
    @test in(:hrintsta, names(df))
    @test isfile(joinpath(pwd(), "test", "data", "CPS 2019"))
end

# df = Nothing
# tbl = Nothing
# rm(joinpath(pwd(), "test", "data"), recursive=true)
# rm(eval(@datadep_str "CPS 2019"), recursive=true)
