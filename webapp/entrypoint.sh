#!/bin/sh
set -e

# Apply migrations
dotnet ef database update

# Start the application
exec dotnet webapp.dll
