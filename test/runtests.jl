using CurrentPopulationSurvey
using DataDeps
using Tables
using Test

@testset "CurrentPopulationSurvey.jl" begin
    tbl = cpsdata(2019, 1, ["HRINTSTA"])
    @test isdir(@datadep_str "CPS 20191")
    @test Tables.istable(tbl) == true
    @test in(:HRINTSTA, getfield(tbl, :names))
    tbl_all = cpsdata(2019,1)
    @test in(:pworwgt, getfield(tbl_all, :names))
end
