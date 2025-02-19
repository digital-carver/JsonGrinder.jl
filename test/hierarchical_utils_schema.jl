using Mill, JSON, Flux, JsonGrinder, Test
using HierarchicalUtils
import HierarchicalUtils: printtree
using JsonGrinder: DictEntry, suggestextractor, schema

j1 = JSON.parse("""{"a": 4, "b": {"a":[1,2,3],"b": 1},"c": { "a": {"a":[1,2,3],"b":[4,5,6]}}}""",inttype=Float64)
j2 = JSON.parse("""{"a": 4, "c": {"a":{"a":[2,3],"b":[5,6]}}}""")
j3 = JSON.parse("""{"a": 4, "b": {"a":[1,2,3],"b": 1}}""")
j4 = JSON.parse("""{"a": 4, "b": {}}""")
j5 = JSON.parse("""{"b": {}}""")
j6 = JSON.parse("""{}""")

sch = schema([j1,j2,j3,j4,j5,j6])

@testset "printtree" begin
    @test buf_printtree(sch, trav=true) ==
    """
    [Dict] [""]  # updated = 6
      ├── a: [Scalar - Int64], 1 unique values ["E"]  # updated = 4
      ├── b: [Dict] ["U"]  # updated = 4
      │        ├── a: [List] ["Y"]  # updated = 2
      │        │        ╰── [Scalar - Int64], 3 unique values ["a"]  # updated = 6
      │        ╰── b: [Scalar - Int64], 1 unique values ["c"]  # updated = 2
      ╰── c: [Dict] ["k"]  # updated = 2
               ╰── a: [Dict] ["s"]  # updated = 2
                        ├── a: [List] ["u"]  # updated = 2
                        │        ╰── [Scalar - Float64,Int64], 3 unique values ["v"]  # updated = 5
                        ╰── b: [List] ["w"]  # updated = 2
                                 ╰── [Scalar - Float64,Int64], 3 unique values ["x"]  # updated = 5
    """
end

@testset "nnodes" begin
    @test nnodes(sch) == 12
    @test nnodes(sch.childs[:a]) == 1
    @test nnodes(sch.childs[:b]) == 4
    @test nnodes(sch.childs[:c]) == 6
end

@testset "nleafs" begin
    @test nleafs(sch.childs[:a]) + nleafs(sch.childs[:b]) + nleafs(sch.childs[:c]) == nleafs(sch)
end

@testset "children" begin
    @test children(sch) == [:a=>sch[:a], :b=>sch[:b], :c=>sch[:c]]
    @test children(sch[:a]) == ()
    @test children(sch[:b]) == [:a=>sch[:b][:a], :b=>sch[:b][:b]]
    @test children(sch[:b][:a]) == (sch[:b][:a].items,)
    @test children(sch[:b][:b]) == ()
    @test children(sch[:c]) == [:a=>sch[:c][:a]]
    @test children(sch[:c][:a]) == [:a=>sch[:c][:a][:a], :b=>sch[:c][:a][:b]]
    @test children(sch[:c][:a][:a]) == (sch[:c][:a][:a].items,)
    @test children(sch[:c][:a][:b]) == (sch[:c][:a][:b].items,)
end

@testset "nchildren" begin
    @test nchildren(sch) == 3
    @test nchildren(sch[:a]) == 0
    @test nchildren(sch[:b]) == 2
    @test nchildren(sch[:b][:a]) == 1
    @test nchildren(sch[:b][:b]) == 0
    @test nchildren(sch[:c]) == 1
    @test nchildren(sch[:c][:a]) == 2
    @test nchildren(sch[:c][:a][:a]) == 1
    @test nchildren(sch[:c][:a][:b]) == 1
end

@testset "getindex on strings" begin
    @test sch[""] == sch
    @test sch["E"] == sch[:a]
    @test sch["U"] == sch[:b]
    @test sch["Y"] == sch[:b][:a]
    @test sch["a"] == sch[:b][:a].items
    @test sch["c"] == sch[:b][:b]
    @test sch["k"] == sch[:c]
    @test sch["s"] == sch[:c][:a]
    @test sch["u"] == sch[:c][:a][:a]
    @test sch["v"] == sch[:c][:a][:a].items
    @test sch["w"] == sch[:c][:a][:b]
    @test sch["x"] == sch[:c][:a][:b].items
end

@testset "NodeIterator" begin
    @test collect(NodeIterator(sch)) == [sch[""], sch["E"], sch["U"], sch["Y"], sch["a"], sch["c"],
        sch["k"], sch["s"], sch["u"], sch["v"], sch["w"], sch["x"]]
end

@testset "LeafIterator" begin
    @test collect(LeafIterator(sch)) == [sch["E"], sch["a"], sch["c"], sch["v"], sch["x"]]
end

@testset "TypeIterator" begin
    @test collect(TypeIterator(DictEntry, sch)) == [sch[""], sch["U"], sch["k"], sch["s"]]
end

