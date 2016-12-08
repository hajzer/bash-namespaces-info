#!/bin/bash
#
# FILE        : namespaces-info.sh
# VERSION     : 0.3
# DESC        : Linux namespaces info in BASH
# DATE        : 2016
# AUTHOR      : LALA -> lala (at) linuxor (dot) sk
#
# INSPIRATION : (2013 - How to find namespaces in a Linux system) -> http://www.opencloudblog.com/?p=251 
#

##################################################################################
#                                     VARIABLES
##################################################################################

# GLOBALNE PREMENNE
# GLOBAL VARIABLES
NO_ARGS=0
SCRIPT_VERSION=0.3
SCRIPT_AUTHOR="LALA -> lala (at) linuxor (dot) sk"
SCRIPT_YEAR="2016"

# FARBY
# COLORS
# REF: http://stackoverflow.com/questions/4332478/read-the-current-text-color-in-a-xterm/4332530#4332530
COLOR_BLACK=$(tput setaf 0)
COLOR_RED=$(tput setaf 1)
COLOR_GREEN=$(tput setaf 2)
COLOR_YELLOW=$(tput setaf 3)
COLOR_LIME_YELLOW=$(tput setaf 190)
COLOR_POWDER_BLUE=$(tput setaf 153)
COLOR_BLUE=$(tput setaf 4)
COLOR_MAGENTA=$(tput setaf 5)
COLOR_CYAN=$(tput setaf 6)
COLOR_WHITE=$(tput setaf 7)
COLOR_BRIGHT=$(tput bold)
COLOR_NORMAL=$(tput sgr0)
COLOR_BLINK=$(tput blink)
COLOR_REVERSE=$(tput smso)
COLOR_UNDERLINE=$(tput smul)


##################################################################################
#                                     FUNCTIONS
##################################################################################

# Check if namespace ($NS) exists for given PID ($PID)
function namespace_exist_for_pid ()
{
    local PID=$1
    local NS=$2

    if [ -f "/proc/$PID/ns/$NS" ]
    then
        return 0
    else
        return 1
    fi
}

# Compare namespace for given PID with default namespace
# 1.argument: PID of process
# 2.argument: Namespace name
function compare_pid-ns_default-ns ()
{
    local PID=$1
    local NS=$2

    local PID_NS=`readlink /proc/$PID/ns/$NS`
    if [ "$PID_NS" == "${DEFAULT_NS[$NS]}" ]
    then
        return 0
    else
        return 1
    fi
}

function namespace_is_default ()
{
    local PID=$1
    local NS=$2

    # Check if given namespace ($NS) exist for given PID ($PID)
    if namespace_exist_for_pid "$PID" "$NS"
    then
        # If exists then compare with default namespace
        if compare_pid-ns_default-ns "$PID" "$NS"
        then
            return 0
        else
            return 1
        fi
    fi
}

function print_usage ()
{
    printf "%s\n" "Usage: `basename $0` [options]"
    printf "%s\n" "       -d      List system default namespaces"
    printf "%s\n" "       -a      List of all namespaces for all PIDs (processes)"
    printf "%s\n" "       -n      List only non default namespaces for all PIDs (processes)"
    printf "%s\n" "       -p PID  List namespaces for PID (process)"
    printf "%s\n" "       -v      Show script version"
}

function print_version ()
{
    printf "%s\n" "`basename $0` $SCRIPT_VERSION ($SCRIPT_YEAR)"
}

