#!/usr/bin/env bash

# File: gradlew (Linux/Mac)
# Note: Ensure this file has executable permissions (chmod +x ./gradlew)

##############################################################################
##
##  Gradle start up script for UN*X
##
##############################################################################

# Determine the Java command to run.
if [ -n "$JAVA_HOME" ] ; then
    if [ -x "$JAVA_HOME/jre/sh/java" ] ; then
        # IBM's JDK on AIX uses "$JAVA_HOME/jre/sh/java" as the system java executable
        JAVACMD="$JAVA_HOME/jre/sh/java"
    else
        JAVACMD="$JAVA_HOME/bin/java"
    fi
    if [ ! -x "$JAVACMD" ] ; then
        die "ERROR: JAVA_HOME is set to an invalid directory: $JAVA_HOME

Please set the JAVA_HOME variable in your environment to match the
location of your Java installation."
    fi
else
    JAVACMD="java"
    if [ ! -x "`which java`" ] ; then
        die "ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH.

Please set the JAVA_HOME variable in your environment to match the
location of your Java installation."
    fi
fi

# Determine the path to the executable folder and its name
APP_BASE_NAME=`basename "$0"`
APP_HOME=`dirname "$0"`

# Add default JVM options here. You can also use system property org.gradle.internal.jvm.args to pass JVM options.
DEFAULT_JVM_OPTS='"-Xmx64m" "-Xms64m"'

# OS specific support (must be 'true' or 'false').
cygwin=false
darwin=false
case "`uname`" in
  CYGWIN*)
    cygwin=true
    ;;
  Darwin*)
    darwin=true
    ;;
esac

# For Cygwin, ensure paths are in UNIX format before anything else.
if $cygwin ; then
    [ -n "$JAVA_HOME" ] && JAVA_HOME=`cygpath --unix "$JAVA_HOME"`
    [ -n "$CLASSPATH" ] && CLASSPATH=`cygpath --path --unix "$CLASSPATH"`
fi

# Set the GRADLE_HOME and launch the program
GRADLE_HOME="$APP_HOME/gradle/wrapper"

# Launch the JVM
"$JAVACMD" $DEFAULT_JVM_OPTS -Dorg.gradle.appname="$APP_BASE_NAME" -classpath "$GRADLE_HOME/gradle-wrapper.jar" org.gradle.wrapper.GradleWrapperMain "$@"
