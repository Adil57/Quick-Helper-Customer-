@rem
@rem Copyright 2017 the original author or authors.
@rem
@rem Licensed under the Apache License, Version 2.0 (the "License");
@rem you may not use this file except in compliance with the License.
@rem You may obtain a copy of the License at
@rem
@rem      http://www.apache.org/licenses/LICENSE-2.0
@rem
@rem Unless required by applicable law or agreed to in writing, software
@rem distributed under the License is distributed on an "AS IS" BASIS,
@rem WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
@rem See the License for the specific language governing permissions and
@rem limitations under the License.
@rem

@if "%DEBUG%" == "" @echo off
@rem ##########################################################################
@rem
@rem  Gradle startup script for Windows
@rem
@rem ##########################################################################

@rem Set local scope for the variables with windows NT shell
if "%OS%"=="Windows_NT" setlocal

@rem Add default JVM options here. You can also use system property org.gradle.internal.jvm.args to pass JVM options.
set DEFAULT_JVM_OPTS="-Xmx64m" "-Xms64m"

@rem Find the Java executable and set JAVA_EXE.
set JAVA_EXE=java.exe
if defined JAVA_HOME goto findJavaFromJavaHome

:findJavaFromPath
set JAVA_HOME=
set JAVA_EXE=java.exe
for %%i in ("%PATH:;=" "%") do (
  if exist "%%~i\java.exe" (
    set "JAVA_EXE=%%~i\java.exe"
    goto checkJava
  )
)

:findJavaFromJavaHome
set "JAVA_EXE=%JAVA_HOME%\bin\java.exe"

:checkJava
if exist "%JAVA_EXE%" goto execute

echo.ERROR: JAVA_HOME is set to an invalid directory: %JAVA_HOME%
echo.
echo Please set the JAVA_HOME variable in your environment to match the
echo location of your Java installation.

@rem End local scope for the variables with windows NT shell
if "%OS%"=="Windows_NT" endlocal
exit /b 1

:execute
@rem Setup Gradle environment
set GRADLE_HOME=%~dp0gradle\wrapper
set CLASSPATH=%GRADLE_HOME%\gradle-wrapper.jar

@rem Execute Gradle
"%JAVA_EXE%" %DEFAULT_JVM_OPTS% -Dorg.gradle.appname="%~n0" -classpath "%CLASSPATH%" org.gradle.wrapper.GradleWrapperMain %*

@rem End local scope for the variables with windows NT shell
if "%OS%"=="Windows_NT" endlocal