function print_namespace_for_pid ()
{
    local PID=$1
    local NS=$2
    local COLOR=$3

    local PID_NS=`readlink /proc/$PID/ns/$NS`
    local PID_PPID=`ps -o ppid= $PID`
    local PID_COMMAND=`ps -o cmd= $PID`

    if namespace_is_default "$PID" "$NS"
    then 
        printf "%-10.10s | %-10.10s | %s%-20.20s%s | %-8.8s | %-40.40s \n" "$PID" "$PID_PPID" "$COLOR" "$PID_NS" "${COLOR_NORMAL}" "YES" "$PID_COMMAND"
        PRINT_FOOTER+=1
    else
        printf "%-10.10s | %-10.10s | %s%-20.20s%s | %-8.8s | %-40.40s \n" "$PID" "$PID_PPID" "$COLOR" "$PID_NS" "${COLOR_NORMAL}" "NO" "$PID_COMMAND"
        PRINT_FOOTER+=1
    fi
}

function print_header ()
{
    printf "%-10s + %-10s + %-20s + %-8s + %-40s \n" "----------" "----------" "--------------------" "--------" "----------------------------------------"
    printf "%-10s | %-10s | %-20s | %-8s | %-40s \n" "PID"        "PPID"       "NAMESPACE"            "DEFAULT"  "COMMAND"
    printf "%-10s + %-10s + %-20s + %-8s + %-40s \n" "----------" "----------" "--------------------" "--------" "----------------------------------------"
}

function print_footer ()
{
    printf "%-10s + %-10s + %-20s + %-8s + %-40s \n" "----------" "----------" "--------------------" "--------" "----------------------------------------"
}


##################################################################################
#                                     INITIALIZATION
##################################################################################

# Default Linux namespaces
declare -A DEFAULT_NS
    if namespace_exist_for_pid 1 "ipc"
    then
        DEFAULT_NS[ipc]=`readlink /proc/1/ns/ipc`
    fi

    if namespace_exist_for_pid 1 "mnt"
    then
        DEFAULT_NS[mnt]=`readlink /proc/1/ns/mnt`
    fi

    if namespace_exist_for_pid 1 "net"
    then
        DEFAULT_NS[net]=`readlink /proc/1/ns/net`
    fi

    if namespace_exist_for_pid 1 "pid"
    then
        DEFAULT_NS[pid]=`readlink /proc/1/ns/pid`
    fi

    if namespace_exist_for_pid 1 "user"
    then
        DEFAULT_NS[user]=`readlink /proc/1/ns/user`
    fi

    if namespace_exist_for_pid 1 "uts"
    then
        DEFAULT_NS[uts]=`readlink /proc/1/ns/uts`
    fi

