using ZipFile
using DataFrames
using CategoricalArrays

using DataStructures: OrderedDict

function load_libras(
    dirpath::String=joinpath(dirname(pathof(ModalAssociationRules)), "../test/data/Libras"),
    fileprefix::String="Libras"
)
    _load_libras(dirpath, fileprefix)
end

function _load_libras(dirpath::String, fileprefix::String)
    (X_train, y_train), (X_test, y_test) =
        (
            read("$(dirpath)/$(fileprefix)_TEST.arff", String) |> SoleData.parseARFF,
            read("$(dirpath)/$(fileprefix)_TRAIN.arff", String) |> SoleData.parseARFF,
        )

    variablenames = [
        "x_frame_1", "y_frame_1", "x_frame_2", "y_frame_2", "x_frame_3", "y_frame_3",
        "x_frame_4", "y_frame_4", "x_frame_5", "y_frame_5", "x_frame_6", "y_frame_6",
        "x_frame_7", "y_frame_7", "x_frame_8", "y_frame_8", "x_frame_9", "y_frame_9",
        "x_frame_10", "y_frame_10", "x_frame_11", "y_frame_11", "x_frame_12", "y_frame_12",
        "x_frame_13", "y_frame_13", "x_frame_14", "y_frame_14", "x_frame_15", "y_frame_15",
        "x_frame_16", "y_frame_16", "x_frame_17", "y_frame_17", "x_frame_18", "y_frame_18",
        "x_frame_19", "y_frame_19", "x_frame_20", "y_frame_20", "x_frame_21", "y_frame_21",
        "x_frame_22", "y_frame_22", "x_frame_23", "y_frame_23", "x_frame_24", "y_frame_24",
        "x_frame_25", "y_frame_25", "x_frame_26", "y_frame_26", "x_frame_27", "y_frame_27",
        "x_frame_28", "y_frame_28", "x_frame_29", "y_frame_29", "x_frame_30", "y_frame_30",
        "x_frame_31", "y_frame_31", "x_frame_32", "y_frame_32", "x_frame_33", "y_frame_33",
        "x_frame_34", "y_frame_34", "x_frame_35", "y_frame_35", "x_frame_36", "y_frame_36",
        "x_frame_37", "y_frame_37", "x_frame_38", "y_frame_38", "x_frame_39", "y_frame_39",
        "x_frame_40", "y_frame_40", "x_frame_41", "y_frame_41", "x_frame_42", "y_frame_42",
        "x_frame_43", "y_frame_43", "x_frame_44", "y_frame_44", "x_frame_45", "y_frame_45",
    ]

    class_names = [
        "curved_swing",
        "horizontal_swing",
        "vertical_swing",
        "anti_clockwise_arc",
        "clokcwise_arc",
        "circle",
        "horizontal_straight_line",
        "vertical_straight_line",
        "horizontal_zigzag",
        "vertical_zigzag",
        "horizontal_wavy",
        "vertical_wavy",
        "face_up_curve",
        "face_down_curve",
        "tremble"
    ]

    # convert from .arff class codes to string
    fix_class_names(y) = class_names[round(Int, parse(Float64, y))]

    y_train = map(fix_class_names, y_train)
    y_test = map(fix_class_names, y_test)

    y_train = categorical(y_train)
    y_test = categorical(y_test)

    vcat(X_train, X_test), vcat(y_train, y_test)
end
