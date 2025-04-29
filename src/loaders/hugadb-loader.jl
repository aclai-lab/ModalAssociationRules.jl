# Loader for HuGaDB dataset;
# see https://github.com/romanchereshnev/HuGaDB

# Usage:
# call `load_hugadb(filepath)`, specifying one specific the filepath containing the
# recordings for one specific partecipant.

# Warning: as stated on the official GitHub page of the dataset, some data has been
# corrupted: be careful about the file you are choosing to load.

using ZipFile
using DataFrames
using CategoricalArrays

using DataStructures: OrderedDict

function load_hugadb(;
    filepath::String=joinpath(dirname(pathof(ModalAssociationRules)),
        "..", "test", "data", "HuGaDB"),
    filename::String="HuGaDB_v2_various_01_00.txt",
)
    filepath = joinpath(filepath, filename)

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

    # e.g. open("test/data/HuGaDB/HuGaDB_v2_various_01_00.txt", "r")
    f = open(filepath, "r")

    # get the activities recorded for the performer specified in `filename`
    activities = split(readline(f), " ")[1:end-1]
    activities[1] = activities[1][11:end] # remove the initial "#Activity\t"

    # activity strings to ids as in the table at https://github.com/romanchereshnev/HuGaDB
    _activity2id = x -> findfirst(activity -> x == activity, [
        "walking", "running", "going_up", "going_down", "sitting", "sitting_down",
        "standing_up", "standing", "bicycling", "elevator_up", "elevator_down",
        "sitting_car"
    ])
    activity_ids = [_activity2id(activity) for activity in activities]

    # ignore #ActivityID array (we only keep the string version instead of integer IDs)
    readline(f)

    # ignore #Date row
    readline(f)

    # ignore the variable names, as we already explicited them in `variablenames`
    readline(f)

    _substr2float = x -> parse(Float64, x)
    lines = [_substr2float.(split(line, "\t")) for line in eachline(f)]

    close(f)

    X = DataFrame([
        # get the i-th element from each line, and concatenate them together
        [[line[i] for line in lines]]
        for i in 1:length(variablenames)
    ], variablenames)

    return X, (activities, activity_ids), variablenames
end
