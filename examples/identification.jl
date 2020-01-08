using Flux, MLDataPattern, Mill, JsonGrinder, JSON, Statistics

using JsonGrinder: suggestextractor, ExtractCategorical, ExtractBranch
using Mill: mapdata, sparsify, reflectinmodel

###############################################################
# start by loading all samples
###############################################################
samples = map(readlines("/Users/tomas.pevny/Downloads/dataset/train.json")) do s
	JSON.parse(s)
end
JSON.print(samples[1],2)
test_samples = map(readlines("/Users/tomas.pevny/Downloads/dataset/test.json")) do s
	JSON.parse(s)
end
ns = extract_target.vec["device_class"].items


###############################################################
# create schema of the JSON
###############################################################
sch = JsonGrinder.schema(samples);
extractor = suggestextractor(Float32, sch, 0)
extract_target = ExtractBranch(extractor.vec,nothing)
target = extractbatch(extract_target, samples).data
extract_data = ExtractBranch(nothing, extractor.other)
data = extractbatch(extract_data, samples)

model = reflectinmodel(data[1:10], d -> Dense(d,20, relu), d -> SegmentedMeanMax(d), b = Dict("" => d -> Chain(Dense(d, 20, relu), Dense(20, size(target,1)))));
model(data[1:10])

###############################################################
#  train
###############################################################
function makebatch()
	i = rand(1:nobs(data), 100)
	data[i], target[:,i]
end
opt = ADAM()
ps = params(model)
loss = (x,y) -> Flux.logitcrossentropy(model(x).data,y)

#a little test before training
# x, y = makebatch()
# loss(x,y)
# gradient(() -> sum(model(x).data), ps)

cb = () -> begin
	o = model(data).data
	println("crossentropy = ",Flux.logitcrossentropy(o,target) ," accuracy = ",mean(Flux.onecold(softmax(o)) .== Flux.onecold(target)))
end
Flux.Optimise.train!(loss, ps, repeatedly(makebatch,10000), opt, cb = Flux.throttle(cb, 60))

#calculate the accuracy
cb()

o = Flux.onecold(model(extractbatch(extract_data, test_samples)).data);
o = [ns[i] for i in o];
id = [s["device_id"] for s in test_samples];
# Id,Predicted
# crossentropy = 0.028738448 accuracy = 0.999067454149829. = F-score 0.86994
writedlm("/Users/tomas.pevny/Downloads/dataset/kaggle.csv",hcat(id, o), ",")
