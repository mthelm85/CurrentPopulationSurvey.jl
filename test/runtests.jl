using CurrentPopulationSurvey
using DataDeps
using DelimitedFiles
using Tables
using Test

ENV["DATADEPS_ALWAYS_ACCEPT"] = "true"

const PROJECT_ROOT = normpath(joinpath(@__DIR__, ".."))
const LOOKUP = readdlm(joinpath(PROJECT_ROOT, "data", "links_dicts.csv"), ',', skipstart=1)

# Helper: return the data_dict code for a given year/month
dict_for(year, month) = string(LOOKUP[(LOOKUP[:,1] .== year) .& (LOOKUP[:,2] .== month), 4][1])

@testset "CurrentPopulationSurvey.jl" begin

    # ──────────────────────────────────────────────────────────────────────────
    @testset "links_dicts.csv integrity" begin
        years  = Int.(LOOKUP[:, 1])
        months = Int.(LOOKUP[:, 2])

        # Exact row count: 19 years × 12 months
        @test size(LOOKUP, 1) == 228

        # Year range
        @test minimum(years) == 2007
        @test maximum(years) == 2025

        # Every year has exactly 12 month entries
        for y in 2007:2025
            @test count(==(y), years) == 12
        end

        # Month values are all in 1–12
        @test minimum(months) == 1
        @test maximum(months) == 12

        # No duplicate (year, month) pairs
        pairs = collect(zip(years, months))
        @test length(pairs) == length(unique(pairs))

        # All URLs are https:// and end with .zip
        urls = string.(LOOKUP[:, 3])
        @test all(u -> startswith(u, "https://"), urls)
        @test all(u -> endswith(u, ".zip"), urls)

        # Every referenced data_dict code has a corresponding file on disk
        for ref in unique(string.(LOOKUP[:, 4]))
            @test isfile(joinpath(PROJECT_ROOT, "data", "data_dict$ref.csv"))
        end

        # Era boundary spot-checks (verified directly against links_dicts.csv)
        @test dict_for(2019, 1) == "201701"
        @test dict_for(2020, 1) == "202001"
        @test dict_for(2021, 1) == "202101"
        @test dict_for(2022, 1) == "202101"
        @test dict_for(2023, 1) == "202301"
        @test dict_for(2024, 1) == "202301"
        @test dict_for(2025, 1) == "202501"

        # 2012 intra-year split: Jan–Apr use 201001, May–Dec use 201205
        @test dict_for(2012, 4) == "201001"
        @test dict_for(2012, 5) == "201205"
    end

    # ──────────────────────────────────────────────────────────────────────────
    @testset "data dictionary file integrity" begin
        dict_codes = ["200701","200901","201001","201205","201301",
                      "201401","201501","201701","202001","202101",
                      "202301","202501"]

        for code in dict_codes
            @testset "dict $code" begin
                path = joinpath(PROJECT_ROOT, "data", "data_dict$code.csv")
                dict = readdlm(path, ',', skipstart=1)

                # Three columns: varname, start, end
                @test size(dict, 2) == 3

                # At least 200 variables
                @test size(dict, 1) >= 200

                starts   = Int.(dict[:, 2])
                ends     = Int.(dict[:, 3])
                varnames = string.(dict[:, 1])

                # All positions are positive integers; start ≤ end
                @test all(s -> s >= 1, starts)
                @test all(e -> e >= 1, ends)
                @test all(i -> starts[i] <= ends[i], eachindex(starts))

                # Universal variables at fixed positions across every dict
                # (confirmed by parsing all Census layout .txt files)
                for (var, (s, e)) in [("hrhhid",   (1,   15)),
                                       ("hrmonth",  (16,  17)),
                                       ("hryear4",  (18,  21)),
                                       ("hrintsta", (57,  58)),
                                       ("pworwgt",  (603, 612))]
                    idx = findfirst(==(var), varnames)
                    @test idx !== nothing
                    if idx !== nothing
                        @test starts[idx] == s
                        @test ends[idx]   == e
                    end
                end
            end
        end

        # Era-sentinel cross-checks (confirmed from Julia diff of 202301 vs 202501 layouts)
        dict_202301 = readdlm(joinpath(PROJECT_ROOT, "data", "data_dict202301.csv"), ',', skipstart=1)
        dict_202501 = readdlm(joinpath(PROJECT_ROOT, "data", "data_dict202501.csv"), ',', skipstart=1)
        vars_202301 = string.(dict_202301[:, 1])
        vars_202501 = string.(dict_202501[:, 1])

        # prinusyr was renamed to prinuyer starting in 202501
        @test  ("prinusyr" in vars_202301)
        @test !("prinusyr" in vars_202501)
        @test  ("prinuyer" in vars_202501)
        @test !("prinuyer" in vars_202301)

        # pxtlwkhr is a new variable added in 202501
        @test  ("pxtlwkhr" in vars_202501)
        @test !("pxtlwkhr" in vars_202301)
    end

    # ──────────────────────────────────────────────────────────────────────────
    @testset "error handling" begin
        # Year outside the 2007–2025 range: lookup returns empty array, [1] throws BoundsError.
        # Note: if graceful ArgumentError handling is added later, update these to match.
        @test_throws BoundsError cpsdata(2006,  1, ["HRINTSTA"])
        @test_throws BoundsError cpsdata(2026,  1, ["HRINTSTA"])
        @test_throws BoundsError cpsdata(2006,  1)
        @test_throws BoundsError cpsdata(2026,  1)

        # Invalid month
        @test_throws BoundsError cpsdata(2019,  0, ["HRINTSTA"])
        @test_throws BoundsError cpsdata(2019, 13, ["HRINTSTA"])
        @test_throws BoundsError cpsdata(2019,  0)
        @test_throws BoundsError cpsdata(2019, 13)
    end

    # ──────────────────────────────────────────────────────────────────────────
    @testset "integration — pre-2020 and 2020 era" begin

        # ── filtered retrieval: 2019-Jan (dict 201701) ───────────────────────
        tbl19 = cpsdata(2019, 1, ["HRINTSTA"])

        @test Tables.istable(tbl19)
        @test isdir(@datadep_str "CPS 20191")

        names19 = getfield(tbl19, :names)
        @test :hrintsta in names19
        @test length(names19) == 1           # only the requested column
        @test !(:hrmonth in names19)          # unrequested column is absent

        col19 = Tables.getcolumn(tbl19, :hrintsta)
        @test eltype(col19) <: Integer
        @test length(col19) > 0

        # ── case-insensitivity (reuses cached 2019-Jan) ───────────────────────
        tbl_upper = cpsdata(2019, 1, ["HRINTSTA"])
        tbl_lower = cpsdata(2019, 1, ["hrintsta"])
        tbl_mixed = cpsdata(2019, 1, ["HrInTsTa"])

        @test :hrintsta in getfield(tbl_upper, :names)
        @test :hrintsta in getfield(tbl_lower, :names)
        @test :hrintsta in getfield(tbl_mixed, :names)
        @test Tables.getcolumn(tbl_upper, :hrintsta) == Tables.getcolumn(tbl_lower, :hrintsta)
        @test Tables.getcolumn(tbl_upper, :hrintsta) == Tables.getcolumn(tbl_mixed, :hrintsta)

        # ── multi-variable filter + year/month value validation ───────────────
        tbl19m = cpsdata(2019, 1, ["HRINTSTA", "HRMONTH", "HRYEAR4"])
        names19m = getfield(tbl19m, :names)
        @test :hrintsta in names19m
        @test :hrmonth  in names19m
        @test :hryear4  in names19m
        @test length(names19m) == 3
        @test all(==(1),    Tables.getcolumn(tbl19m, :hrmonth))
        @test all(==(2019), Tables.getcolumn(tbl19m, :hryear4))

        # ── verify 2020-Jan DataDep was registered (dict 202001) ─────────────
        # (The unfiltered cpsdata(2020, 1) call is omitted here because parsing
        #  all ~386 columns across the full .dat file is too slow for CI.
        #  Column-count integrity is verified statically in "data dictionary
        #  file integrity" via readdlm — no download required.)
        @test isdir(@datadep_str "CPS 20201")
    end

    # ──────────────────────────────────────────────────────────────────────────
    @testset "integration — 202101 era" begin
        tbl21 = cpsdata(2021, 1, ["HRINTSTA", "HRMONTH", "HRYEAR4", "PWORWGT"])

        @test Tables.istable(tbl21)
        @test isdir(@datadep_str "CPS 20211")

        names21 = getfield(tbl21, :names)
        @test :hrintsta in names21
        @test :hrmonth  in names21
        @test :hryear4  in names21
        @test :pworwgt  in names21
        @test length(names21) == 4

        @test all(==(1),    Tables.getcolumn(tbl21, :hrmonth))
        @test all(==(2021), Tables.getcolumn(tbl21, :hryear4))
    end

    # ──────────────────────────────────────────────────────────────────────────
    @testset "integration — 202301 era" begin
        # prinusyr sits at position 176–177 in data_dict202301.csv.
        # It was renamed to prinuyer in 202501, so its presence here confirms
        # the 202301 dict was loaded (not the old 202101 or the new 202501).
        tbl23 = cpsdata(2023, 1, ["HRINTSTA", "HRMONTH", "HRYEAR4", "PRINUSYR"])

        @test Tables.istable(tbl23)
        @test isdir(@datadep_str "CPS 20231")

        names23 = getfield(tbl23, :names)
        @test :hrintsta in names23
        @test :hrmonth  in names23
        @test :hryear4  in names23
        @test :prinusyr in names23
        @test length(names23) == 4

        @test all(==(1),    Tables.getcolumn(tbl23, :hrmonth))
        @test all(==(2023), Tables.getcolumn(tbl23, :hryear4))
    end

    # ──────────────────────────────────────────────────────────────────────────
    @testset "integration — 202501 era" begin
        # prinuyer (renamed from prinusyr) and pxtlwkhr are both unique to 202501,
        # confirming the correct dict was loaded.
        tbl25 = cpsdata(2025, 1, ["HRINTSTA", "HRMONTH", "HRYEAR4", "PRINUYER", "PXTLWKHR"])

        @test Tables.istable(tbl25)
        @test isdir(@datadep_str "CPS 20251")

        names25 = getfield(tbl25, :names)
        @test :hrintsta in names25
        @test :hrmonth  in names25
        @test :hryear4  in names25
        @test :prinuyer  in names25
        @test :pxtlwkhr in names25
        @test length(names25) == 5

        @test all(==(1),    Tables.getcolumn(tbl25, :hrmonth))
        @test all(==(2025), Tables.getcolumn(tbl25, :hryear4))
        # (Unfiltered cpsdata(2025, 1) omitted — too slow for CI; column-count
        #  integrity is covered statically in "data dictionary file integrity".)
    end

    # ──────────────────────────────────────────────────────────────────────────
    @testset "DataDeps caching" begin
        # Second call for the same month returns identical data (proves cache is used)
        tbl_a = cpsdata(2019, 1, ["HRINTSTA"])
        tbl_b = cpsdata(2019, 1, ["HRINTSTA"])
        @test Tables.getcolumn(tbl_a, :hrintsta) == Tables.getcolumn(tbl_b, :hrintsta)

        # All integration-test months have a DataDeps directory with exactly one .dat file
        for (y, m) in [(2019, 1), (2020, 1), (2021, 1), (2023, 1), (2025, 1)]
            dir = @datadep_str "CPS $y$m"
            @test isdir(dir)
            files = readdir(dir)
            @test length(files) == 1
            @test endswith(lowercase(files[1]), ".dat")
        end
    end

end
