"""
	MultipleRepresentation(extractors::Tuple)

Extractor extracts item to a `ProductNode` where each item is different extractor and item is
extracted by all extractors in multirepresentation.

# Examples

## Example of both categorical and string representation

One of usecases is to use string representation for strings and categorical variable representation for most frequent values.
This allows model to more easily learn frequent or somehow else significant values, which creating meaningful representation
for previously unseen inputs.

```jldoctest
julia> e = MultipleRepresentation((ExtractString(false),
                        ExtractCategorical(["tcp", "udp", "dhcp"], false)));

julia> s1 = e("tcp")
ProductNode  # 1 obs, 48 bytes
  ├── e1: ArrayNode(2053×1 NGramMatrix with Int64 elements)  # 1 obs, 123 bytes
  ╰── e2: ArrayNode(4×1 OneHotArray with Bool elements)  # 1 obs, 76 bytes

julia> s1[:e1]
2053×1 ArrayNode{NGramMatrix{String, Vector{String}, Int64}, Nothing}:
 "tcp"

julia> s1[:e2]
4×1 ArrayNode{OneHotMatrix{UInt32, Vector{UInt32}}, Nothing}:
 ⋅
 1
 ⋅
 ⋅

julia> s2 = e("http")
ProductNode  # 1 obs, 48 bytes
  ├── e1: ArrayNode(2053×1 NGramMatrix with Int64 elements)  # 1 obs, 124 bytes
  ╰── e2: ArrayNode(4×1 OneHotArray with Bool elements)  # 1 obs, 76 bytes

julia> s2[:e1]
2053×1 ArrayNode{NGramMatrix{String, Vector{String}, Int64}, Nothing}:
 "http"

julia> s2[:e2]
4×1 ArrayNode{OneHotMatrix{UInt32, Vector{UInt32}}, Nothing}:
 ⋅
 ⋅
 ⋅
 1
```

## Example of irregular schema representation

The other usecase is to handle irregular schema, where extractor returns `missing` representation if it's unable to
extract it properly. Of course there do not have to be only leaf value extractors, some extractors may be ExtractDict,
while other are extracting leaves etc.

```jldoctest
julia> e = MultipleRepresentation((ExtractString(), ExtractScalar(Float32, 2, 3)));

julia> s1 = e(5)
ProductNode  # 1 obs, 40 bytes
  ├── e1: ArrayNode(2053×1 NGramMatrix with Union{Missing, Int64} elements)  # 1 obs, 112 bytes
  ╰── e2: ArrayNode(1×1 Array with Union{Missing, Float32} elements)  # 1 obs, 53 bytes

julia> s1[:e1]
2053×1 ArrayNode{NGramMatrix{Union{Missing, String}, Vector{Union{Missing, String}}, Union{Missing, Int64}}, Nothing}:
 missing

julia> s1[:e2]
1×1 ArrayNode{Matrix{Union{Missing, Float32}}, Nothing}:
 9.0f0

julia> s2 = e("hi")
ProductNode  # 1 obs, 40 bytes
  ├── e1: ArrayNode(2053×1 NGramMatrix with Union{Missing, Int64} elements)  # 1 obs, 122 bytes
  ╰── e2: ArrayNode(1×1 Array with Union{Missing, Float32} elements)  # 1 obs, 53 bytes

julia> s2[:e1]
2053×1 ArrayNode{NGramMatrix{Union{Missing, String}, Vector{Union{Missing, String}}, Union{Missing, Int64}}, Nothing}:
 "hi"

julia> s2[:e2]
1×1 ArrayNode{Matrix{Union{Missing, Float32}}, Nothing}:
 missing

```
"""
struct MultipleRepresentation{E<:Union{NamedTuple, Tuple}}
	extractors::E
end

MultipleRepresentation(vs::AbstractVector) = MultipleRepresentation((;[Symbol("e$(i)") => v for (i,v) in enumerate(vs)]...))
MultipleRepresentation(vs::Tuple) = MultipleRepresentation((;[Symbol("e$(i)") => v for (i,v) in enumerate(vs)]...))
(m::MultipleRepresentation)(x::HierarchicType; store_input=false) = ProductNode(map(e -> e(x; store_input), m.extractors))
Base.keys(e::MultipleRepresentation) = keys(e.extractors)

Base.hash(e::MultipleRepresentation, h::UInt) = hash(e.extractors, h)
Base.:(==)(e1::MultipleRepresentation, e2::MultipleRepresentation) = e1.extractors == e2.extractors
Base.getindex(e::MultipleRepresentation, i::Int) = e.extractors[i]
