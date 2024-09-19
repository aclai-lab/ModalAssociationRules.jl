# Data-free dictionary implementation that can be shared on multiple threads.
# https://discourse.julialang.org/t/thread-local-dict-for-each-thread/51441/3
#
"""
    struct ThreadDict{D<:AbstractDict}
        protection::ReentrantLock
        dictionaries::Dict{Int,D}
    end

Dictionary protected from race-conditions through a lock called `protection`.
Actually, this structure embodies multiple dictionaries, each of which is accessed with
respect to the current thread id.
"""
struct ThreadDict{D<:AbstractDict}
    protection::ReentrantLock
    dictionaries::Dict{Int,D}
    ThreadDict(::Type{D}) where {D<:AbstractDict} = new{D}(ReentrantLock(), Dict{Int,D}())
end

function Base.getindex(t::ThreadDict, x)
    lock(t.protect) do
        _threadid = threadid()
        if !haskey(t.dicts, _threadid)
            t.dicts[_threadid] = Dict{Symbol, Float64}()
        end
        return t.dicts[_threadid][x]
    end
end

function Base.setindex!(t::ThreadDict, x, y)
    lock(t.protect) do
        if haskey(t.dicts, threadid()) == false
            t.dicts[threadid()] = Dict{Symbol, Float64}()
        end
        t.dicts[threadid()][y] = x
    end
end
