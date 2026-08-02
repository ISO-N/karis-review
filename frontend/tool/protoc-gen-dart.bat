@echo off
cd /d "%~dp0.."
dart run protoc_plugin:protoc_plugin %*
