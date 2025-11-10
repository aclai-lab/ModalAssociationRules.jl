using Random
using DataStructures
using StatsBase

# TODO - these dependencies should be removed from MAS, as they are only useful
# during the experiments.
using ImageFiltering
using MAT

# this script has been adapted from
# https://github.com/aclai-lab/results/blob/master/datasets/land-cover.jl

data_dir = joinpath(@__DIR__, "test", "experiments", "LandCover", "data")

function LandCoverDataset(
	dataset_name::String
	;
	window_size::Union{Integer,NTuple{2,Integer}} = 1,
	pad_window_size::Union{Integer,NTuple{2,Integer}} = window_size,
	ninstances_per_class::Union{Nothing,Integer} = nothing,
    ninstances_per_class_strategy::Symbol = :updownsampling,
	flattened::Union{Bool,Symbol} = false,
	apply_filter::Union{Bool,Tuple} = false,
	seed = 1 :: Integer,
    return_dicts = false :: Bool,
    return_imgsize = false :: Bool,
)
	if window_size isa Integer
		window_size = (window_size, window_size)
	end
	if pad_window_size isa Integer
		pad_window_size = (pad_window_size, pad_window_size)
	end
	@assert pad_window_size[1] >= window_size[1] && pad_window_size[2] >= window_size[2]

	@assert isodd(window_size[1]) && isodd(window_size[2])

    @assert ninstances_per_class_strategy in [:updownsampling, :discard_classes] "Unknown ninstances_per_class_strategy: $(ninstances_per_class_strategy)."

    ########################################################################################

    function IndianPinesDataset(;modIndianPines8 = false)
        X = matread(
            joinpath(data_dir, "IndianPines/Indian_pines_corrected.mat"))["indian_pines_corrected"]

        Y = matread(
            joinpath(data_dir, "IndianPines/Indian_pines_gt.mat"))["indian_pines_gt"]

        (X, Y) = map(((x)->round.(Int,x)), (X, Y))
        (X,Y), (modIndianPines8 == false ? [
                "Alfalfa",
                "Corn-notill",
                "Corn-mintill",
                "Corn",
                "Grass-pasture",
                "Grass-trees",
                "Grass-pasture-mowed",
                "Hay-windrowed",
                "Oats",
                "Soybean-notill",
                "Soybean-mintill",
                "Soybean-clean",
                "Wheat",
                "Woods",
                "Buildings-Grass-Trees-Drives",
                "Stone-Steel-Towers",
            ] : OrderedDict(
                2  => "Corn-notill",
                3  => "Corn-mintill",
                5  => "Grass-pasture",
                8  => "Hay-windrowed", # "Grass-trees",
                10 => "Soybean-notill",
                11 => "Soybean-mintill",
                12 => "Soybean-clean",
                14 => "Woods",
            )
        )
    end

    function SalinasDataset()
        X = matread(data_dir * "salinas/Salinas_corrected.mat")["salinas_corrected"]
        Y = matread(data_dir * "salinas/Salinas_gt.mat")["salinas_gt"]
        (X, Y) = map(((x)->round.(Int,x)), (X, Y))
        (X, Y), [
            "Brocoli_green_weeds_1",
            "Brocoli_green_weeds_2",
            "Fallow",
            "Fallow_rough_plow",
            "Fallow_smooth",
            "Stubble",
            "Celery",
            "Grapes_untrained",
            "Soil_vinyard_develop",
            "Corn_senesced_green_weeds",
            "Lettuce_romaine_4wk",
            "Lettuce_romaine_5wk",
            "Lettuce_romaine_6wk",
            "Lettuce_romaine_7wk",
            "Vinyard_untrained",
            "Vinyard_vertical_trellis",
        ]
    end

    function SalinasADataset()
        X = matread(data_dir * "salinas-A/SalinasA_corrected.mat")["salinasA_corrected"]
        Y = matread(data_dir * "salinas-A/SalinasA_gt.mat")["salinasA_gt"]
        (X, Y) = map(((x)->round.(Int,x)), (X, Y))
        (X, Y), OrderedDict(
            1  => "Brocoli_green_weeds_1",
            10 => "Corn_senesced_green_weeds",
            11 => "Lettuce_romaine_4wk",
            12 => "Lettuce_romaine_5wk",
            13 => "Lettuce_romaine_6wk",
            14 => "Lettuce_romaine_7wk",
        )
    end

    function PaviaCentreDataset()
        X = matread(data_dir * "paviaC/Pavia.mat")["pavia"]
        Y = matread(data_dir * "paviaC/Pavia_gt.mat")["pavia_gt"]
        (X, Y) = map(((x)->round.(Int,x)), (X, Y))
        (X,Y), [
            "Water",
            "Trees",
            "Asphalt",
            "Self-Blocking Bricks",
            "Bitumen",
            "Tiles",
            "Shadows",
            "Meadows",
            "Bare Soil",
        ]
    end

    function PaviaUniversityDataset()
        X = matread(
            joinpath(data_dir, "paviauni/PaviaU.mat"))["paviauni"]
        Y = matread(
            joinpath(data_dir, "paviauni/PaviaU_gt.mat"))["paviaU_gt"]
        (X, Y) = map(((x)->round.(Int,x)), (X, Y))
        (X,Y), [
            "Asphalt",
            "Meadows",
            "Gravel",
            "Trees",
            "Painted metal sheets",
            "Bare Soil",
            "Bitumen",
            "Self-Blocking Bricks",
            "Shadows",
        ]
    end

    ########################################################################################

	rng = Random.MersenneTwister(seed)

	println("Load LandCoverDataset: $(dataset_name)...")
	println("window_size         = $(window_size)")
	println("pad_window_size     = $(pad_window_size)")
	println("ninstances_per_class  = $(ninstances_per_class)")
    println("ninstances_per_class_strategy = $(ninstances_per_class_strategy)")
	println("flattened           = $(flattened)")
	println("apply_filter        = $(apply_filter)")
	println("seed                = $(seed)")

	(Xmap, Ymap), class_names_map =
		if dataset_name == "IndianPines"
			IndianPinesDataset()
		elseif dataset_name == "IndianPines8"
			IndianPinesDataset(; modIndianPines8 = true)
		elseif dataset_name == "Salinas"
			SalinasDataset()
		elseif dataset_name == "Salinas-A"
			SalinasADataset()
		elseif dataset_name == "Pavia Centre"
			PaviaCentreDataset()
		elseif dataset_name == "Pavia University"
			PaviaUniversityDataset()
		else
			throw_n_log("Unknown land cover dataset_name: $(dataset_name)")
	end

	println("Image size: $(size(Xmap))")

	X, Y, tot_variables = size(Xmap, 1), size(Xmap, 2), size(Xmap, 3)

	# Note: important that these are sorted
	# existingLabels = sort(filter!(l->l≠0, unique(Ymap)))
	existingLabels = sort(collect(keys(class_names_map)))
	n_classes = length(existingLabels)

	x_pad, y_pad = floor(Int,window_size[1]/2), floor(Int,window_size[2]/2)
	x_dummypad, y_dummypad = floor(Int,pad_window_size[1]/2), floor(Int,pad_window_size[2]/2)

	# println(1+x_dummypad, ":", (X-x_dummypad))
	# println(1+y_dummypad, ":", (Y-y_dummypad))

	pixel_coords, ninstances, _X, labels = begin
		pixel_coords =
            if isnothing(ninstances_per_class) # obtain all
                pixel_coords = []
                for x in 1+x_dummypad:(X-x_dummypad)
                    for y in 1+y_dummypad:(Y-y_dummypad)
                        exLabel = Ymap[x,y];
                        if exLabel == 0 || ! (exLabel in existingLabels)
                            continue
                        end

                        push!(pixel_coords, (x,y))
                    end
                end
                pixel_coords
    		else # obtain_with_random_sampling
                # Derive the total number of samples per class
                class_counts_d = OrderedDict(y => 0 for y in existingLabels)
                no_class_counts = 0
                for exLabel in Ymap
                    if exLabel == 0 || ! (exLabel in existingLabels)
                        no_class_counts += 1
                    else
                        class_counts_d[exLabel] += 1
                    end
                end
                println("class_counts_d = $(zip(class_names_map,class_counts_d) |> collect)")
                println("no_class_counts = $(no_class_counts)")

                class_is_to_ignore = OrderedDict(y => (ninstances_per_class_strategy == :discard_classes && class_counts_d[y] < ninstances_per_class) for y in existingLabels)

                n_classes = begin
                    if sum(values(class_is_to_ignore)) != 0
                        @warn "Warning! The following classes will be ignored in order to balance the dataset:"

                        ignored_existingLabels = filter(y->(class_is_to_ignore[y]), existingLabels)
                        non_ignored_existingLabels = map(y->!(class_is_to_ignore[y]), existingLabels)

                        print("ignored classes: $([(class_names_map[y],class_counts_d[y]) for y in ignored_existingLabels])")

                        filter(y->(class_is_to_ignore[y]), existingLabels)
                        sum(non_ignored_existingLabels)
                    else
                        n_classes
                    end
                end

                println("n_classes = $(n_classes)")

                ninstances = ninstances_per_class * n_classes
                println("ninstances = $(ninstances_per_class) * $(n_classes) = $(ninstances)")

                allow_upsampling = (ninstances_per_class_strategy in [:updownsampling])

                pixel_coords = []
                sampled_class_counts_d = OrderedDict(y=>0 for y in existingLabels)
                for i_instance in 1:ninstances
                    # print(i_instance)
                    while (
                        x = rand(rng, 1+x_dummypad:(X-x_dummypad));
                        y = rand(rng, 1+y_dummypad:(Y-y_dummypad));
                        exLabel = Ymap[x,y];
                        exLabel == 0 || (! (exLabel in existingLabels)) || # Dummy class
                        class_is_to_ignore[exLabel] || # Must ignore class
                        ((x,y) in pixel_coords && !allow_upsampling) || # Pixel already picked
                        sampled_class_counts_d[exLabel] == ninstances_per_class # Already picked enough pixels for this class
                    )
                    end

                    push!(pixel_coords, (x,y))
                    sampled_class_counts_d[exLabel] += 1
                    # readline()
                end

                if (length(pixel_coords) != ninstances)
                    throw_n_log("ERROR! Sampling failed! $(ninstances) $(length(pixel_coords))")
                end

                pixel_coords
    		end

        ninstances = length(pixel_coords)
        _X = Array{eltype(Xmap), 4}(undef, window_size[1], window_size[2], ninstances, tot_variables)
        labels = Vector{eltype(Ymap)}(undef, ninstances)

        for (i,(x,y)) in enumerate(pixel_coords)
            _X[:,:,i,:] .= Xmap[x-x_pad:x+x_pad, y-y_pad:y+y_pad, :]
            labels[i]        = Ymap[x,y]
        end

        pixel_coords, ninstances, _X, labels
	end

	# Apply a convolutional filter
	if apply_filter != false
		if apply_filter[1] == "avg"
			k = apply_filter[2]
			_X = parent(imfilter(_X, ones(k,k,1,1)/9, Inner()))
			@assert size(_X)[1:2] == (window_size[1]-k+1, window_size[2]-k+1)
		else
			throw_n_log("Unexpected value for apply_filter: $(apply_filter)")
		end
	end

	_X =
        if flattened != false
            _X =
        		if flattened == :flattened
        			reshape(_X, (ninstances,(size(_X, 1)*size(_X, 2)*size(_X, 4))))
        		elseif flattened == :averaged
        			_X = sum(_X, dims=(1,2))./(size(_X, 1)*size(_X, 2))
        			dropdims(_X; dims=(1,2))
        		elseif flattened == :minmax
                    _X_min = dropdims(minimum(_X, dims=(1,2)); dims=(1,2))
                    _X_max = dropdims(maximum(_X, dims=(1,2)); dims=(1,2))
                    vcat(_X_min, _X_max)
                else
        			throw_n_log("Unexpected value for flattened: $(flattened)")
    		end
    		permutedims(_X, [2,1])
    	elseif (size(_X, 1), size(_X, 2)) == (1, 1)
            _X = dropdims(_X; dims=(1,2))
    		permutedims(_X, [2,1])
    	else
    		permutedims(_X, [1,2,4,3])
	end


    effective_class_counts_d = OrderedDict(y => 0 for y in existingLabels)
    for i_instance in 1:ninstances
        effective_class_counts_d[labels[i_instance]] += 1
    end
    println("effective_class_counts_d = $(zip(class_names_map,effective_class_counts_d) |> collect)")
    println("countmap(labels) = $(countmap(labels))")


    # # Sort pixel_coords by label
    # sp = sortperm(labels)
    # labels = labels[sp]
    # _X = _X[:,:,sp,:]
    # class_counts = Tuple(effective_class_counts_d[y] for y in existingLabels) # Note: dangerous: assumes existingLabels is sorted!

    # println("class_counts = $(class_counts)")
    # @assert length(labels) == sum(class_counts) "length(labels) = $(length(labels)) != sum(class_counts) = $(sum(class_counts))"

    # println([class_names_map[y] for y in existingLabels])
    # println(labels)
    _Y = [class_names_map[y] for y in labels]

    _X = OrderedDict([(i_pixel_coord => instance) for (i_pixel_coord, instance) in zip(enumerate(pixel_coords), eachslice(_X; dims=length(size(_X))))])
    _Y = OrderedDict([(i_pixel_coord => y) for (i_pixel_coord, y) in zip(enumerate(pixel_coords), _Y)])

    dataset = begin
        if return_dicts
           (_X, _Y)
        else
            dict2cube((_X, _Y),)
        end
    end

    if return_imgsize
        dataset, size(Xmap)
    else
        dataset
    end
end


# taken from:
# https://github.com/aclai-lab/results/blob/master/datasets/dataset-utils.jl
function dict2cube(X::OrderedDict)
    # cat(values(X)...; dims=(length(size(first(values(X))))+1)) # Simple but causes StackOverflowError because of the splatting
    _X = collect(values(X))
    s = unique(size.(_X))
    @assert length(s) == 1 "$(s)"
    s = s[1]
    __X = similar(first(_X), s..., length(_X))
    for (i,x) in enumerate(_X)
        __X[[(:) for j in 1:length(s)]...,i] .= x
    end
    __X
end

dict2cube((X,Y)::Tuple{OrderedDict,Union{OrderedDict,AbstractVector}}) = (dict2cube(X), collect(values(Y)))