@testset "print with empty lists" begin
    j1 = JSON.parse("""{"a": 4, "c": { "a": {"a":[1,2,3],"b":[4,5,6]}}, "d":[]}""",inttype=Float64)
    j2 = JSON.parse("""{"a": 4, "c": { "a": {"a":[2,3],"b":[5,6]}}, "d":[]}""")
    j3 = JSON.parse("""{"a": 4, "d":[]}""")
    j4 = JSON.parse("""{"a": 4, "d":[]}""")
    j5 = JSON.parse("""{"d":[]}""")
    j6 = JSON.parse("""{}""")

    sch = schema([j1,j2,j3,j4,j5,j6])

    @test buf_printtree(sch, trav=true) ==
    """
    [Dict] [""]  # updated = 6
      ├── a: [Scalar - Int64], 1 unique values ["E"]  # updated = 4
      ├── d: [Empty List] ["U"]  # updated = 5
      │        ╰── Nothing ["c"]
      ╰── c: [Dict] ["k"]  # updated = 2
               ╰── a: [Dict] ["s"]  # updated = 2
                        ├── a: [List] ["u"]  # updated = 2
                        │        ╰── [Scalar - Float64,Int64], 3 unique values ["v"]  # updated = 5
                        ╰── b: [List] ["w"]  # updated = 2
                                 ╰── [Scalar - Float64,Int64], 3 unique values ["x"]  # updated = 5
    """
end

@testset "print with multi entry" begin
    j1 = JSON.parse("""{"a": 4, "c": { "a": {"a":[1,2,3],"b":[4,5,6]}}, "d":[]}""",inttype=Float64)
    j2 = JSON.parse("""{"a": 4, "c": { "a": {"a":[2,3],"b":[5,6]}}, "d":[]}""")
    j3 = JSON.parse("""{"a": 4, "c": 5, "d":[]}""")
    j4 = JSON.parse("""{"a": 4, "c": 6.5, "d":[]}""")
    j5 = JSON.parse("""{"c": ["Oh", "Hi", "Mark"], "d":[]}""")
    j6 = JSON.parse("""{}""")

    sch = schema([j1,j2,j3,j4,j5,j6])

    @test buf_printtree(sch, trav=true) ==
    """
    [Dict] [""]  # updated = 6
      ├── a: [Scalar - Int64], 1 unique values ["E"]  # updated = 4
      ├── d: [Empty List] ["U"]  # updated = 5
      │        ╰── Nothing ["c"]
      ╰── c: [MultiEntry] ["k"]  # updated = 5
               ├── 1: [Dict] ["o"]  # updated = 2
               │        ╰── a: [Dict] ["q"]  # updated = 2
               │                 ├── a: [List] ["qU"]  # updated = 2
               │                 │        ╰── [Scalar - Float64,Int64], 3 unique values ["qk"]  # updated = 5
               │                 ╰── b: [List] ["r*"]  # updated = 2
               │                          ╰── [Scalar - Float64,Int64], 3 unique values ["rE"]  # updated = 5
               ├── 2: [Scalar - Float64,Int64], 2 unique values ["s"]  # updated = 2
               ╰── 3: [List] ["w"]  # updated = 1
                        ╰── [Scalar - String], 3 unique values ["y"]  # updated = 3
    """
end

@testset "print with multi entry 2" begin
    j1 = JSON.parse("""{"a": "4"}""",inttype=Float64)
    j2 = JSON.parse("""{"a": ["It's", "over", 9000]}""")
    j3 = JSON.parse("""{"a": 5.5}""")
    j4 = JSON.parse("""{"a": "5.5"}""")
    j5 = JSON.parse("""{"a": "Oh, Hi Mark"}""")
    j6 = JSON.parse("""{"a": 4}""")

    sch = schema([j1,j2,j3,j4,j5,j6])

    @test buf_printtree(sch, trav=true) ==
    """
    [Dict] [""]  # updated = 6
      ╰── a: [MultiEntry] ["U"]  # updated = 6
               ├── 1: [Scalar - String], 3 unique values ["c"]  # updated = 3
               ├── 2: [List] ["k"]  # updated = 1
               │        ╰── [MultiEntry] ["o"]  # updated = 3
               │              ├── 1: [Scalar - String], 2 unique values ["p"]  # updated = 2
               │              ╰── 2: [Scalar - Int64], 1 unique values ["q"]  # updated = 1
               ╰── 3: [Scalar - Float64,Int64], 2 unique values ["s"]  # updated = 2
    """
end


@testset "Base.show" begin
    j1 = JSON.parse("""{"a": "4"}""",inttype=Float64)
    j2 = JSON.parse("""{"a": ["It's", "over", 9000]}""")
    j3 = JSON.parse("""{"a": 5.5}""")
    j4 = JSON.parse("""{"a": "5.5"}""")
    j5 = JSON.parse("""{"a": "Oh, Hi Mark"}""")
    j6 = JSON.parse("""{"a": 4}""")

    sch = schema([j1,j2,j3,j4,j5,j6])
    @test repr(sch) == "DictEntry"
    @test repr("text/plain", sch) == buf_printtree(sch; trav=false, htrunc=5, vtrunc=10, breakline=false)
    repr(Dict(1=>2))
end
