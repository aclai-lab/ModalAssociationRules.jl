# temporary definition for synthetic modal datasets (logiset);
# this is an extremely lightweight version of SoleData.FullDimensionalScalarLogiset

struct Logiset <: SoleData.AbstractLogiset
    instances::Vector{KripkeStructure}
end

function ModalAssociationRules.instances(logiset::Logiset)
    return logiset.instances
end

function ModalAssociationRules.ninstances(logiset::Logiset)
    return logiset |> instances |> length
end

function ModalAssociationRules.getinstance(
    logiset::Logiset,
    i::Int64
)::SoleLogics.LogicalInstance
    return SoleLogics.LogicalInstance(
        SoleLogics.InterpretationVector(logiset |> instances), i)
end

function ModalAssociationRules.frame(logiset::Logiset, i::Int64)
    return instances(logiset)[i] |> frame
end

function ModalAssociationRules.frame(
    interpvec::SoleLogics.InterpretationVector{KripkeStructure},
    i::Int64
)
    return interpvec.instances[1].frame
end

function Base.show(io::IO, logiset::Logiset)
    print(io, "Logiset with $(logiset.instances |> length) instances.")
end

function ModalAssociationRules.getinstance(logiset::Logiset, i::Integer)
    return logiset.instances[i]
end

function ModalAssociationRules.slicedataset(
    logiset::Logiset,
    instancerange::UnitRange{<:Integer}
)
    return instances(logiset)[instancerange] |> Logiset
end
