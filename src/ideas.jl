"""
    macro linkmeas(gmeasname, lmeasname)

Link together two [`MeaningfulnessMeasure`](@ref), automatically defining
[`globaof`](@ref)/[`locaof`](@ref) and [`isglobalof`](@ref)/[`islocaof`](@ref).

See also [`globalof`](@ref), [`localof`](@ref), [`isglobalof`](@ref), [`islocalof`](@ref).
"""
# macro linkmeas(gmeasname, lmeasname)
#     quote
#         islocalof(::typeof(esc($(lmeasname))), ::typeof(esc($(gmeasname)))) = true
#         isglobalof(::typeof(esc($(gmeasname))), ::typeof(esc($(lmeasname)))) = true
#
#         localof(::typeof(esc($(gmeasname)))) = $(lmeasname)
#         globalof(::typeof(esc($(lmeasname)))) = $(gmeasname)
#     end
# end
