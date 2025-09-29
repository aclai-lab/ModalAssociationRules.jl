# temporary definition for synthetic modal datasets (logiset);
# this is an extremely lightweight version of SoleData.FullDimensionalScalarLogiset

struct Logiset <: SoleData.AbstractLogiset
    instances::Vector{KripkeStructure}
end

function instances(logiset::Logiset)
    return logiset.instances
end

function ninstances(logiset::Logiset)
    return logiset |> instances |> length
end

function getinstance(
    logiset::Logiset,
    i::Int64
)::SoleLogics.LogicalInstance
    return SoleLogics.LogicalInstance(
        SoleLogics.InterpretationVector(logiset |> instances), i)
end

function frame(logiset::Logiset, i::Int64)
    instances(logiset)[i] |> frame
end

function Base.show(io::IO, logiset::Logiset)
    print(io, "Logiset with $(logiset.instances |> length) instances.")
end

function getinstance(logiset::Logiset, i::Integer)
    return logiset.instances[i]
end
