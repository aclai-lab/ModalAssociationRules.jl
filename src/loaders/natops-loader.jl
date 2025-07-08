# Offline loader for NATOPS dataset.

# Usage:
# call `load_natops()`, eventually specifying the installation path of NATOPS if it is not
# downloaded in /test/data/NATOPS.
# Otherwise it will be downloaded from timeseriesclassification.com, but might be
# unavailable.

using ZipFile
using DataFrames
using CategoricalArrays

using DataStructures: OrderedDict

"""
function load_NATOPS(
    dirpath::String=joinpath(dirname(pathof(ModalAssociationRules)), "../test/data/NATOPS"),
    fileprefix::String="NATOPS"
)

Loader for NATOPS dataset.
More on [the official GitHub repository](https://github.com/yalesong/natops).
"""
function load_NATOPS(
    dirpath::String=joinpath(dirname(pathof(ModalAssociationRules)), "../test/data/NATOPS"),
    fileprefix::String="NATOPS"
)
    # A previous implementation of this loader was very kind with the user, and tried
    # to download NATOPS by internet if an error occurred locally:
    # try
    #     _load_NATOPS(dirpath, fileprefix)
    # catch error
    #     if error isa SystemError
    #         SoleData.load_arff_dataset("NATOPS")
    #     else
    #         rethrow(error)
    #     end
    # end

    _load_NATOPS(dirpath, fileprefix)
end

function _load_NATOPS(dirpath::String, fileprefix::String)
    (X_train, y_train), (X_test, y_test) =
        (
            read("$(dirpath)/$(fileprefix)_TEST.arff", String) |> SoleData.parseARFF,
            read("$(dirpath)/$(fileprefix)_TRAIN.arff", String) |> SoleData.parseARFF,
        )

    variablenames = [
        "X[Hand tip l]",
        "Y[Hand tip l]",
        "Z[Hand tip l]",
        "X[Hand tip r]",
        "Y[Hand tip r]",
        "Z[Hand tip r]",
        "X[Elbow l]",
        "Y[Elbow l]",
        "Z[Elbow l]",
        "X[Elbow r]",
        "Y[Elbow r]",
        "Z[Elbow r]",
        "X[Wrist l]",
        "Y[Wrist l]",
        "Z[Wrist l]",
        "X[Wrist r]",
        "Y[Wrist r]",
        "Z[Wrist r]",
        "X[Thumb l]",
        "Y[Thumb l]",
        "Z[Thumb l]",
        "X[Thumb r]",
        "Y[Thumb r]",
        "Z[Thumb r]",
    ]

    X_train  = SoleData.fix_dataframe(X_train, variablenames)
    X_test   = SoleData.fix_dataframe(X_test, variablenames)

    class_names = [
        "I have command",
        "All clear",
        "Not clear",
        "Spread wings",
        "Fold wings",
        "Lock wings",
    ]

    fix_class_names(y) = class_names[round(Int, parse(Float64, y))]

    y_train = map(fix_class_names, y_train)
    y_test  = map(fix_class_names, y_test)

    # if !(nrow(X_train) == length(y_train))
    #     throw(ArgumentError("Mismatching dimensions for X_train ($(nrow(X_train))) and " *
    #         "y_train ($(length(y_train)))"))
    # end

    y_train = categorical(y_train)
    y_test = categorical(y_test)
    vcat(X_train, X_test), vcat(y_train, y_test)
end