# List of all PIDs, PPIDs and COMMANDs (We start from second line [NR>1] because first line contains string "PID" or "COMMAND" etc.)
TABLE_PIDS=($(ps -eo pid | awk 'NR>1{print $1}'))
TABLE_PPIDS=($(ps -eo ppid | awk 'NR>1{print $1}'))
TABLE_COMMANDS=($(ps -eo cmd | awk 'NR>1{print $1}'))
TABLE_PIDS_ITEMS=${#TABLE_PIDS[@]}


##################################################################################
#                                     MAIN
##################################################################################

##################################### Check script arguments
if [ $# -eq "$NO_ARGS" ]
    then
    print_usage 
    exit
fi

##################################### Process script arguments
while getopts ":danp:v" Option
do
    case $Option in


##################################### Argument "-d"
##################################### List system default namespaces
    d) 
    printf "%-15s + %-26s \n"      "---------------"                    "--------------------------"
    printf "%-15s | %-26s \n"      "Linux Namespace"                    "System default namespaces"
    printf "%-15s + %-26s \n"      "---------------"                    "--------------------------"
    printf "%-15s | %s%-26s%s \n"  "IPC  namespace"  "${COLOR_RED}"     "${DEFAULT_NS[ipc]}"          "${COLOR_NORMAL}"
    printf "%-15s | %s%-26s%s \n"  "MNT  namespace"  "${COLOR_YELLOW}"  "${DEFAULT_NS[mnt]}"          "${COLOR_NORMAL}"
    printf "%-15s | %s%-26s%s \n"  "NET  namespace"  "${COLOR_MAGENTA}" "${DEFAULT_NS[net]}"          "${COLOR_NORMAL}"
    printf "%-15s | %s%-26s%s \n"  "PID  namespace"  "${COLOR_CYAN}"    "${DEFAULT_NS[pid]}"          "${COLOR_NORMAL}"
    printf "%-15s | %s%-26s%s \n"  "USER namespace"  "${COLOR_GREEN}"   "${DEFAULT_NS[user]}"         "${COLOR_NORMAL}"
    printf "%-15s | %s%-26s%s \n"  "UTS  namespace"  "${COLOR_WHITE}"   "${DEFAULT_NS[uts]}"          "${COLOR_NORMAL}"
    printf "%-15s + %-26s \n"      "---------------"                    "--------------------------"

    exit 0
    ;;


##################################### Argument "-a"
##################################### List of all namespaces for all PIDs (processes)
    a) 

    for ((    i=0; i<=$TABLE_PIDS_ITEMS; i++    ))
    do


    # Table header
    if (( $i==0 ))
    then
        print_header
    fi


    # Temporary variable for printing separator line between different PIDs
    PRINT_FOOTER=0


    # IPC namespace
    #################################
    NS="ipc"
    
    # Print namespace ($NS) for PID ( ${TABLE_PIDS[$i]} )
    if namespace_exist_for_pid "${TABLE_PIDS[$i]}" "$NS"
    then
        print_namespace_for_pid "${TABLE_PIDS[$i]}" "$NS" "$COLOR_RED"
    fi
    

    # MNT namespace
    #################################
    NS="mnt"
    
    # Print namespace ($NS) for PID ( ${TABLE_PIDS[$i]} )
    if namespace_exist_for_pid "${TABLE_PIDS[$i]}" "$NS"
    then 
        print_namespace_for_pid "${TABLE_PIDS[$i]}" "$NS" "$COLOR_YELLOW"
    fi
    

    # NET namespace
    #################################
    NS="net"
    
    # Print namespace ($NS) for PID ( ${TABLE_PIDS[$i]} )
    if namespace_exist_for_pid "${TABLE_PIDS[$i]}" "$NS"
    then
        print_namespace_for_pid "${TABLE_PIDS[$i]}" "$NS" "$COLOR_MAGENTA"
    fi
    

    # PID namespace
    #################################
    NS="pid"
    
    # Print namespace ($NS) for PID ( ${TABLE_PIDS[$i]} )
    if namespace_exist_for_pid "${TABLE_PIDS[$i]}" "$NS"
    then
        print_namespace_for_pid "${TABLE_PIDS[$i]}" "$NS" "$COLOR_CYAN"
    fi
    

    # USER namespace
    #################################
    NS="user"
    
    # Print namespace ($NS) for PID ( ${TABLE_PIDS[$i]} )
    if namespace_exist_for_pid "${TABLE_PIDS[$i]}" "$NS"
    then
        print_namespace_for_pid "${TABLE_PIDS[$i]}" "$NS" "$COLOR_GREEN"
    fi
    

    # UTS namespace
    #################################
    NS="uts"
    
    # Print namespace ($NS) for PID ( ${TABLE_PIDS[$i]} )
    if namespace_exist_for_pid "${TABLE_PIDS[$i]}" "$NS"
    then
        print_namespace_for_pid "${TABLE_PIDS[$i]}" "$NS" "$COLOR_WHITE"
    fi


    # Print footer (when $PRINT_FOOTER != 0)
    if (( $PRINT_FOOTER != 0 ))
    then
        print_footer
        PRINT_FOOTER=0
    fi

    done
    exit 0
    ;;


