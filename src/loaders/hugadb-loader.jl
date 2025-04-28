# Loader for HuGaDB dataset.

# Usage:
# call `load_hugadb(filepath)`, specifying one specific the filepath containing the
# recordings for one specific partecipant.

using ZipFile
using DataFrames
using CategoricalArrays

using DataStructures: OrderedDict

function load_hugadb(
    filepath::String=joinpath(dirname(pathof(ModalAssociationRules)),
        "..", "test", "data", "HuGaDB", "HuGaDB_v2_various_01_00.txt"),
)
    (X_train, y_train), (X_test, y_test) =
        (
            read("$(dirpath)/$(fileprefix)_TEST.arff", String) |> SoleData.parseARFF,
            read("$(dirpath)/$(fileprefix)_TRAIN.arff", String) |> SoleData.parseARFF,
        )

    variablenames = ["acc_rf_x","acc_rf_y","acc_rf_z",
        "gyro_rf_x","gyro_rf_y","gyro_rf_z",
        "acc_rs_x","acc_rs_y","acc_rs_z",
        "gyro_rs_x","gyro_rs_y","gyro_rs_z",
        "acc_rt_x","acc_rt_y","acc_rt_z",
        "gyro_rt_x","gyro_rt_y","gyro_rt_z",
        "acc_lf_x","acc_lf_y","acc_lf_z",
        "gyro_lf_x","gyro_lf_y","gyro_lf_z",
        "acc_ls_x","acc_ls_y","acc_ls_z",
        "gyro_ls_x","gyro_ls_y","gyro_ls_z",
        "acc_lt_x","acc_lt_y","acc_lt_z",
        "gyro_lt_x","gyro_lt_y","gyro_lt_z",
        "EMG_r","EMG_l","act",
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
