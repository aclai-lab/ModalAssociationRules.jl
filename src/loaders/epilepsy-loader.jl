using ZipFile
using DataFrames
using CategoricalArrays

using DataStructures: OrderedDict

"""
function load_epilepsy(
    dirpath::String=joinpath(dirname(pathof(ModalAssociationRules)), "../test/data/Epilepsy"),
    fileprefix::String="Epilepsy"
)

Loader for Epilepsy dataset.
More information on [timeseriesclassification.com](https://timeseriesclassification.com/description.php?Dataset=Epilepsy).
"""
function load_epilepsy(
    dirpath::String=joinpath(dirname(pathof(ModalAssociationRules)), "../test/data/Epilepsy"),
    fileprefix::String="Epilepsy"
)
    _load_epilepsy(dirpath, fileprefix)
end

function _load_epilepsy(dirpath::String, fileprefix::String)
    (X_train, y_train), (X_test, y_test) =
        (
            read("$(dirpath)/$(fileprefix)_TEST.arff", String) |> parseARFF,
            read("$(dirpath)/$(fileprefix)_TRAIN.arff", String) |> parseARFF,
        )

    variablenames = [
        "x", "y", "z",
    ]

    X_train  = fix_dataframe(X_train, variablenames)
    X_test   = fix_dataframe(X_test, variablenames)

    y_train = categorical(y_train)
    y_test = categorical(y_test)

    vcat(X_train, X_test), vcat(y_train, y_test)
end
