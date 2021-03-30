using JsonGrinder
using Test
using Documenter

function buf_printtree(data; kwargs...)
    buf = IOBuffer()
	printtree(buf, data; kwargs...)
	String(take!(buf))
end

const ≃ = isequal

@testset "JsonGrinder.jl" begin

	# this must be first, because other tests include more imports which break string asserts on types
	@testset "Doctests" begin
	    # there are breaking changes in printing of things between julia 1.5 and 1.6, so we run tests only on 1.6
	    @static if VERSION >= v"1.6.0-"
        	DocMeta.setdocmeta!(JsonGrinder, :DocTestSetup, :(using JsonGrinder); recursive=true)
        	doctest(JsonGrinder)
    	end
	end

	@testset "Extractors" begin
		include("extractors.jl")
		include("multirepresentation.jl")
	end
	@testset "Pipeline" begin
		include("pipelinetest.jl")
	end
	@testset "Schema" begin
		include("schema.jl")
	end
	@testset "HierarchicalUtils" begin
		include("hierarchical_utils_extractors.jl")
		include("hierarchical_utils_schema.jl")
	end
	include("show_html.jl")
	include("util.jl")

end
