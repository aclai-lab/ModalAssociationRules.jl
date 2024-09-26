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

function load_NATOPS(
    dirpath::String=joinpath(dirname(pathof(ModalAssociationRules)), "../test/data/NATOPS"),
    fileprefix::String="NATOPS"
)
    # if data is not locally available (e.g., in test/data/),
    # then try download it using SoleData default loader.
    try
        _load_NATOPS(dirpath, fileprefix)
    catch error
        if error isa SystemError
            SoleData.load_arff_dataset("NATOPS")
        else
            rethrow(error)
        end
    end
end

function _load_NATOPS(dirpath::String, fileprefix::String)
    (X_train, y_train), (X_test, y_test) = begin
        (
            read("$(dirpath)/$(fileprefix)_TEST.arff", String) |> SoleData.parseARFF,
            read("$(dirpath)/$(fileprefix)_TRAIN.arff", String) |> SoleData.parseARFF,
        )
    end

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

    variablenames_latex = [
    "\\text{hand tip l}_X",
    "\\text{hand tip l}_Y",
    "\\text{hand tip l}_Z",
    "\\text{hand tip r}_X",
    "\\text{hand tip r}_Y",
    "\\text{hand tip r}_Z",
    "\\text{elbow l}_X",
    "\\text{elbow l}_Y",
    "\\text{elbow l}_Z",
    "\\text{elbow r}_X",
    "\\text{elbow r}_Y",
    "\\text{elbow r}_Z",
    "\\text{wrist l}_X",
    "\\text{wrist l}_Y",
    "\\text{wrist l}_Z",
    "\\text{wrist r}_X",
    "\\text{wrist r}_Y",
    "\\text{wrist r}_Z",
    "\\text{thumb l}_X",
    "\\text{thumb l}_Y",
    "\\text{thumb l}_Z",
    "\\text{thumb r}_X",
    "\\text{thumb r}_Y",
    "\\text{thumb r}_Z",
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

    @assert nrow(X_train) == length(y_train) "$(nrow(X_train)), $(length(y_train))"

    y_train = categorical(y_train)
    y_test = categorical(y_test)
    vcat(X_train, X_test), vcat(y_train, y_test)
end
