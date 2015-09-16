#!/usr/bin/env bash

####################################
# Set up environment variables
####################################

# if not set, set $STARDOG to the parent of the folder in which this script is stored
if [ -z "$STARDOG" ]; then
  SOURCE="${BASH_SOURCE[0]}"
  while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
    STARDOG="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
    [[ $SOURCE != /* ]] && SOURCE="$STARDOG/$SOURCE"
  done
  STARDOG="$( cd -P "$( dirname "$SOURCE" )" && pwd )/.."
fi

if [[ `uname -s` == CYGWIN* ]]; then
  PATHVAR=`cygpath -m "$STARDOG"`
  PATHDELIM=";"
else
  PATHVAR="$STARDOG"
  PATHDELIM=":"
fi

MARKER="+++++SUCCESS+++++"

if [ -n "${JAVA_HOME}" -a -x "${JAVA_HOME}/bin/java" ]; then
 java="${JAVA_HOME}/bin/java"
else
 java=java
fi

# The "default" java arguments for Stardog.  These should not be edited.  For providing custom arguments to the JVM,
# STARDOG_JAVA_ARGS should be used.
DEFAULT_JAVA_ARGS="-Djavax.xml.datatype.DatatypeFactory=org.apache.xerces.jaxp.datatype.DatatypeFactoryImpl
 -Dapple.awt.UIElement=true -Dfile.encoding=UTF-8"

# Performance related java arguments for things like GC tuning.  Default values are reasonable defaults for the system
# across platforms, but these can be tweaked for your current environment.
if [ -z "${STARDOG_PERF_JAVA_ARGS}" ]; then
 STARDOG_PERF_JAVA_ARGS="-XX:SoftRefLRUPolicyMSPerMB=1 -XX:+UseParallelOldGC -XX:+UseCompressedOops"
fi

####################################
# Helper functions
####################################

build_classpath() {
  local dirs="
/client/api/
/client/cli/
/client/http/
/client/snarl/
/client/pack/
"
  if [ -n "$1" -a "$1" = "admin" ]; then
    is_admin=true
    dirs="
${dirs}
/server/dbms/
/server/http/
/server/snarl/
/server/pack/"
  fi
  CLASSPATH=
  for _dir in $dirs; do
    if [ -z "${CLASSPATH}" ]; then
      CLASSPATH="${PATHVAR}${_dir}*"
    else
      CLASSPATH="${CLASSPATH}${PATHDELIM}${PATHVAR}${_dir}*"
    fi
  done
  if [ -z "$is_admin" ]; then
    SLF4J_JARS=$(find "${PATHVAR}/server/dbms/" -name '*slf4j*.jar' -print0 | xargs -0 echo  | tr ' ' "${PATHDELIM}")
    CLASSPATH="${CLASSPATH}${PATHDELIM}${SLF4J_JARS}"
  fi
}

create_tmp_file() {
  if [[ `uname -s` == CYGWIN* ]]; then
    SERVER_START_LOG=`mktemp -p $PATHVAR -t stardog-server-start.XXXXXXXX`    # PATHVAR is the cygpath of stardog home
  else
    SERVER_START_LOG=`mktemp -t stardog-server-start.XXXXXXXX`
  fi

  if [ "$?" != "0" ]; then
    echo Failed to create a temporary file
  else
    export SERVER_START_LOG
    TEMP_FILE_CREATED=1
  fi
}
signal_handler_first_stage() {
  if [ -z "$HANDLER_EXECUTED" ]; then
    HANDLER_EXECUTED=1
    kill $PID
  fi
  exit
}

process_exists() {
  kill -s 0 $1 > /dev/null 2>&1
  return $?
}

is_foreground() {
  FOREGROUND=
  if [ -z "$APP_START" ]; then
    return 0
  fi
  for it in "$@"; do
    if [ "$it" = "--foreground" ]; then
      FOREGROUND=true
      break
    fi
  done
}

is_appstart() {
  APP_START=
  if [ "$1" = "server" -a "$2" = "start" ]; then
    APP_START=true
  fi
  if [ "$1" = "cluster" -a "$2" = "zkstart" ]; then
    APP_START=true
  fi
}

handle_zk() {
  if [ "$1" = "cluster" ]; then
    if [ "$2" = "zkstart" ]; then
      if [ -z "${SD_ZOO_JAVA_ARGS}" ]; then
          SD_ZOO_JAVA_ARGS="-Xmx1g -Xms1g -XX:MaxDirectMemorySize=128m -Dzookeeper.jmx.log4j.disable=true"
      fi
      STARDOG_JAVA_ARGS=${SD_ZOO_JAVA_ARGS}
    fi
    if [ "$2" = "zkstop" ]; then
      jps -m | grep zkstart | awk '{ print $1 }' | xargs kill -15
      STARDOG_ARGS+=('--is-successful' "$?")
    fi
  fi
}

check_log4j_config() {
  if [ -n "${STARDOG_HOME}" ]; then
    local extensions=("yaml" "yml" "json" "jsn" "xml")
    local has_log4j=
    local actual_ext=
    for ext in ${extensions[*]}; do
      if [ -e "${STARDOG_HOME}/log4j2.${ext}" ]; then
        has_log4j=true
        actual_ext=${ext}
        break;
      fi
    done
    if [ -n "${has_log4j}" ]; then
      DEFAULT_JAVA_ARGS="${DEFAULT_JAVA_ARGS} -Dlog4j.configurationFile=${STARDOG_HOME}/log4j2.${actual_ext}"
    fi
  fi
}