##################################### Argument "-n"
##################################### List only non default namespaces for all PIDs (processes)
    n) 

    for ((    i=0; i<=$TABLE_PIDS_ITEMS; i++    ))
    do

    # Table header
    if (( $i==0 ))
    then
        print_header
    fi

    # Temporary variable for printing separator line between different PIDs
    PRINT_FOOTER=0


    # IPC namespace
    #################################
    NS="ipc"
    
    # Print namespace if namespace ($NS) for PID ( ${TABLE_PIDS[$i]} ) is different than default namespace
    if  ! namespace_is_default "${TABLE_PIDS[$i]}" "$NS"
    then
        print_namespace_for_pid "${TABLE_PIDS[$i]}" "$NS" "$COLOR_RED"
    fi


    # MNT namespace
    #################################
    NS="mnt"
    
    # Print namespace if namespace ($NS) for PID ( ${TABLE_PIDS[$i]} ) is different than default namespace
    if  ! namespace_is_default "${TABLE_PIDS[$i]}" "$NS"
    then
        print_namespace_for_pid "${TABLE_PIDS[$i]}" "$NS" "$COLOR_YELLOW"
    fi


    # NET namespace
    #################################
    NS="net"
    
    # Print namespace if namespace ($NS) for PID ( ${TABLE_PIDS[$i]} ) is different than default namespace
    if  ! namespace_is_default "${TABLE_PIDS[$i]}" "$NS"
    then
        print_namespace_for_pid "${TABLE_PIDS[$i]}" "$NS" "$COLOR_MAGENTA"
    fi


    # PID namespace
    #################################
    NS="pid"
    
    # Print namespace if namespace ($NS) for PID ( ${TABLE_PIDS[$i]} ) is different than default namespace
    if  ! namespace_is_default "${TABLE_PIDS[$i]}" "$NS"
    then
        print_namespace_for_pid "${TABLE_PIDS[$i]}" "$NS" "$COLOR_CYAN"
    fi


    # USER namespace
    #################################
    NS="user"
    
    # Print namespace if namespace ($NS) for PID ( ${TABLE_PIDS[$i]} ) is different than default namespace
    if  ! namespace_is_default "${TABLE_PIDS[$i]}" "$NS"
    then
        print_namespace_for_pid "${TABLE_PIDS[$i]}" "$NS" "$COLOR_GREEN"
    fi


    # UTS namespace
    #################################
    NS="uts"
    
    # Print namespace if namespace ($NS) for PID ( ${TABLE_PIDS[$i]} ) is different than default namespace
    if  ! namespace_is_default "${TABLE_PIDS[$i]}" "$NS"
    then
        print_namespace_for_pid "${TABLE_PIDS[$i]}" "$NS" "$COLOR_WHITE"
    fi


    # Print footer (when $PRINT_FOOTER != 0)
    if (( $PRINT_FOOTER != 0 ))
    then
        print_footer
        PRINT_FOOTER=0
    fi

    done
    exit 0
    ;;


##################################### Argument "-p PID"
##################################### List namespaces for PID (process)
    p)
    if kill -0 $2 2>/dev/null
    then
        print_header
        print_namespace_for_pid "$2" "ipc" "$COLOR_RED"
        print_namespace_for_pid "$2" "mnt" "$COLOR_YELLOW"
        print_namespace_for_pid "$2" "net" "$COLOR_MAGENTA"
        print_namespace_for_pid "$2" "pid" "$COLOR_CYAN"
        print_namespace_for_pid "$2" "user" "$COLOR_GREEN"
        print_namespace_for_pid "$2" "uts" "$COLOR_WHITE"
        print_footer
    else
        printf "PID not exist.\n"
    fi

    exit 0
    ;;


##################################### Argument "-v"
##################################### Show script version
    v) 
    print_version
    exit 0
    ;;


##################################### Default
##################################### Show usage
    *) 
    print_usage
    exit 0
    ;;


    esac
done


# Dekrementujeme smernik argumentu, takze ukazuje na nasledujuci parameter.
# $1 teraz referuje na prvu polozku (nie volbu) poskytnutu na prikazovom riadku.
shift $(($OPTIND - 1))

# Uspesny koniec
exit 0
