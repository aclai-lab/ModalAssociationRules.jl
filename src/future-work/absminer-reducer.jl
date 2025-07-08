# To solve https://github.com/aclai-lab/ModalAssociationRules.jl/issues/99
# (that is, remove the necessity of the Bulldozer subtype of Miner)
# this generic reducer could be implemented;
# it might require a bit of refactoring but should be correct.

##### """
#####     miner_reduce!(miners::AbstractVector{M}) where {M<:AbstractMiner}
#####
##### Reduce multiple [`AbstractMiner`](@ref), obtaining a new miner of the same type, wrapping
##### all the items within `miners` vector, as well as the data related to [`localmemo`](@ref)
##### and [`globalmemo`](@ref) [`MeaningfulnessMeasure`](@ref)s.
#####
##### !!! note
#####     Be careful, only information between items, and local and global meaningfulness measures
#####     are reduced together. The assumption is that everything else can virtually be ignored
#####     (e.g., [`info`](@ref), [`worldfilter`], [`itemset_policies`](@ref), etc.)
#####
##### # Arguments
##### - `miners::AbstractVector{M}`: the list of miners to be reduced together.
#####
##### # Keyword Arguments
##### - `includeitems::Bool=true`: whether to reduce `items(miner)`;
##### - `includefreqitems::Bool=true`: whether to reduce `freqitems(miner)`;
##### - `includelmemo::Bool=false`: whether to reduce `lmemo(miner)`; defaulted to false for performances;
##### - `includegmemo::Bool=true`: whether to reduce `gmemo(miner)`.
#####
##### See also [`AbstractMiner`](@ref), [`localmemo`](@ref), [`MeaningfulnessMeasure`](@ref),
##### [`globalmemo`](@ref).
##### """
##### function miner_reduce!(
#####     miners::AbstractVector{M};
#####     includeitems::Bool=true,
#####     includefreqitems::Bool=true,
#####     includelmemo::Bool=false,
#####     includegmemo::Bool=true,
##### ) where {M<:AbstractMiner}
#####     main_miner = miners |> first
#####
#####     decant = (to, from) -> begin
#####         for k in keys(from)
#####             to[k] = from[k]
#####         end
#####     end
#####
#####     # decant all the other miners in the first one
#####     for secondary_miner in miners[2:end]
#####         # instead of if-else, one could leverage metaprogramming to avoid repeating
#####         # these checks in the first place.
#####
#####         if includeitems
#####             union!(main_miner |> items, secondary_miner |> items)
#####         end
#####
#####         # beware: heavy computation
#####         if includefreqitems
#####             union!(main_miner |> freqitems, secondary_miner |> freqitems)
#####         end
#####
#####         # beware: heavy computation
#####         if includelmemo
#####             decant(main_miner |> localmemo, secondary_miner |> localmemo)
#####         end
#####
#####         if includegmemo
#####             decant(main_miner |> globalmemo, secondary_miner |> globalmemo)
#####         end
#####     end
#####
#####     return main_miner
##### end
